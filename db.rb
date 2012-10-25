dep 'db', :username, :root, :env, :data_required, :require_db_deps do
  def orm
    (root/'Gemfile').grep('dm-rails') ? :datamapper : :activerecord
  end

  def db_config
    (root / 'config/database.yml').yaml[env.to_s].tap {|config|
      unmeetable! "There's no database.yml entry for the #{env} environment." if config.nil?
    }
  end

  def db_type
    # Use 'postgres' when rails says 'postgresql' or similar.
    db_config['adapter'].sub('postgresql', 'postgres')
  end

  requires 'app bundled'.with(root, env)

  if require_db_deps[/^y/]
    requires 'db gem'.with(db_type)
    if data_required[/^y/]
      requires "existing data".with(username, db_config['database'])
      requires "migrated db".with(username, root, env, db_config['database'], db_type, 'no')
    else
      requires "seeded db".with(username, root, env, db_config['database'], db_type, orm)
    end
  end
end

dep 'seeded db', :username, :root, :env, :db_name, :db_type, :orm, :template => 'benhoskings:task' do
  requires "migrated db".with(username, root, env, db_name, db_type, 'no')
  root.default!('.')
  run {
    shell "bundle exec rake db:seed --trace RAILS_ENV=#{env} RACK_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'migrated db', :username, :root, :env, :db_name, :db_type, :deploying, :template => 'task' do
  root.default!('.')
  deploying.default!('no')
  requires 'schema loaded'.with(:username => username, :root => root, :db_name => db_name, :db_type => db_type) unless deploying[/^y/]
  run {
    shell! "bundle exec rake db:migrate --trace RAILS_ENV=#{env} RACK_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'schema loaded', :username, :root, :schema_path, :db_name, :db_type do
  root.default!('.')
  schema_path.default!('db/schema.sql')
  requires 'existing db'.with(username, db_name, db_type)
  met? {
    shell(
      %Q{psql #{db_name} -t -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'public'"}
    ).to_i.tap {|tables|
      log "There are #{tables} tables in #{db_name}."
    } > 0
  }
  meet {
    log_shell "Applying #{schema_path} to #{db_name}", "psql #{db_name} -f -", :input => (root / schema_path).p.read!
  }
end

dep 'existing db', :username, :db_name, :db_type do
  requires "existing #{db_type} db".with(username, db_name)
end

dep 'db gem', :db do
  db.choose(%w[postgres mysql])
  requires db == 'postgres' ? 'pg.gem' : "#{db}.gem"
end
