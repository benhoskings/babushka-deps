dep 'Ruby on Rails.tmbundle' do
  source 'git://github.com/drnic/ruby-on-rails-tmbundle.git'
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

