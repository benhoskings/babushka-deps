# coding: utf-8

dep 'ready for update.repo', :git_ref_data do
  requires [
    'valid git_ref_data.repo'.with(git_ref_data),
    'clean.repo',
    'before deploy'.with(ref_info[:old_id], ref_info[:new_id], ref_info[:branch], env)
  ]
end

dep 'up to date.repo', :git_ref_data, :env do
  env.default!(ENV['RAILS_ENV'] || 'production')
  requires [
    'on correct branch.repo'.with(ref_info[:branch]),
    'HEAD up to date.repo'.with(ref_info),
    'app bundled'.with(:root => '.', :env => env),

    # This and 'after deploy' below are separated so the deps in 'current dir'
    # they refer to load from the new code checked out by 'HEAD up to date.repo'.
    # Normally it would be fine because dep loading is lazy, but the "if Dep('...')"
    # checks trigger a source load when called.
    'on deploy'.with(ref_info[:old_id], ref_info[:new_id], ref_info[:branch], env),

    'app flagged for restart.task',
    '☕',
    'scss built',
    'maintenance page down',
    'after deploy'.with(ref_info[:old_id], ref_info[:new_id], ref_info[:branch], env)
  ]
end

dep 'before deploy', :old_id, :new_id, :branch, :env do
  requires 'current dir:before deploy'.with(old_id, new_id, branch, env) if Dep('current dir:before deploy')
end
dep 'on deploy', :old_id, :new_id, :branch, :env do
  requires 'current dir:on deploy'.with(old_id, new_id, branch, env) if Dep('current dir:on deploy')
end
dep 'after deploy', :old_id, :new_id, :branch, :env do
  requires 'current dir:after deploy'.with(old_id, new_id, branch, env) if Dep('current dir:after deploy')
end

dep 'valid git_ref_data.repo', :git_ref_data do
  met? {
    git_ref_data[ref_data_regexp] || unmeetable("Invalid git_ref_data '#{git_ref_data}'.")
  }
end

dep 'clean.repo' do
  setup {
    # Clear git's internal cache, which sometimes says the repo is dirty when it isn't.
    repo.repo_shell "git diff"
  }
  met? { repo.clean? || unmeetable("The remote repo has local changes.") }
end

dep 'branch exists.repo', :branch do
  met? {
    repo.branches.include? branch
  }
  meet {
    log_block "Creating #{branch}" do
      repo.branch! branch
    end
  }
end

dep 'on correct branch.repo', :branch do
  requires 'branch exists.repo'.with(branch)
  met? {
    repo.current_branch == branch
  }
  meet {
    log_block "Checking out #{branch}" do
      repo.checkout! branch
    end
  }
end

dep 'HEAD up to date.repo', :old_id, :new_id, :branch do
  met? {
    (repo.current_full_head == new_id && repo.clean?).tap {|result|
      if result
        log_ok "#{branch} is up to date at #{repo.current_head}."
      else
        log "#{branch} needs updating: #{old_id[0...7]}..#{new_id[0...7]}"
      end
    }
  }
  meet {
    if old_id[/^0+$/]
      log "Starting HEAD at #{new_id[0...7]} (a #{shell("git rev-list #{new_id} | wc -l").strip}-commit history) since the repo is blank."
    else
      log shell("git diff --stat #{old_id}..#{new_id}")
    end
    repo.reset_hard! new_id
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

dep 'untracked assets removed' do
  def to_remove
    existing_sources = Dir.glob('app/{stylesheets,coffeescripts}/**/*')
    existing_assets = shell("git clean -xn -- public/*style* public/*script*").split("\n").collapse(/^Would remove /)
    (existing_assets - existing_sources.map {|path|
      path.
        gsub(/\.coffee$/, '.js'). # .coffee is compiled to .js
        gsub(/\.s[ac]ss$/, '.css'). # .sass and .scss are compiled to .css
        gsub(/^app\/coffeescripts\//, 'public/javascripts/'). # the coffee in app/coffeescripts/ ends up in public/javascripts/
        gsub(/^app\//, 'public/') # and everything else is in the same subpath, within public/ instead of app/.
    })
  end
  met? {
    to_remove.empty?
  }
  meet {
    cached_to_remove = to_remove
    log_shell "Removing:\n#{cached_to_remove.join("\n")}", "rm -f #{cached_to_remove.map {|f| "'#{f}'" }.join(' ')}"
  }
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
