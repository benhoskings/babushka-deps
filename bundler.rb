dep 'app bundled', :root, :env do
  requires_when_unmet Dep('current dir:packages')
  met? {
    if !(root / 'Gemfile').exists?
      log "No Gemfile - skipping bundling."
      true
    else
      cd(root) { shell? 'bundle check', :log => true }
    end
  }
  meet { cd(root) {
    install_args = env != 'production' ? '' : "--deployment --without 'development test'"
    unless shell("bundle install #{install_args}", :log => true)
      confirm("Try a `bundle update`", :default => 'n') {
        shell 'bundle update', :log => true
      }
    end
  } }
end
