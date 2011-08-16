dep 'app bundled' do
  requires_when_unmet Dep('current dir:packages')
  met? {
    if !(var(:app_root) / 'Gemfile').exists?
      log "No Gemfile - skipping bundling."
      true
    else
      cd(var(:app_root)) { shell? 'bundle check', :log => true }
    end
  }
  meet { cd(var(:app_root)) {
    install_args = var(:app_env) != 'production' ? '' : "--deployment --without 'development test'"
    unless shell("bundle install #{install_args}", :log => true)
      confirm("Try a `bundle update`", :default => 'n') {
        shell 'bundle update', :log => true
      }
    end
  } }
end
