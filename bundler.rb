dep 'app bundled', :root, :env do
  requires_when_unmet Dep('current dir:packages')
  met? {
    if !(root / 'Gemfile').exists?
      log "No Gemfile - skipping bundling."
      true
    else
      shell? 'bundle check', :cd => root, :log => true
    end
  }
  meet {
    install_args = %w[development test].include?(env) ? '' : "--deployment --without 'development test'"
    unless shell("bundle install #{install_args} | grep -v '^Using '", :cd => root, :log => true)
      confirm("Try a `bundle update`", :default => 'n') {
        shell 'bundle update', :cd => root, :log => true
      }
    end
  }
end
