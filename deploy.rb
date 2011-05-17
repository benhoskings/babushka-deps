dep 'ready for update.repo' do
  requires [
    'valid git_ref_data.repo',
    'clean.repo'
  ]
end

dep 'up to date.repo' do
  setup {
    set :rails_root, var(:repo_path)
    set :rails_env, 'production'
    set :username, shell('whoami')
  }
  requires [
    'ref info extracted.repo',
    'branch exists.repo',
    'branch checked out.repo',
    'HEAD up to date.repo',
    'app bundled',

    # This and the 'maintenace' one below are separate so the 'current dir'
    # deps load lazily from the new code checked out by 'HEAD up to date.repo'.
    'on deploy, live',
    'maintenance page up',
    'on deploy, maintenance',

    'app flagged for restart.task',
    'untracked styles & scripts removed',
    'maintenance page down'
  ]
end

# These are looked up with Dep() so they're just skipped if they don't exist.
dep 'on deploy, live' do
  requires Dep('current dir:on deploy, live')
end
dep 'on deploy, maintenance' do
  requires Dep('current dir:on deploy, maintenance')
end

dep 'ref info extracted.repo' do
  requires 'valid git_ref_data.repo'
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

dep 'valid git_ref_data.repo' do
  met? {
    var(:git_ref_data)[ref_data_regexp] ||
      raise(UnmeetableDep, "Invalid value '#{var(:git_ref_data)}' for :git_ref_data.")
  }
end

dep 'clean.repo' do
  setup {
    # Clear git's internal cache, which sometimes says the repo is dirty when it isn't.
    repo.repo_shell "git diff"
  }
  met? { repo.clean? || raise(UnmeetableDep, "The remote repo has local changes.") }
end

dep 'branch exists.repo' do
  met? { repo.branches.include? var(:branch) }
  meet {
    log_block "Creating #{var(:branch)}" do
      repo.branch! var(:branch)
    end
  }
end

dep 'branch checked out.repo' do
  met? { repo.current_branch == var(:branch) }
  meet {
    log_block "Checking out #{var(:branch)}" do
      repo.checkout! var(:branch)
    end
  }
end

dep 'HEAD up to date.repo' do
  met? { repo.current_full_head == var(:new_id) && repo.clean? }
  meet {
    log_block "Updating #{var(:branch)}: #{var(:old_id)[0...7]}..#{var(:new_id)[0...7]}" do
      repo.reset_hard! var(:new_id)
    end
  }
end

dep 'untracked styles & scripts removed' do
  def to_remove
    shell(
      "git clean -dxn -- public/*style*/* public/*script*/*"
    ).split("\n").collapse(/^Would remove /).select {|path|
      path.p.exists?
    }
  end
  met? { to_remove.empty? }
  meet { to_remove.each {|path| log_shell "Removing #{path}", "rm '#{path}'" } }
end

dep 'app flagged for restart.task' do
  before { shell 'mkdir -p tmp' }
  run { shell 'touch tmp/restart.txt' }
end

dep 'maintenance page up' do
  met? {
    !'public/system/maintenance.html.off'.p.exists? or
    'public/system/maintenance.html'.p.exists?
  }
  meet { 'public/system/maintenance.html.off'.p.copy 'public/system/maintenance.html' }
end

dep 'maintenance page down' do
  met? { !'public/system/maintenance.html'.p.exists? }
  meet { 'public/system/maintenance.html'.p.rm }
end
