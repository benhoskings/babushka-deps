dep 'system' do
  requires 'set.locale', 'hostname', 'secured ssh logins', 'lax host key checking', 'admins can sudo', 'tmp cleaning grace period', 'core software'
  setup {
    unmeetable "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'user setup' do
  requires 'dot files', 'passwordless ssh logins', 'public key', 'zsh'
  define_var :username, :default => shell('whoami')
  setup {
    set :username, shell('whoami')
  }
end

dep 'rails app' do
  requires 'webapp', 'web repo', 'app bundled', 'migrated db'
  define_var :rails_env, :default => 'production'
  define_var :rails_root, :default => '~/current', :type => :path
  setup {
    set :username, shell('whoami')
    set :vhost_type, 'passenger'
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
