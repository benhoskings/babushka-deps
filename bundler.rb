dep 'app bundled' do
  requires 'deployed app', 'bundler.gem'
  met? { in_dir(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { in_dir(var(:rails_root)) { shell 'bundle install --without test', :log => true } }
  # TODO maybe vendor the gems by default? Depends if gem partitioning is
  # required, or if bundler's version requirement resolution is good enough
  # that it doesn't matter.
  # `bundle install ./vendor --disable-shared-gems`
end

dep 'deployed app' do
  met? { File.directory? var(:rails_root) / 'app' }
end
