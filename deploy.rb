# coding: utf-8

dep 'ready for update.repo' do
  requires [
    'valid git_ref_data.repo',
    'clean.repo'
  ]
end

dep 'up to date.repo' do
  setup {
    set :app_root, var(:repo_path)
    set :app_env, 'production'
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
    'on deploy',

    'app flagged for restart.task',
    '☕',
    'scss built',
    'untracked css removed',
    'maintenance page down',
    'after deploy'
  ]
end

# These are looked up with Dep() so they're just skipped if they don't exist.
dep 'on deploy' do
  requires Dep('current dir:on deploy')
end
dep 'after deploy' do
  requires Dep('current dir:after deploy')
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
  met? {
    (repo.current_full_head == var(:new_id) && repo.clean?).tap {|result|
      if result
        log_ok "#{var(:branch)} is up to date at #{repo.current_head}."
      else
        log "#{var(:branch)} needs updating: #{var(:old_id)[0...7]}..#{var(:new_id)[0...7]}"
      end
    }
  }
  meet {
    log shell("git diff --stat #{var(:old_id)}..#{var(:new_id)}")
    repo.reset_hard! var(:new_id)
  }
end

dep '☕' do
  def to_brew
    Dir.glob("app/coffeescripts/**/*.coffee").reject {|coffee|
      js = coffee.sub(/^app\/coffeescripts\//, 'public/javascripts/').sub(/\.coffee$/, '.js')
      File.exists?(js) && File.mtime(js) > File.mtime(coffee)
    }
  end
  met? {
    (count = to_brew.length).zero?.tap {|result|
      log result ? "☕ Mmmm!" : "Found #{count} unbrewed coffee#{'s' unless count == 1}."
    }
  }
  meet {
    log_shell "Brewing", "coffee --compile --output public/javascripts #{to_brew.map {|c| "'#{c}'" }.join(' ')}"
  }
end

dep 'scss built' do
  def missing_css
    Dir.glob("app/stylesheets/**/*.scss").reject {|scss|
      scss[/\/_[^\/]+\.scss$/] # Don't try to build _partials.scss
    }.reject {|scss|
      css = scss.sub(/^app\//, 'public/').sub(/\.scss$/, '.css')
      File.exists?(css) && File.mtime(css) > File.mtime(scss)
    }
  end
  met? {
    if !missing_css.empty?
      log "There #{missing_css.length == 1 ? 'is' : 'are'} #{missing_css.length} scss file#{'s' unless missing_css.length == 1} to rebuild."
    elsif !shell("grep -ri 'syntax error' public/stylesheets/") {|s| s.stdout.empty? }
      log "There are syntax errors in the scss."
    else
      log_ok "The scss is built."
    end
  }
  meet {
    shell "bundle exec sass --update app/stylesheets:public/stylesheets" do |shell|
      log_error shell.stdout.split("\n").grep(/error/).map(&:strip).join("\n") unless shell.ok?
    end
  }
end

dep 'untracked css removed' do
  def untracked_css
    Dir.glob("public/stylesheets/**/*.css").reject {|css|
      File.exists? css.sub(/^public\//, 'app/').sub(/\.css$/, '.scss')
    }
  end
  met? {
    untracked_css.empty?
  }
  meet {
    log_shell "Removing", "rm -f #{untracked_css.map {|f| "'#{f}'" }.join(' ')}"
  }
end


dep 'untracked styles & scripts removed' do
  def to_remove
    shell(
      "git clean -dxn -- public/*style* public/*script*"
    ).split("\n").collapse(/^Would remove /).select {|path|
      path.p.exists?
    }
  end
  met? { to_remove.empty? }
  meet { to_remove.each {|path| log_shell "Removing #{path}", "rm -rf '#{path}'" } }
end

dep 'app flagged for restart.task' do
  run {
    if File.exists? 'tmp/pids/unicorn.pid'
      shell "kill -USR2 #{'tmp/pids/unicorn.pid'.p.read}"
    else
      shell "mkdir -p tmp && touch tmp/restart.txt"
    end
  }
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
