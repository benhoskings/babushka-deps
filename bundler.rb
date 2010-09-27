dep 'app bundled' do
  requires 'deployed app', 'bundler.gem'
  met? { in_dir(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { in_dir(var(:rails_root)) {
    if var(:rails_env) == 'production'
      shell 'bundle install --without development --without test --path ./vendor', :log => true
    else
      shell 'bundle install', :log => true
    end
  } }
end

dep 'deployed app' do
  met? { File.directory? var(:rails_root) / 'app' }
end
