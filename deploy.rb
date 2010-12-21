
meta :task do
  accepts_block_for :run
  template {
    met? { @run_called }
    meet {
      call_task(:run)
      @run_called = true
    }
  }
end

dep 'deploy repo up to date' do
  requires [
    'branch name',
    'repo clean',
    'branch exists',
    'branch checked out',
    'HEAD up to date',
    'submodules up to date',
    'cached JS and CSS removed',
    'app bundled',
    'app flagged for restart'
  ]
end

dep 'branch name' do
  
end

dep 'repo clean' do
  met? { GitRepo.new('.').clean? }
end

dep 'branch exists' do
  met? { GitRepo.new('.').branches.include? var(:branch) }
  meet { GitRepo.new('.').branch! var(:branch) }
end

dep 'branch checked out' do
  met? { GitRepo.new('.').current_branch == var(:branch) }
  meet { GitRepo.new('.').checkout! var(:branch) }
end

dep 'HEAD up to date' do
  met? { GitRepo.new('.').current_head == var(:new_id) }
  meet { GitRepo.new('.').reset_hard! var(:new_id) }
end

dep 'submodules up to date.task' do
  run {
    shell "git submodule update --init"
  }
end

dep 'cached JS and CSS removed' do
  meet {
    shell "rm -f public/javascripts/all.js"
    shell "rm -f public/stylesheets/all.css"
  }
end

dep 'app flagged for restart.task' do
  before { shell 'mkdir -p tmp' }
  run { shell 'touch tmp/restart.txt' }
end
