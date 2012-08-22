dep 'ready for update.repo', :git_ref_data, :env do
  env.default!(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')
  requires [
    'valid git_ref_data.repo'.with(git_ref_data),
    'clean.repo',
    'before deploy'.with(ref_info[:old_id], ref_info[:new_id], ref_info[:branch], env)
  ]
end

dep 'up to date.repo', :git_ref_data, :env do
  env.default!(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')
  requires [
    'on correct branch.repo'.with(ref_info[:branch]),
    'HEAD up to date.repo'.with(ref_info),
    'app bundled'.with(:root => '.', :env => env),

    # This and 'after deploy' below are separated so the deps in 'current dir'
    # they refer to load from the new code checked out by 'HEAD up to date.repo'.
    # Normally it would be fine because dep loading is lazy, but the "if Dep('...')"
    # checks trigger a source load when called.
    'on deploy'.with(ref_info[:old_id], ref_info[:new_id], ref_info[:branch], env),

    'unicorn restarted',
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
    git_ref_data[ref_data_regexp] || unmeetable!("Invalid git_ref_data '#{git_ref_data}'.")
  }
end

dep 'clean.repo' do
  setup {
    # Clear git's internal cache, which sometimes says the repo is dirty when it isn't.
    repo.repo_shell "git diff"
  }
  met? { repo.clean? || unmeetable!("The remote repo has local changes.") }
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

dep 'unicorn restarted', :pidfile, :old_pidfile do
  pidfile.default!('tmp/pids/unicorn.pid')
  old_pidfile.default!("#{pidfile}.oldbin")
  def running? pid
    if pid.nil?
      false
    else
      Process.getpgid(pid.to_i)
    end
  rescue Errno::ESRCH
    false
  end
  def wait_for timeout, message, &block
    waited_for, result = 0, nil
    log_block message do
      while !(result = yield) && (waited_for < timeout)
        waited_for += 0.2
        sleep 0.2
      end
      result
    end
  end
  setup {
    @original_pid = pidfile.p.read.try(:chomp)
  }
  def restarted?(current_pid)
    # The app has restarted if:
    !old_pidfile.p.exists? && # A restart isn't in progress,
    running?(current_pid) && # The current pid is running,
    (current_pid != @original_pid) # And the value has changed.
  end
  met? {
    current_pid = pidfile.p.read.try(:chomp)
    if !running?(current_pid)
      if @attempted_restart
        log_error "Unicorn exited! (Possible cause: no free RAM on host.)"
      else
        log "There are no unicorns running: not attempting a restart."
        true
      end
    else
      restarted?(current_pid).tap {|result|
        if !@attempted_restart
          log "The unicorn master is running with pid #{current_pid}."
        elsif !result
          log_warn "The new unicorn failed to start. (The old one is still running, though.)"
        else
          log_ok "Restarted OK (pid #{@original_pid} -> #{pidfile.p.read.try(:chomp)})."
        end
      }
    end
  }
  meet {
    shell "kill -USR2 #{'tmp/pids/unicorn.pid'.p.read.try(:chomp)}"
    @attempted_restart = true
    # 1) The current pidfile is moved to old_pidfile.
    # 2) The new master starts and writes pidfile.
    # 3) On launch success, old_pidfile is deleted; on failure,
    #    old_pidfile is moved back into place.
    wait_for(10, "Current unicorn moving aside") { pidfile.p.exists? && old_pidfile.p.exists? }
    wait_for(10, "New unicorn forking") { pidfile.p.exists? }
    wait_for(120, "New unicorn booting") { !old_pidfile.p.exists? }
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

dep 'when path changed', :path, :dep_spec, :old_id, :new_id, :env do
  def effective_old_id
    # If there is no initial commit (first push or branch change), git
    # replace git's '0000000' with a parentless commit (usually there's
    # just one, the initial repo commit).
    old_id[/^0+$/] ? shell('git rev-list HEAD | tail -n1') : old_id
  end
  def pending
    shell(
      "git diff --numstat #{effective_old_id}..#{new_id}"
    ).split("\n").grep(
      /^[\d\s\-]+#{path}/
    )
  end
  setup {
    if pending.empty?
      log "No changes within #{path.inspect} - not running '#{dep_spec}'."
    else
      log "#{pending.length} change#{'s' unless pending.length == 1} within #{path.inspect}:"
      if pending.length < 30
        pending.each {|p| log p }
      else
        pending[0...15].each {|p| log p }
        log "[and #{pending.length - 15} more]"
      end

      requires dep_spec.to_s.with(:env => env, :deploying => 'yes')
    end
  }
end

dep 'assets precompiled', :env, :deploying, :template => 'task' do
  run {
    shell "bundle exec rake assets:precompile:primary RAILS_GROUPS=assets RAILS_ENV=#{env}"
  }
end

dep 'delayed job restarted', :template => 'task' do
  run {
    output = shell?('ps ux | grep -v grep | grep "rake jobs:work"')

    if output.nil?
      log "`rake jobs:work` isn't running."
      true
    else
      pid = output.scan(/^\w+\s+(\d+)\s+/).flatten.first
      log_shell "Sending SIGTERM to #{pid}", "kill -s TERM #{pid}"
    end
  }
end
