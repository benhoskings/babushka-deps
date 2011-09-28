meta :nginx do
  accepts_list_for :source
  accepts_list_for :extra_source

  def nginx_bin;    nginx_prefix / "sbin/nginx" end
  def cert_path;    nginx_prefix / "conf/certs" end
  def nginx_conf;   nginx_prefix / "conf/nginx.conf" end
  def vhost_conf;   nginx_prefix / "conf/vhosts/#{domain}.conf" end
  def vhost_common; nginx_prefix / "conf/vhosts/#{domain}.common" end
  def vhost_link;   nginx_prefix / "conf/vhosts/on/#{domain}.conf" end

  def upstream_name
    "#{domain}.upstream"
  end
  def unicorn_socket_path
    path / 'tmp/sockets/unicorn.socket'
  end
  def nginx_running?
    shell? "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
  end
  def restart_nginx
    if nginx_running?
      log_shell "Restarting nginx", "#{nginx_bin} -s reload", :sudo => true
      sleep 1 # The reload just sends the signal, and doesn't wait.
    end
  end
end

dep 'vhost enabled.nginx', :nginx_prefix, :type, :domain, :path do
  requires 'vhost configured.nginx'.with(nginx_prefix, type, domain, path)
  met? { vhost_link.exists? }
  meet { sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'" }
  after { restart_nginx }
end

dep 'vhost configured.nginx', :nginx_prefix, :type, :domain, :path do
  define_var :www_aliases, :default => L{
    "#{domain} #{var :extra_domains}".split(' ').compact.map(&:strip).reject {|d|
      d.starts_with? '*.'
    }.reject {|d|
      d.starts_with? 'www.'
    }.map {|d|
      "www.#{d}"
    }.join(' ')
  }

  type.default('unicorn').choose(%w[unicorn proxy static])
  path.default("~#{domain}/current".p) if shell?('id', domain)

  requires 'configured.nginx'.with(nginx_prefix)
  requires 'unicorn configured'.with(path) if type == 'unicorn'

  met? {
    Babushka::Renderable.new(vhost_conf).from?(dependency.load_path.parent / "nginx/vhost.conf.erb") and
    Babushka::Renderable.new(vhost_common).from?(dependency.load_path.parent / "nginx/#{type}_vhost.common.erb")
  }
  meet {
    render_erb "nginx/vhost.conf.erb", :to => vhost_conf, :sudo => true
    render_erb "nginx/#{type}_vhost.common.erb", :to => vhost_common, :sudo => true
  }
end

dep 'self signed cert.nginx' do
  requires 'nginx.src'
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

dep 'running.nginx' do
  requires 'configured.nginx', 'startup script.nginx'
  met? {
    nginx_running?.tap {|result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 80."
    }
  }
  meet :on => :linux do
    sudo '/etc/init.d/nginx start'
  end
  meet :on => :osx do
    log_error "launchctl should have already started nginx. Check /var/log/system.log for errors."
  end
end

dep 'startup script.nginx' do
  requires 'nginx.src'
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

dep 'configured.nginx', :nginx_prefix do
  requires 'nginx.src'.with(:nginx_prefix => nginx_prefix), 'www user and group', 'nginx.logrotate'
  met? {
    Babushka::Renderable.new(nginx_conf).from?(dependency.load_path.parent / "nginx/nginx.conf.erb")
  }
  meet {
    render_erb 'nginx/nginx.conf.erb', :to => nginx_conf, :sudo => true
  }
  after {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts/on'}"
  }
end

dep 'nginx.src', :nginx_prefix, :version, :upload_module_version do
  nginx_prefix.default!("/opt/nginx")
  version.default!('1.0.6')
  upload_module_version.default!('2.2.0')
  requires 'pcre.managed', 'libssl headers.managed', 'zlib headers.managed'
  source "http://nginx.org/download/nginx-#{version}.tar.gz"
  extra_source "http://www.grid.net.ru/nginx/download/nginx_upload_module-#{upload_module_version}.tar.gz"
  configure_args "--with-ipv6", "--with-pcre", "--with-http_ssl_module",
    "--add-module='../../nginx_upload_module-#{upload_module_version}/nginx_upload_module-#{upload_module_version}'"
  prefix nginx_prefix
  provides nginx_prefix / 'sbin/nginx'

  configure { log_shell "configure", default_configure_command }
  build { log_shell "build", "make" }
  install { log_shell "install", "make install", :sudo => true }

  met? {
    if !File.executable?(nginx_prefix / 'sbin/nginx')
      unmet "nginx isn't installed"
    else
      installed_version = shell(nginx_prefix / 'sbin/nginx -v') {|shell| shell.stderr }.val_for(/(nginx: )?nginx version:/).sub('nginx/', '')
      if installed_version != version
        unmet "an outdated version of nginx is installed (#{installed_version})"
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
