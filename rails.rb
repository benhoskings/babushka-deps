dep 'migrated db', :username, :root, :env, :data_required, :require_db_deps do
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
      requires "existing data".with(username, db_config['database'], db_type)
    else
      requires "seeded db".with(username, db_config['database'], db_type, root, env)
    end
    requires "migrated #{orm} db".with(root, env)
  end
end

dep 'migrated datamapper db', :root, :env, :template => 'task' do
  run {
    shell "bundle exec rake db:migrate db:autoupgrade db:seed --trace RAILS_ENV=#{env}", :cd => root
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
