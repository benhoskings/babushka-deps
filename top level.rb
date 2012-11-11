dep 'system', :host_name, :locale_name do
  requires [
    'set.locale'.with(locale_name),
    'core software',
    'hostname'.with(host_name),
    'secured ssh logins',
    'lax host key checking',
    'admins can sudo',
    'tmp cleaning grace period'
  ]
  requires 'bad certificates removed' if Babushka.host.linux?
  setup {
    unmeetable! "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'user setup', :username, :key do
  username.default(shell('whoami'))
  requires [
    'dot files'.with(:username => username),
    'passwordless ssh logins'.with(username, key),
    'public key',
    'zsh'.with(username)
  ]
end

dep 'rails app', :domain, :domain_aliases, :username, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :env, :nginx_prefix, :enable_http, :enable_https, :force_https, :data_required do
  requires 'rack app'.with(domain, domain_aliases, username, path, listen_host, listen_port, proxy_host, proxy_port, env, nginx_prefix, enable_http, enable_https, force_https, data_required)
  requires 'db'.with(username, path, env, data_required, 'yes')
end

dep 'rack app', :domain, :domain_aliases, :username, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :env, :nginx_prefix, :enable_http, :enable_https, :force_https, :data_required do
  username.default!(shell('whoami'))
  path.default('~/current')
  env.default(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')

  requires 'webapp'.with('unicorn', domain, domain_aliases, username, path, listen_host, listen_port, proxy_host, proxy_port, nginx_prefix, enable_http, enable_https, force_https)
  requires 'web repo'.with(path)
  requires 'app bundled'.with(path, env)
  requires 'rack.logrotate'.with(username)
end

dep 'proxied app' do
  requires 'webapp'.with(:type => 'proxy')
end

dep 'webapp', :type, :domain, :domain_aliases, :username, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix, :enable_http, :enable_https, :force_https do
  username.default!(domain)
  requires 'user exists'.with(username, '/srv/http')
  requires 'vhost enabled.nginx'.with(type, domain, domain_aliases, path, listen_host, listen_port, proxy_host, proxy_port, nginx_prefix, enable_http, enable_https, force_https)
  requires 'running.nginx'
end

dep 'core software' do
  requires {
    on :lenny, 'sudo.bin', 'lsof.bin', 'vim.bin', 'curl.bin', 'traceroute.bin', 'htop.bin', 'iotop.bin', 'jnettop.bin', 'nmap.bin', 'tree.bin', 'pv.bin'
    on :linux, 'sudo.bin', 'lsof.bin', 'vim.bin', 'curl.bin', 'traceroute.bin', 'htop.bin', 'iotop.bin', 'jnettop.bin', 'tmux.bin', 'nmap.bin', 'tree.bin', 'pv.bin'
    on :osx, 'sudo.bin', 'lsof.bin', 'vim.bin', 'curl.bin', 'traceroute.bin', 'tmux.bin', 'nmap.bin', 'tree.bin', 'pv.bin'
  }
end
