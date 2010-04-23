tmbundle "Gists.tmbundle" do
  requires 'github token set'
  source "git://github.com/ivanvc/gists-tmbundle.git"
end

dep 'github token set' do
  met? { !shell('git config --global github.token').blank? }
  meet { shell("git config --global github.token '#{var(:github_token)}'")}
end
