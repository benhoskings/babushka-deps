meta :deploy_repo do
  def repo
    @repo ||= Babushka::GitRepo.new(var(:repo_path))
  end
  def ref_data_regexp
    # For example:
    # 83a90415670ec7ae4690d58563be628c73900716 e817f54d3e9a2d982b16328f8d7f0fbfcd7433f7 refs/heads/master
    /\A([\da-f]{40}) ([\da-f]{40}) refs\/heads\/(.+)\z/
  end
end

dep 'ready for update.deploy_repo' do
  requires [
    'valid git_ref_data.deploy_repo',
    'clean.deploy_repo'
  ]
end

dep 'up to date.deploy_repo' do
  setup {
    set :rails_root, var(:repo_path)
    set :rails_env, 'production'
    set :username, shell('whoami')

    requires Dep('current dir:deployed') # app-specific deps
  }
  requires [
    'ref info extracted.deploy_repo',
    'branch exists.deploy_repo',
    'branch checked out.deploy_repo',
    'HEAD up to date.deploy_repo',
    'submodules up to date.task',
    'cached JS and CSS removed',
    'app bundled',
    'app flagged for restart.task'
  ]
end

dep 'ref info extracted.deploy_repo' do
  requires 'valid git_ref_data.deploy_repo'
  met? {
    %w[old_id new_id branch].all? {|name|
      !Babushka::Base.task.vars.vars[name][:value].nil?
    }
  }
  meet {
    old_id, new_id, branch = var(:git_ref_data).scan(ref_data_regexp).flatten
    set :old_id, old_id
    set :new_id, new_id
    set :branch, branch
  }
end

dep 'valid git_ref_data.deploy_repo' do
  met? {
    var(:git_ref_data)[ref_data_regexp] ||
      raise(UnmeetableDep, "Invalid value '#{var(:git_ref_data)}' for :git_ref_data.")
  }
end

dep 'clean.deploy_repo' do
  met? { repo.clean? || raise(UnmeetableDep, "The remote repo has local changes.") }
end

dep 'branch exists.deploy_repo' do
  met? { repo.branches.include? var(:branch) }
  meet { repo.branch! var(:branch) }
end

dep 'branch checked out.deploy_repo' do
  met? { repo.current_branch == var(:branch) }
  meet { repo.checkout! var(:branch) }
end

dep 'HEAD up to date.deploy_repo' do
  met? { repo.current_full_head == var(:new_id) && repo.clean? }
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
