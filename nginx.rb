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
  def unicorn_upstream
    "#{var(:domain).gsub(/[^a-z]/, '_')}_unicorn"
  end
  def unicorn_socket_path
    var(:app_root) / 'tmp/sockets/unicorn.socket'
  end
  def worker_pool_size
    # 300MB 'working room' per worker (hopefully the worker itself should be
    # no more than half that), with 500MB set aside for system, DB, etc,
    # capped to at least 2 and at most 8 workers.
    [8, [2,
      (Babushka::Base.host.total_memory - 500.mb) / 300.mb,
    ].max].min
  end
  def nginx_running?
    shell "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
  end
  def restart_nginx
    if nginx_running?
      log_shell "Restarting nginx", "#{nginx_bin} -s reload", :sudo => true
      sleep 1 # The reload just sends the signal, and doesn't wait.
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
  define_var :vhost_type, :default => 'passenger', :choices => %w[unicorn passenger proxy static]
  define_var :document_root, :default => L{ '/srv/http' / var(:domain) }
  requires 'webserver configured.nginx'
  requires 'unicorn configured' if var(:vhost_type) == 'unicorn'
  met? {
    Babushka::Renderable.new(nginx_conf_for(var(:domain), 'conf')).from?(dependency.load_path.parent / "nginx/vhost.conf.erb") and
    Babushka::Renderable.new(nginx_conf_for(var(:domain), 'common')).from?(dependency.load_path.parent / "nginx/#{var :vhost_type}_vhost.common.erb")
  }
  meet {
    render_erb "nginx/vhost.conf.erb",                      :to => nginx_conf_for(var(:domain), 'conf'), :sudo => true
    render_erb "nginx/#{var :vhost_type}_vhost.common.erb", :to => nginx_conf_for(var(:domain), 'common'), :sudo => true
  }
  after { restart_nginx if nginx_conf_link_for(var(:domain)).exists? }
end

dep 'self signed cert.nginx' do
  requires 'webserver installed.src'
  met? { %w[key csr crt].all? {|ext| (nginx_cert_path / "#{var :domain}.#{ext}").exists? } }
  meet {
    cd nginx_cert_path, :create => "700", :sudo => true do
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
  requires 'webserver installed.src', 'www user and group', 'nginx.logrotate'
  define_var :nginx_prefix, :default => '/opt/nginx'
  met? {
    if Babushka::Renderable.new(nginx_conf).from?(dependency.load_path.parent / "nginx/nginx.conf.erb")
      configured_root = nginx_conf.read.val_for('passenger_root')
      (configured_root == passenger_root).tap {|result|
        log "nginx is configured to use #{File.basename configured_root}", :as => (:ok if result)
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
    cd Babushka::GemHelper.gem_path_for('passenger') do
      log_shell "Building passenger", "rake clean nginx", :sudo => Babushka::GemHelper.should_sudo?
    end
  }
end

dep 'webserver installed.src' do
  requires 'passenger built', 'pcre.managed', 'libssl headers.managed', 'zlib headers.managed'
  merge :versions, {:nginx => '1.0.2', :nginx_upload_module => '2.2.0'}
  source "http://nginx.org/download/nginx-#{var(:versions)[:nginx]}.tar.gz"
  extra_source "http://www.grid.net.ru/nginx/download/nginx_upload_module-#{var(:versions)[:nginx_upload_module]}.tar.gz"
  configure_args "--with-ipv6", "--with-pcre", "--with-http_ssl_module",
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
      installed_version = shell(var(:nginx_prefix) / 'sbin/nginx -V') {|shell| shell.stderr }.val_for(/(nginx: )?nginx version:/).sub('nginx/', '')
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

dep 'http basic logins.nginx' do
  requires 'http basic auth enabled.nginx'
  met? { shell("curl -I -u #{var(:http_user)}:#{var(:http_pass)} #{var(:domain)}").val_for('HTTP/1.1')[/^[25]00\b/] }
  meet { append_to_file "#{var(:http_user)}:#{var(:http_pass).crypt(var(:http_pass))}", (var(:nginx_prefix) / 'conf/htpasswd'), :sudo => true }
  after { restart_nginx }
end

dep 'http basic auth enabled.nginx' do
  met? { shell("curl -I #{var(:domain)}").val_for('HTTP/1.1')[/^401\b/] }
  meet {
    append_to_file %Q{auth_basic 'Restricted';\nauth_basic_user_file htpasswd;}, nginx_conf_for(var(:domain), 'common'), :sudo => true
  }
  after {
    sudo "touch #{var(:nginx_prefix) / 'conf/htpasswd'}"
    restart_nginx
  }
end
