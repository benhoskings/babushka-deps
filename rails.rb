dep 'migrated db', :username, :root, :env, :data_required do
  def orm
    grep('dm-rails', root/'Gemfile') ? :datamapper : :activerecord
  end

  def db_name
    if (db_config = yaml(root / 'config/database.yml')[env.to_s]).nil?
      unmeetable "There's no database.yml entry for the #{env} environment."
    else
      db_config['database']
    end
  end

  requires 'app bundled', 'db gem'
  requires "existing #{data_required.starts_with?('y') ? 'data' : 'db'}".with(username, db_name)
  requires "migrated #{orm} db".with(root, env)
end

dep 'migrated datamapper db', :root, :env, :template => 'task' do
  run {
    shell "bundle exec rake db:migrate db:autoupgrade db:seed --trace RAILS_ENV=#{env}", :cd => root
  }
end

dep 'migrated activerecord db', :root, :env do
  met? {
    current_version = shell("bundle exec rake db:version RAILS_ENV=#{env}", :cd => root) {|shell| shell.stdout.val_for('Current version') }
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
    shell "bundle exec rake db:migrate --trace RAILS_ENV=#{env}", :cd => root
  }
end
