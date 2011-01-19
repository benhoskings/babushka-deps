dep 'deploy repo up to date' do
  setup {
    # Should look like this:
    # 83a90415670ec7ae4690d58563be628c73900716 e817f54d3e9a2d982b16328f8d7f0fbfcd7433f7 refs/heads/master
    old_id, new_id, branch = var(:git_ref_data).scan(
      /^([\da-f]{40}) ([\da-f]{40}) refs\/heads\/(.+)$/
    ).flatten
    if [old_id, new_id, branch].any?(&:nil?)
      raise UnmeetableDep, "Invalid value '#{var(:git_ref_data)}' for :git_ref_data."
    end
  }
  requires [
    'branch name',
    'clean.repo',
    'branch exists.repo',
    'branch checked out.repo',
    'HEAD up to date.repo',
    'submodules up to date.task',
    'cached JS and CSS removed',
    'app bundled',
    'app flagged for restart.task'
  ]
end

dep 'branch name' do
  
end

meta :repo do
  def repo
    @repo ||= Babushka::GitRepo.new(var(:repo_path))
  end
end

dep 'clean.repo' do
  met? { repo.clean? }
end

dep 'branch exists.repo' do
  met? { repo.branches.include? var(:branch) }
  meet { repo.branch! var(:branch) }
end

dep 'branch checked out.repo' do
  met? { repo.current_branch == var(:branch) }
  meet { repo.checkout! var(:branch) }
end

dep 'HEAD up to date.repo' do
  met? { repo.current_head == var(:new_id) }
  meet { repo.reset_hard! var(:new_id) }
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
