dep 'migrated db' do
  requires 'deployed app', 'existing db', 'db gem'
  setup {
    if (db_config = yaml(var(:rails_root) / 'config/database.yml')[var(:rails_env)]).nil?
      log_error "There's no database.yml entry for the #{var(:rails_env)} environment."
    else
      set :db_name, db_config['database']
    end
  }
  def orm
    grep('dm-rails', var(:rails_root)/'Gemfile') ? :datamapper : :activerecord
  end
  setup {
    requires "migrated #{orm} db"
  }
end

dep 'migrated datamapper db', :template => 'task' do
  run {
    bundle_rake "db:autoupgrade db:seed"
  }
end

dep 'migrated activerecord db' do
  met? {
    current_version = bundle_rake("db:version") {|shell| shell.stdout.val_for('Current version') }
    latest_version = Dir[
      var(:rails_root) / 'db/migrate/*.rb'
    ].map {|f| File.basename f }.push('0').sort.last.split('_', 2).first

    (current_version.gsub(/^0+/, '') == latest_version.gsub(/^0+/, '')).tap {|result|
      unless current_version.blank?
        if latest_version == '0'
          log_verbose "This app doesn't have any migrations yet."
        elsif result
          log_ok "DB is up to date at migration #{current_version}"
        else
          log "DB needs migrating from #{current_version} to #{latest_version}"
        end
      end
    }
  }
  meet { bundle_rake "db:migrate --trace" }
end
