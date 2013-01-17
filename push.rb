meta :push do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def self.remote_host_and_path remote
    @remote_host_and_path ||= shell("git config remote.#{remote}.url").split(':', 2)
  end
  def self.remote_head remote
    host, path = remote_host_and_path(remote)
    @remote_head ||= shell!("ssh #{host} 'cd #{path} && git rev-parse --short HEAD 2>/dev/null || echo 0000000'")
  end
  def remote_host; self.class.remote_host_and_path(remote).first end
  def remote_path; self.class.remote_host_and_path(remote).last end
  def remote_head; self.class.remote_head(remote) end
  def self.uncache!
    @remote_head = nil
    @remote_host_and_path = nil
  end
  def git_log from, to
    if from[/^0+$/]
      log "Starting #{remote} at #{to[0...7]} (a #{shell("git rev-list #{to} | wc -l").strip}-commit history) since the repo is blank."
    else
      log shell("git log --graph --date-order --pretty='format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset' #{from}..#{to}")
    end
  end
end

dep 'push!', :ref, :remote, :env do
  ref.ask("What would you like to push?").default('HEAD')
  env.default!(remote)

  requires 'ready.push'
  requires 'current dir:before push'.with(ref, remote, env) if Dep('current dir:before push')
  requires 'pushed.push'.with(ref, remote)
  requires 'current dir:after push'.with(ref, remote, env) if Dep('current dir:after push')
end

dep 'ready.push' do
  met? {
    state = [:dirty, :rebasing, :merging, :applying, :bisecting].detect {|s| repo.send("#{s}?") }
    if !state.nil?
      unmeetable! "The repo is #{state}."
    else
      log_ok "The repo is clean."
    end
  }
end

dep 'pushed.push', :ref, :remote do
  self.class.uncache!
  ref.ask("What would you like to push?").default('HEAD')
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
    confirm "OK to push #{ref} to #{remote} (#{repo.repo_shell("git config remote.#{remote}.url")})?" do
      push_cmd = "git push #{remote} #{ref}:master -f"
      log push_cmd.colorize("on grey") do
        self.class.uncache!
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'ok to update.push', :ref, :remote do
  met? {
    if remote_head[/^0+$/]
      log_ok "The remote repo is empty."
    elsif !repo.repo_shell("git rev-parse #{remote_head}", &:ok?)
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
