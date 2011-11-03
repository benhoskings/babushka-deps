dep 'db', :username, :root, :env, :data_required, :require_db_deps do
  def orm
    grep('dm-rails', root/'Gemfile') ? :datamapper : :activerecord
  end

  def db_config
    (db_config = yaml(root / 'config/database.yml')[env.to_s]).tap {|config|
      unmeetable "There's no database.yml entry for the #{env} environment." if config.nil?
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
    else
      requires "seeded db".with(username, root, env, db_config['database'], db_type, orm)
    end
  end
end

dep 'seeded db', :username, :root, :env, :db_name, :db_type, :orm, :template => 'benhoskings:task' do
  requires "migrated db".with(root, env, orm)
  run {
    shell "bundle exec rake db:seed --trace RAILS_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'migrated db', :root, :env, :orm do
  requires "migrated #{orm} db".with(root, env)
end

dep 'migrated datamapper db', :root, :env, :template => 'task' do
  run {
    shell! "bundle exec rake db:migrate db:autoupgrade --trace RAILS_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'migrated activerecord db', :root, :env do
  met? {
    current_version = shell("bundle exec rake db:version RAILS_ENV=#{env}", :cd => root, :log => true) {|shell| shell.stdout.val_for('Current version') }
    latest_version = Dir[
      root / 'db/migrate/*.rb'
    ].map {|f| File.basename f }.push('0').sort.last.split('_', 2).first

    (current_version.gsub(/^0+/, '') == latest_version.gsub(/^0+/, '')).tap {|result|
      unless current_version.blank?
        if latest_version == '0'
          log_ok "This app doesn't have any migrations yet."
        elsif result
          log_ok "DB is up to date at migration #{current_version}"
        else
          log "DB needs migrating from #{current_version} to #{latest_version}"
        end
      end
    }
  }
  meet {
    shell "bundle exec rake db:migrate --trace RAILS_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'existing db', :username, :db_name, :db do
  requires "existing #{db} db".with(username, db_name)
end

dep 'db gem', :db do
  db.choose(%w[postgres mysql])
  requires db == 'postgres' ? 'pg.gem' : "#{db}.gem"
end

dep 'deployed migrations run', :old_id, :new_id, :env, :orm do
  setup {
    # If the branch was changed, git supplies 0000000 for old_id,
    # so the commit range is 'everything'.
    effective_old_id = old_id[/^0+$/] ? '' : old_id
    pending = shell("git diff --numstat #{effective_old_id}..#{new_id}").split("\n").grep(/^[\d\s]+db\/migrate\//)
    if pending.empty?
      log "No new migrations."
    else
      log "#{pending.length} migration#{'s' unless pending.length == 1} to run:"
      pending.each {|p| log p }

      requires 'maintenance page up'
      requires 'migrated db'.with('.', env, orm)
    end
  }
end
