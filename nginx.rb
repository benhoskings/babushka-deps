meta :nginx do
  accepts_list_for :source
  accepts_list_for :extra_source
  template {
    helper(:nginx_bin) { var(:nginx_prefix) / 'sbin/nginx' }
    helper(:nginx_conf) { var(:nginx_prefix) / 'conf/nginx.conf' }
    helper(:nginx_cert_path) { var(:nginx_prefix) / 'conf/certs' }
    helper(:nginx_conf_for) {|domain,ext| var(:nginx_prefix) / "conf/vhosts/#{domain}.#{ext || 'conf'}" }
    helper(:nginx_conf_link_for) {|domain| var(:nginx_prefix) / "conf/vhosts/on/#{domain}.conf" }

    helper(:passenger_root) { Babushka::GemHelper.gem_path_for('passenger') }

    helper :nginx_running? do
      shell "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
    end

    helper :restart_nginx do
      if nginx_running?
        log_shell "Restarting nginx", "#{nginx_bin} -s reload", :sudo => true
      end
    end
  }
end

nginx 'vhost enabled' do
  requires 'vhost configured'
  met? { nginx_conf_link_for(var(:domain)).exists? }
  meet { sudo "ln -sf '#{nginx_conf_for(var(:domain))}' '#{nginx_conf_link_for(var(:domain))}'" }
  after { restart_nginx }
end

nginx 'vhost configured' do
  helper :www_aliases do
    "#{var :domain} #{var :extra_domains}".split(' ').compact.map(&:strip).reject {|d|
      d.starts_with? '*.'
    }.reject {|d|
      d.starts_with? 'www.'
    }.map {|d|
      "www.#{d}"
    }.join(' ')
  end
  requires 'webserver configured'
  define_var :vhost_type, :default => 'passenger', :choices => %w[passenger proxy static]
  met? { nginx_conf_for(var(:domain)).exists? }
  meet {
    render_erb "nginx/#{var :vhost_type}_vhost.conf.erb",   :to => nginx_conf_for(var(:domain)), :sudo => true
    render_erb "nginx/#{var :vhost_type}_vhost.common.erb", :to => nginx_conf_for(var(:domain), 'common'), :sudo => true, :optional => true
  }
  after { restart_nginx if nginx_conf_link_for(var(:domain)).exists? }
end

nginx 'self signed cert' do
  requires 'webserver installed'
  met? { %w[key csr crt].all? {|ext| (nginx_cert_path / "#{var :domain}.#{ext}").exists? } }
  meet {
    in_dir nginx_cert_path, :create => "700", :sudo => true do
      log_shell("generating private key", "openssl genrsa -out #{var :domain}.key 1024", :sudo => true) and
      log_shell("generating certificate", "openssl req -new -key #{var :domain}.key -out #{var :domain}.csr",
        :sudo => true, :input => [
          var(:country, 'AU'),
          var(:state),
          var(:city, ''),
          var(:organisation),
          var(:organisational_unit, ''),
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

def build_nginx
  in_build_dir {
    get_source("http://sysoev.ru/nginx/nginx-#{var(:versions)[:nginx]}.tar.gz") and
    get_source("http://www.grid.net.ru/nginx/download/nginx_upload_module-#{var(:versions)[:upload_module]}.tar.gz") and
    log_shell("Building nginx (this takes a minute or two)",
      Babushka::GemHelper.gem_bin_path / 'passenger-install-nginx-module',
      :sudo => true,
      :input => [
        '', # enter to continue
        '2', # custom build
        "nginx-#{var(:versions)[:nginx]}".p, # path to nginx source
        '', # accept /opt/nginx target path
        "--with-http_ssl_module --add-module='#{"nginx_upload_module-#{var(:versions)[:upload_module]}".p}'",
        '', # confirm settings
        '', # enter to continue
        '' # done
      ].join("\n")
    )
  }
end

def nginx_running?
  shell "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
end

def restart_nginx
  if nginx_running?
    log_shell "Restarting nginx", "/opt/nginx/sbin/nginx -s reload", :sudo => true
  end
end

dep 'webserver running' do
  requires 'webserver configured', 'webserver startup script'
  met? {
    returning nginx_running? do |result|
      result "There is #{result ? 'something' : 'nothing'} listening on #{result ? result.scan(/[0-9.*]+[.:]80/).first : 'port 80'}", :result => result
    end
  }
  meet :on => :linux do
    sudo '/etc/init.d/nginx start'
  end
  meet :on => :osx do
    log_error "launchctl should have already started nginx. Check /var/log/system.log for errors."
  end
end

dep 'webserver startup script' do
  requires 'webserver installed'
  on :linux do
    requires 'rcconf'
    met? { shell("rcconf --list").val_for('nginx') == 'on' }
    meet {
      render_erb 'nginx/nginx.init.d.erb', :to => '/etc/init.d/nginx', :perms => '755', :sudo => true
      sudo 'update-rc.d nginx defaults'
    }
  end
  on :osx do
    met? { !sudo('launchctl list').val_for('org.nginx').blank? }
    meet {
      render_erb 'nginx/nginx.launchd.erb', :to => '/Library/LaunchDaemons/org.nginx.plist', :sudo => true
      sudo 'launchctl load -w /Library/LaunchDaemons/org.nginx.plist'
    }
  end
end

dep 'webserver configured' do
  requires 'webserver installed', 'www user and group'
  define_var :nginx_prefix, :default => '/opt/nginx'
  helper(:nginx_conf) { var(:nginx_prefix) / 'conf/nginx.conf' }
  met? {
    if babushka_config? nginx_conf
      configured_root = nginx_conf.read.val_for('passenger_root')
      passenger_root = Babushka::GemHelper.gem_path_for('passenger')
      returning configured_root == passenger_root do |result|
        log_result "nginx is configured to use #{File.basename configured_root}", :result => result
      end
    end
  }
  meet {
    set :passenger_root, Babushka::GemHelper.gem_path_for('passenger')
    render_erb 'nginx/nginx.conf.erb', :to => nginx_conf, :sudo => true
  }
  after {
    sudo "mkdir -p #{var(:nginx_prefix) / 'conf/vhosts/on'}"
    restart_nginx
  }
end

dep 'webserver installed' do
  requires 'passenger', 'build tools', 'libssl headers', 'zlib headers'
  merge :versions, {:nginx => '0.7.64', :upload_module => '2.0.11'}
  met? {
    if !File.executable?(var(:nginx_prefix) / 'sbin/nginx')
      unmet "nginx isn't installed"
    else
      installed_version = shell(var(:nginx_prefix) / 'sbin/nginx -V') {|shell| shell.stderr }.val_for('nginx version').sub('nginx/', '')
      if installed_version != var(:versions)[:nginx]
        unmet "an outdated version of nginx is installed (#{installed_version})"
      elsif !shell(var(:nginx_prefix) / 'sbin/nginx -V') {|shell| shell.stderr }[Babushka::GemHelper.gem_path_for('passenger').to_s]
        unmet "nginx is installed, but built against the wrong passenger version"
      elsif !(Babushka::GemHelper.gem_path_for('passenger') / 'ext/nginx/HelperServer').exists?
        unmet "nginx is installed, but passenger's HelperServer wasn't built"
      else
        met "nginx-#{installed_version} is installed"
      end
    end
  }
  meet { build_nginx }
end
