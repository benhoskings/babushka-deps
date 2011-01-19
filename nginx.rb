meta :nginx do
  accepts_list_for :source
  accepts_list_for :extra_source
  def nginx_bin
    var(:nginx_prefix) / 'sbin/nginx'
  end
  def nginx_conf
    var(:nginx_prefix) / 'conf/nginx.conf'
  end
  def nginx_cert_path
    var(:nginx_prefix) / 'conf/certs'
  end
  def nginx_conf_for domain, ext
    var(:nginx_prefix) / "conf/vhosts/#{domain}.#{ext}"
  end
  def nginx_conf_link_for domain
    var(:nginx_prefix) / "conf/vhosts/on/#{domain}.conf"
  end
  def passenger_root
    Babushka::GemHelper.gem_path_for('passenger')
  end
  def nginx_running?
    shell "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
  end
  def restart_nginx
    if nginx_running?
      log_shell "Restarting nginx", "#{nginx_bin} -s reload", :sudo => true
    end
  end
end

dep 'vhost enabled.nginx' do
  requires 'vhost configured.nginx'
  met? { nginx_conf_link_for(var(:domain)).exists? }
  meet { sudo "ln -sf '#{nginx_conf_for(var(:domain), 'conf')}' '#{nginx_conf_link_for(var(:domain))}'" }
  after { restart_nginx }
end

dep 'vhost configured.nginx' do
  define_var :www_aliases, :default => L{
    "#{var :domain} #{var :extra_domains}".split(' ').compact.map(&:strip).reject {|d|
      d.starts_with? '*.'
    }.reject {|d|
      d.starts_with? 'www.'
    }.map {|d|
      "www.#{d}"
    }.join(' ')
  }
  requires 'webserver configured.nginx'
  define_var :vhost_type, :default => 'passenger', :choices => %w[passenger proxy static]
  define_var :document_root, :default => L{ '/srv/http' / var(:domain) }
  met? { nginx_conf_for(var(:domain), 'conf').exists? }
  meet {
    render_erb "nginx/#{var :vhost_type}_vhost.conf.erb",   :to => nginx_conf_for(var(:domain), 'conf'), :sudo => true
    render_erb "nginx/#{var :vhost_type}_vhost.common.erb", :to => nginx_conf_for(var(:domain), 'common'), :sudo => true, :optional => true
  }
  after { restart_nginx if nginx_conf_link_for(var(:domain)).exists? }
end

dep 'self signed cert.nginx' do
  requires 'webserver installed.src'
  met? { %w[key csr crt].all? {|ext| (nginx_cert_path / "#{var :domain}.#{ext}").exists? } }
  meet {
    in_dir nginx_cert_path, :create => "700", :sudo => true do
      log_shell("generating private key", "openssl genrsa -out #{var :domain}.key 2048", :sudo => true) and
      log_shell("generating certificate", "openssl req -new -key #{var :domain}.key -out #{var :domain}.csr",
        :sudo => true, :input => [
          var(:country, :default => 'AU'),
          var(:state),
          var(:city, :default => ''),
          var(:organisation),
          var(:organisational_unit, :default => ''),
          var(:domain),
          var(:email),
          '', # password
          '', # optional company name
          '' # done
        ].join("\n")
      ) and
      log_shell("signing certificate with key", "openssl x509 -req -days 365 -in #{var :domain}.csr -signkey #{var :domain}.key -out #{var :domain}.crt", :sudo => true)
    end
  }
end

dep 'webserver running.nginx' do
  requires 'webserver configured.nginx', 'webserver startup script.nginx'
  met? {
    nginx_running?.tap {|result|
      log "There is #{result ? 'something' : 'nothing'} listening on #{result ? result.scan(/[0-9.*]+[.:]80/).first : 'port 80'}"
    }
  }
  meet :on => :linux do
    sudo '/etc/init.d/nginx start'
  end
  meet :on => :osx do
    log_error "launchctl should have already started nginx. Check /var/log/system.log for errors."
  end
end

dep 'webserver startup script.nginx' do
  requires 'webserver installed.src'
  on :linux do
    requires 'rcconf.managed'
    met? { shell("rcconf --list").val_for('nginx') == 'on' }
    meet {
      render_erb 'nginx/nginx.init.d.erb', :to => '/etc/init.d/nginx', :perms => '755', :sudo => true
      sudo 'update-rc.d nginx defaults'
    }
  end
  on :osx do
    met? { !sudo('launchctl list').split("\n").grep(/org\.nginx/).empty? }
    meet {
      render_erb 'nginx/nginx.launchd.erb', :to => '/Library/LaunchDaemons/org.nginx.plist', :sudo => true
      sudo 'launchctl load -w /Library/LaunchDaemons/org.nginx.plist'
    }
  end
end

dep 'webserver configured.nginx' do
  requires 'webserver installed.src', 'www user and group'
  define_var :nginx_prefix, :default => '/opt/nginx'
  met? {
    if babushka_config? nginx_conf
      configured_root = nginx_conf.read.val_for('passenger_root')
      (configured_root == passenger_root).tap {|result|
        log_result "nginx is configured to use #{File.basename configured_root}", :result => result
      }
    end
  }
  meet {
    render_erb 'nginx/nginx.conf.erb', :to => nginx_conf, :sudo => true
  }
  after {
    sudo "mkdir -p #{var(:nginx_prefix) / 'conf/vhosts/on'}"
    restart_nginx
  }
end

dep 'passenger built' do
  requires 'passenger.gem', 'build tools', 'curl.managed'
  met? {
    %W[
      ./agents/nginx/PassengerHelperAgent
      ./agents/PassengerLoggingAgent
      ./agents/PassengerWatchdog
      ./ext/common/libpassenger_common.a
      ./ext/ruby/#{Babushka::GemHelper.ruby_binary_slug}/passenger_native_support.#{Babushka::Base.host.library_ext}
    ].all? {|obj|
      (Babushka::GemHelper.gem_path_for('passenger') / obj).exists?
    }
  }
  meet {
    in_dir Babushka::GemHelper.gem_path_for('passenger') do
      shell "rake clean nginx", :sudo => Babushka::GemHelper.should_sudo?
    end
  }
end

dep 'webserver installed.src' do
  requires 'lamp stack removed', 'passenger built', 'pcre.managed', 'libssl headers.managed', 'zlib headers.managed'
  merge :versions, {:nginx => '0.8.54', :nginx_upload_module => '2.2.0'}
  source "http://nginx.org/download/nginx-#{var(:versions)[:nginx]}.tar.gz"
  extra_source "http://www.grid.net.ru/nginx/download/nginx_upload_module-#{var(:versions)[:nginx_upload_module]}.tar.gz"
  configure_args "--with-pcre", "--with-http_ssl_module",
    L{ "--add-module='#{Babushka::GemHelper.gem_path_for('passenger') / 'ext/nginx'}'" },
    "--add-module='../../nginx_upload_module-#{var(:versions)[:nginx_upload_module]}/nginx_upload_module-#{var(:versions)[:nginx_upload_module]}'"
  setup {
    prefix var(:nginx_prefix, :default => '/opt/nginx')
    provides var(:nginx_prefix) / 'sbin/nginx'
  }

  # The build process needs to write to passenger_root/ext/nginx.
  configure { log_shell "configure", default_configure_command, :sudo => Babushka::GemHelper.should_sudo? }
  build { log_shell "build", "make", :sudo => Babushka::GemHelper.should_sudo? }
  install { log_shell "install", "make install", :sudo => true }

  met? {
    if !File.executable?(var(:nginx_prefix) / 'sbin/nginx')
      unmet "nginx isn't installed"
    else
      installed_version = shell(var(:nginx_prefix) / 'sbin/nginx -V') {|shell| shell.stderr }.val_for('nginx version').sub('nginx/', '')
      if installed_version != var(:versions)[:nginx]
        unmet "an outdated version of nginx is installed (#{installed_version})"
      elsif !shell(var(:nginx_prefix) / 'sbin/nginx -V') {|shell| shell.stderr }[Babushka::GemHelper.gem_path_for('passenger').to_s + '/']
        unmet "nginx is installed, but built against the wrong passenger version"
      else
        met "nginx-#{installed_version} is installed"
      end
    end
  }
end

dep 'lamp stack removed', :for => :apt do
  def packages
    shell("dpkg --get-selections").split("\n").map {|l|
      l.split(/\s+/, 2).first
    }.select {|l|
      l[/apache|mysql|php/]
    }
  end
  met? {
    packages.empty?
  }
  meet {
    packages.each {|pkg|
      log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", :sudo => true
    }
  }
  after {
    log_shell "Autoremoving packages", "apt-get -y autoremove", :sudo => true
  }
end
