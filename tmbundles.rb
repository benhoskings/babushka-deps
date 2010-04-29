tmbundle 'Ruby on Rails.tmbundle' do
  source 'git://github.com/drnic/ruby-on-rails-tmbundle.git'
end

tmbundle 'Tcl.tmbundle' do
  source 'git://github.com/textmate/tcl.tmbundle.git'
end

tmbundle 'Cucumber.tmbundle' do
  source 'git://github.com/bmabey/cucumber-tmbundle.git'
end

tmbundle "Gists.tmbundle" do
  requires 'github token set'
  source "git://github.com/ivanvc/gists-tmbundle.git"
end

dep 'github token set' do
  met? { !shell('git config --global github.token').blank? }
  meet { shell("git config --global github.token '#{var(:github_token)}'")}
end
