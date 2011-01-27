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

    requires Dep('current dir:deployed') # app-specific deps
  }
  requires [
    'ref info extracted.repo',
    'branch exists.repo',
    'branch checked out.repo',
    'HEAD up to date.repo',
    'submodules up to date.task',
    'cached JS and CSS removed',
    'app bundled',
    'app flagged for restart.task'
  ]
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
  met? { repo.clean? || raise(UnmeetableDep, "The remote repo has local changes.") }
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
