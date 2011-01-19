dep 'Ruby on Rails.tmbundle' do
  source 'git://github.com/drnic/ruby-on-rails-tmbundle.git'
end

dep 'Sinatra.tmbundle' do
  source 'git://github.com/foca/sinatra-tmbundle.git'
end

dep 'Tcl.tmbundle' do
  source 'git://github.com/textmate/tcl.tmbundle.git'
end

dep 'Cucumber.tmbundle' do
  source 'git://github.com/bmabey/cucumber-tmbundle.git'
end

dep "Gists.tmbundle" do
  requires 'github token set'
  source "git://github.com/ivanvc/gists-tmbundle.git"
end

dep 'RubyAMP.tmbundle' do
  source 'git://github.com/timcharper/rubyamp.git'
end

dep 'SCSS.tmbundle' do
  source 'git://github.com/kuroir/SCSS.tmbundle.git'
end

dep 'nginx.tmbundle' do
  source 'git://github.com/johnmuhl/nginx-tmbundle.git'
end
