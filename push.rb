dep 'deploy!' do
  define_var :ref, :message => "What would you like to deploy?", :default => 'HEAD'
  requires [
    'pushable repo',
    'pushed to production'
  ]
end

dep 'pushable repo' do
  met? {
    true
    # !rebasing? and
    # !bisecting? and
  }
end

dep 'pushed to production' do
  requires [
    'pushed to origin',
    'ok to update production'
  ]
  met? {
    shell("git rev-parse --short production/production") == var(:ref)
  }
end

dep 'ok to update production' do
  setup {
    shell("git fetch production")
  }
  met? {
    shell("git branch -r --contains #{var(:ref)}").split("\n").include?("origin/master") or
    confirm("Pushing to production would not fast forward. That OK?")
  }
end

dep 'pushed to origin' do
  requires [
  ]
  met? {
    shell("git branch -r --contains #{var(:ref)}").split("\n").map(&:strip).include? "origin/master"
  }
end
