meta :push do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def self.remote_head remote
    host, path = shell("git config remote.#{remote}.url").split(':', 2)
    @remote_head ||= shell!("ssh #{host} 'cd #{path} && git rev-parse --short HEAD 2>/dev/null'") || ''
  end
  def remote_head
    self.class.remote_head(remote)
  end
  def self.uncache_remote_head!
    @remote_head = nil
  end
  def git_log from, to
    log shell("git log --graph --pretty=format:'%Cblue%h%d%Creset %ar %Cgreen%an%Creset %s' #{from}..#{to}")
  end
end

dep 'push!', :ref, :remote do
  ref.ask("What would you like to push?").default('HEAD')
  requires [
    'ready.push',
    'before push',
    'pushed.push'.with(ref, remote),
    'marked on newrelic.task'.with(ref),
    'after push'
  ]
end

# These are looked up with Dep() so they're just skipped if they don't exist.
dep 'before push' do
  requires Dep('current dir:before push')
end
dep 'after push' do
  requires Dep('current dir:after push')
end

dep 'ready.push' do
  met? {
    state = [:dirty, :merging, :rebasing, :applying, :bisecting].detect {|s| repo.send("#{s}?") }
    if !state.nil?
      unmeetable "The repo is #{state}."
    else
      log_ok "The repo is clean."
    end
  }
end

dep 'pushed.push', :ref, :remote do
  remote.ask("Where would you like to push to?").choose(repo.repo_shell('git remote').split("\n"))
  requires [
    'on origin.push'.with(ref),
    'ok to update.push'.with(ref, remote)
  ]
  met? {
    (remote_head == shell("git rev-parse --short #{ref} 2>/dev/null")).tap {|result|
      log "#{remote} is on #{remote_head}.", :as => (:ok if result)
    }
  }
  meet {
    git_log remote_head, ref
    confirm "OK to push to #{remote} (#{repo.repo_shell("git config remote.#{remote}.url")})?" do
      push_cmd = "git push #{remote} #{ref}:master -f"
      log push_cmd.colorize("on grey") do
        self.class.uncache_remote_head!
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'marked on newrelic.task', :ref do
  run {
    if 'config/newrelic.yml'.p.exists?
      shell "bundle exec newrelic deployments -r #{shell("git rev-parse --short #{ref}")}"
    end
  }
end

dep 'ok to update.push', :ref, :remote do
  met? {
    if !repo.repo_shell("git rev-parse #{remote_head}", &:ok?)
      confirm "The current HEAD on #{remote}, #{remote_head}, isn't present locally. OK to push #{'(This is probably a bad idea)'.colorize('on red')}"
    elsif shell("git merge-base #{ref} #{remote_head}", &:stdout)[0...7] != remote_head
      confirm "Pushing #{ref} to #{remote} would not fast forward (#{remote} is on #{remote_head}). That OK?"
    else
      true
    end
  }
end

dep 'on origin.push', :ref do
  requires 'remote exists.push'.with('origin')
  met? {
    shell("git branch -r --contains #{ref}").split("\n").map(&:strip).include? "origin/#{repo.current_branch}"
  }
  meet {
    git_log "origin/#{repo.current_branch}", ref
    confirm("#{ref} isn't pushed to origin/#{repo.current_branch} yet. Do that now?") do
      shell("git push origin #{repo.current_branch}")
    end
  }
end

dep 'remote exists.push', :remote do
  met? {
    repo.repo_shell("git config remote.#{remote}.url") or log_error("The #{remote} remote isn't configured.")
  }
end
