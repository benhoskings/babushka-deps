def parse_config_gem_deps
  IO.readlines(
    var(:rails_root) / 'config/environment.rb'
  ).grep(/^\s*config\.gem/).map {|l|
    i = l.scan /config\.gem[\s\('"]+([\w-]+)(['"],\s*\:version\s*=>\s*['"]([<>=!~.0-9\s]+)['"])?.*$/

    if i.first.nil? || i.first.first.nil?
      log_error "Couldn't parse '#{l.chomp}' in #{'config/environment.rb'.p}."
    else
      ver i.first.first, i.first.last
    end
  }.compact
end

def parse_rails_dep
  IO.readlines(
    var(:rails_root) / 'config/environment.rb'
  ).grep(/RAILS_GEM_VERSION/).map {|l|
    $1 if l =~ /^[^#]*RAILS_GEM_VERSION\s*=\s*["']([!~<>=]*\s*[\d.]+)["']/
  }.compact.map {|v|
    ver 'rails', v
  }
end

def parse_gem_deps
  parse_rails_dep + parse_config_gem_deps
end

dep 'gems installed' do
  setup {
    parse_gem_deps.map {|gem_spec|
      # Make a new Dep for each gem this app needs...
      dep("#{gem_spec}.gem") {
        provides []
      }
    }.each {|dep|
      # ... and set each one as a requirement of this dep.
      requires dep.name
    }
  }
end

dep 'migrated db' do
  requires 'deployed app', 'existing db', 'rails.gem'
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

dep 'rails.gem'
