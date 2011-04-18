dep 'app bundled' do
  requires 'Gemfile'
  requires_when_unmet Dep('current dir:packages')
  met? { cd(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { cd(var(:rails_root)) {
    install_args = var(:rails_env) != 'production' ? '' : "--deployment --without 'development test'"
    unless shell("bundle install #{install_args}", :log => true)
      confirm("Try a `bundle update`") {
        shell 'bundle update', :log => true
      }
    end
  } }
end

dep 'Gemfile' do
  met? { (var(:rails_root) / 'Gemfile').exists? }
end
