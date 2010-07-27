dep 'app bundled' do
  requires 'deployed app', 'bundler.gem'
  met? { in_dir(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { in_dir(var(:rails_root)) { shell 'bundle install --without test', :log => true } }
end

dep 'migrated db' do
  requires 'deployed app', 'existing db', 'db gem'
  setup {
    if (db_config = yaml(var(:rails_root) / 'config/database.yml')[var(:rails_env)]).nil?
      log_error "There's no database.yml entry for the #{var(:rails_env)} environment."
    else
      set :db_name, db_config['database']
    end
  }
  met? {
    current_version = rails_rake("db:version") {|shell| shell.stdout.val_for('Current version') }
    latest_version = Dir[
      var(:rails_root) / 'db/migrate/*.rb'
    ].map {|f| File.basename f }.push('0').sort.last.split('_', 2).first

    returning current_version.gsub(/^0+/, '') == latest_version.gsub(/^0+/, '') do |result|
      unless current_version.blank?
        if latest_version == '0'
          log_verbose "This app doesn't have any migrations yet."
        elsif result
          log_ok "DB is up to date at migration #{current_version}"
        else
          log "DB needs migrating from #{current_version} to #{latest_version}"
        end
      end
    end
  }
  meet { rails_rake "db:migrate --trace" }
end

dep 'deployed app' do
  met? { File.directory? var(:rails_root) / 'app' }
end
