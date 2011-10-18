dep 'system' do
  requires 'set.locale', 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo', 'tmp cleaning grace period', 'core software'
  requires 'bad certificates removed' if Babushka::Base.host.linux?
  setup {
    unmeetable "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'user setup', :username, :key do
  username.default(shell('whoami'))
  requires 'dot files'.with(username), 'passwordless ssh logins'.with(username, key), 'public key', 'zsh'.with(username)
end

dep 'rails app', :domain, :username, :path, :env, :data_required do
  username.default!(shell('whoami'))
  env.default('production')

  requires 'webapp'.with('unicorn', domain, username, path)
  requires 'web repo'.with(path)
  requires 'app bundled'.with(path, env)
  requires 'db'.with(username, path, env, data_required, 'yes')
  requires 'rails.logrotate'
end

dep 'proxied app' do
  requires 'webapp'.with('proxy')
end

dep 'webapp', :type, :domain, :username, :path do
  username.default!(domain)
  requires 'user exists'.with(username, '/srv/http')
  requires 'vhost enabled.nginx'.with(:type => type, :domain => domain, :path => path)
  requires 'running.nginx'
end

dep 'core software' do
  requires {
    on :linux, 'vim.managed', 'curl.managed', 'htop.managed', 'iotop.managed', 'jnettop.managed', 'screen.managed', 'nmap.managed', 'tree.managed'
    on :osx, 'curl.managed', 'htop.managed', 'jnettop.managed', 'nmap.managed', 'tree.managed'
  }
end
