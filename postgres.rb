dep 'existing postgres db' do
  requires 'postgres access'
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{var :db_name}\s+\|/)
    }.empty?
  }
  meet {
    shell "createdb -O '#{var :username}' '#{var :db_name}'"
  }
end

dep 'existing data' do
  requires 'existing db'
  met? {
    shell("psql #{var(:db_name)} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first.tap {|rows|
      if rows && rows.to_i > 0
        log "There are already #{rows} tables."
      else
        unmeetable <<-MSG
That database is empty. Load a database dump with:
$ cat #{var(:db_name)} | ssh #{var(:username)}@#{var(:domain)} 'psql #{var(:db_name)}'
        MSG
      end
    }
  }
end

dep 'pg.gem' do
  requires 'postgres.managed'
  provides []
end

dep 'postgres access' do
  requires 'postgres.managed', 'user exists'
  met? { !sudo("echo '\\du' | #{which 'psql'}", :as => 'postgres').split("\n").grep(/^\W*\b#{var :username}\b/).empty? }
  meet { sudo "createuser -SdR #{var :username}", :as => 'postgres' }
end

dep 'postgres backups' do
  requires 'postgres.managed'
  met? { shell "test -x /etc/cron.hourly/postgres_offsite_backup" }
  before {
    sudo("ssh #{var :offsite_host} 'true'").tap {|result|
      if result
        log_ok "publickey login to #{var :offsite_host}"
      else
        log_error "You need to add root's public key to #{var :offsite_host}:~/.ssh/authorized_keys."
      end
    }
  }
  meet {
    render_erb 'postgres/offsite_backup.rb.erb', :to => '/usr/local/bin/postgres_offsite_backup', :perms => '755', :sudo => true
    sudo "ln -sf /usr/local/bin/postgres_offsite_backup /etc/cron.hourly/"
  }
end

dep 'postgres.managed', :version do
  version.default('9.1')
  requires {
    on :apt, 'set.locale', 'postgres.ppa'
    on :brew, 'set.locale'
  }
  installs {
    via :apt, ["postgresql-#{owner.version}", "libpq-dev"]
    via :brew, "postgresql"
  }
  provides "psql ~> #{version}.0"
end

dep 'postgres.ppa' do
  adds 'ppa:pitti/postgresql'
end
