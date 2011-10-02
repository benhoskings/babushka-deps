dep 'existing postgres db', :username, :db_name do
  requires 'postgres access'.with(username)
  met? {
    !shell("psql -l") {|shell|
      shell.stdout.split("\n").grep(/^\s*#{db_name}\s+\|/)
    }.empty?
  }
  meet {
    shell "createdb -O '#{username}' '#{db_name}'"
  }
end

dep 'existing data', :username, :db_name, :db do
  requires 'existing db'.with(username, db_name, db)
  met? {
    shell("psql #{db_name} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first.tap {|rows|
      if rows && rows.to_i > 0
        log "There are already #{rows} tables."
      else
        unmeetable <<-MSG
That database is empty. Load a database dump with:
$ cat #{db_name} | ssh #{username}@#{shell('hostname -f')} 'psql #{db_name}'
        MSG
      end
    }
  }
end

dep 'pg.gem' do
  requires 'postgres.managed'
  provides []
end

dep 'postgres access', :username do
  requires 'postgres.managed', 'user exists'.with(:username => username)
  met? { !sudo("echo '\\du' | #{which 'psql'}", :as => 'postgres').split("\n").grep(/^\W*\b#{username}\b/).empty? }
  meet { sudo "createuser -SdR #{username}", :as => 'postgres' }
end

dep 'postgres backups', :offsite_host do
  requires 'postgres.managed'
  met? { shell "test -x /etc/cron.hourly/postgres_offsite_backup" }
  before {
    sudo("ssh #{offsite_host} 'true'").tap {|result|
      if result
        log_ok "publickey login to #{offsite_host}"
      else
        log_error "You need to add root's public key to #{offsite_host}:~/.ssh/authorized_keys."
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
  # Assume the installed version if there is one
  version.default!(shell('psql --version').val_for('psql (PostgreSQL)')[/^\d\.\d/]) if which('psql')
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
