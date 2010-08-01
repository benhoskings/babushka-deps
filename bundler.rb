dep 'app bundled' do
  requires 'deployed app', 'bundler.gem'
  met? { in_dir(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { in_dir(var(:rails_root)) { shell 'bundle install --without test', :log => true } }
end

dep 'deployed app' do
  met? { File.directory? var(:rails_root) / 'app' }
end
