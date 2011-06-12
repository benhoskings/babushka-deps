dep 'app bundled' do
  requires 'Gemfile'
  requires_when_unmet Dep('current dir:packages')
  met? { cd(var(:app_root)) { shell 'bundle check', :log => true } }
  meet { cd(var(:app_root)) {
    install_args = var(:app_env) != 'production' ? '' : "--deployment --without 'development test'"
    unless shell("bundle install #{install_args}", :log => true)
      confirm("Try a `bundle update`", :default => 'n') {
        shell 'bundle update', :log => true
      }
    end
  } }
end

dep 'Gemfile' do
  met? { (var(:app_root) / 'Gemfile').exists? }
end
