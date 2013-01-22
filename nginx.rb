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
  def unicorn_socket
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

dep 'vhost enabled.nginx', :vhost_type, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix, :enable_http, :enable_https, :force_https do
  requires 'vhost configured.nginx'.with(vhost_type, domain, domain_aliases, path, listen_host, listen_port, proxy_host, proxy_port, nginx_prefix, enable_http, enable_https, force_https)
  met? { vhost_link.exists? }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts/on'}"
    sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'"
  }
  after { restart_nginx }
end

dep 'vhost configured.nginx', :vhost_type, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix, :enable_http, :enable_https, :force_https do
  domain_aliases.default('').ask('Domains to alias (no need to specify www. aliases)')
  listen_host.default!('[::]')
  listen_port.default!('80')
  proxy_host.default('localhost')
  proxy_port.default('8000')
  enable_http.default!('yes')
  enable_https.default('no')
  force_https.default('no')
  def www_aliases
    "#{domain} #{domain_aliases}".split(/\s+/).reject {|d|
      d[/^\*\./] || d[/^www\./]
    }.map {|d|
      "www.#{d}"
    }
  end
  def server_names
    [domain].concat(
      domain_aliases.to_s.split(/\s+/)
    ).concat(
      www_aliases
    ).uniq
  end

  vhost_type.default('unicorn').choose(%w[unicorn proxy static])
  path.default("~#{domain}/current".p) if shell?('id', domain)

  requires 'configured.nginx'.with(nginx_prefix)
  requires 'unicorn configured'.with(path) if vhost_type == 'unicorn'

  met? {
    Babushka::Renderable.new(vhost_conf).from?(dependency.load_path.parent / "nginx/vhost.conf.erb") and
    Babushka::Renderable.new(vhost_common).from?(dependency.load_path.parent / "nginx/#{vhost_type}_vhost.common.erb")
  }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts'}"
    render_erb "nginx/vhost.conf.erb", :to => vhost_conf, :sudo => true
    render_erb "nginx/#{vhost_type}_vhost.common.erb", :to => vhost_common, :sudo => true
  }
end

dep 'self signed cert.nginx', :domain, :nginx_prefix, :country, :state, :city, :organisation, :organisational_unit, :email do
  requires 'nginx.src'.with(:nginx_prefix => nginx_prefix)
  met? { %w[key crt].all? {|ext| (cert_path / "#{domain}.#{ext}").exists? } }
  meet {
    cd cert_path, :create => "700", :sudo => true do
      log_shell("generating private key", "openssl genrsa -out #{domain}.key 2048", :sudo => true) and
      log_shell("generating certificate", "openssl req -new -key #{domain}.key -out #{domain}.csr",
        :sudo => true, :input => [
          country.default('AU'),
          state,
          city.default(''),
          organisation,
          organisational_unit.default(''),
          domain,
          email,
          '', # password
          '', # optional company name
          '' # done
        ].join("\n")
      ) and
      log_shell("signing certificate with key", "openssl x509 -req -days 365 -in #{domain}.csr -signkey #{domain}.key -out #{domain}.crt", :sudo => true)
    end
    restart_nginx
  }
end

dep 'running.nginx', :nginx_prefix do
  requires_when_unmet 'configured.nginx'.with(nginx_prefix)
  requires 'startup script.nginx'.with(nginx_prefix)
  met? {
    nginx_running?.tap {|result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 80."
    }
  }
  meet :on => :linux do
    sudo 'initctl start nginx'
  end
  meet :on => :osx do
    log_error "launchctl should have already started nginx. Check /var/log/system.log for errors."
  end
end

dep 'startup script.nginx', :nginx_prefix do
  requires 'nginx.src'.with(:nginx_prefix => nginx_prefix)
  on :linux do
    met? {
      raw_shell('initctl list | grep nginx').stdout[/^nginx\b/]
    }
    meet {
      render_erb 'nginx/nginx.init.conf.erb', :to => '/etc/init/nginx.conf'
    }
  end
  on :osx do
    met? { !sudo('launchctl list').split("\n").grep(/org\.nginx/).empty? }
    meet {
      render_erb 'nginx/nginx.launchd.erb', :to => '/Library/LaunchDaemons/org.nginx.plist', :sudo => true, :comment => '<!--', :comment_suffix => '-->'
      sudo 'launchctl load -w /Library/LaunchDaemons/org.nginx.plist'
    }
  end
end

dep 'configured.nginx', :nginx_prefix do
  nginx_prefix.default!('/opt/nginx') # This is required because nginx.src might be cached.
  requires 'nginx.src'.with(:nginx_prefix => nginx_prefix), 'www user and group', 'nginx.logrotate'
  met? {
    Babushka::Renderable.new(nginx_conf).from?(dependency.load_path.parent / "nginx/nginx.conf.erb")
  }
  meet {
    render_erb 'nginx/nginx.conf.erb', :to => nginx_conf, :sudo => true
  }
end

dep 'nginx.src', :nginx_prefix, :version, :upload_module_version do
  nginx_prefix.default!("/opt/nginx")
  version.default!('1.2.4')
  upload_module_version.default!('2.2')

  requires 'pcre.managed', 'libssl headers.managed', 'zlib headers.managed'
  on :linux do 
    requires "unzip.managed"
  end

  source "http://nginx.org/download/nginx-#{version}.tar.gz"
  extra_source "https://github.com/vkholodkov/nginx-upload-module/archive/#{upload_module_version}.zip"

  configure_args L{
    [
      "--with-ipv6",
      "--with-pcre",
      "--with-http_ssl_module",
      "--with-http_gzip_static_module",
      "--add-module='../../#{upload_module_version}/nginx-upload-module-#{upload_module_version}'",
      "--with-ld-opt='#{shell('pcre-config --libs')}'"
    ].join(' ')
  }

  prefix nginx_prefix
  provides nginx_prefix / 'sbin/nginx'

  configure { log_shell "configure", default_configure_command }
  build { log_shell "build", "make" }
  install { log_shell "install", "make install", :sudo => true }

  met? {
    if !File.executable?(nginx_prefix / 'sbin/nginx')
      log "nginx isn't installed"
    else
      installed_version = shell(nginx_prefix / 'sbin/nginx -v') {|shell| shell.stderr }.val_for(/(nginx: )?nginx version:/).sub('nginx/', '')
      (installed_version.to_version >= version.to_s).tap {|result|
        log "nginx-#{installed_version} is installed"
      }
    end
  }
end

dep 'http basic logins.nginx', :nginx_prefix, :domain, :username, :pass do
  nginx_prefix.default!('/opt/nginx')
  requires 'http basic auth enabled.nginx'.with(nginx_prefix, domain)
  met? { shell("curl -I -u #{username}:#{pass} #{domain}").val_for('HTTP/1.1')[/^[25]0\d\b/] }
  meet { (nginx_prefix / 'conf/htpasswd').append("#{username}:#{pass.to_s.crypt(pass)}") }
  after { restart_nginx }
end

dep 'http basic auth enabled.nginx', :nginx_prefix, :domain do
  requires 'configured.nginx'.with(nginx_prefix)
  met? { shell("curl -I #{domain}").val_for('HTTP/1.1')[/^401\b/] }
  meet {
    vhost_common.p.append(%Q{auth_basic 'Restricted';\nauth_basic_user_file htpasswd;})
  }
  after {
    sudo "touch #{nginx_prefix / 'conf/htpasswd'}"
    restart_nginx
  }
end
