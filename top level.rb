dep 'system' do
  requires 'set.locale', 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo', 'tmp cleaning grace period', 'core software'
  requires 'bad certificates removed' if Babushka::Base.host.linux?
  setup {
    unmeetable "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'user setup', :username, :key do
  username.default(shell('whoami'))
  requires 'dot files'.with(username), 'passwordless ssh logins'.with(username, key), 'public key', 'zsh'
end

dep 'rails app' do
  requires 'webapp', 'web repo', 'app bundled', 'migrated db', 'rails.logrotate'
  define_var :app_env, :default => 'production'
  define_var :app_root, :default => '~/current', :type => :path
  setup {
    set :username, shell('whoami')
  }
end

dep 'proxied app' do
  requires 'webapp'
  setup {
    set :vhost_type, 'proxy'
  }
end

dep 'webapp' do
  requires 'user exists', 'vhost enabled.nginx', 'webserver running.nginx'
  define_var :domain, :default => :username
  setup {
    set :home_dir_base, "/srv/http"
  }
end

dep 'core software' do
  requires {
    on :linux, 'vim.managed', 'curl.managed', 'htop.managed', 'jnettop.managed', 'screen.managed', 'nmap.managed', 'tree.managed'
    on :osx, 'curl.managed', 'htop.managed', 'jnettop.managed', 'nmap.managed', 'tree.managed'
  }
end
