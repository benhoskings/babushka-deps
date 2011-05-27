meta :push do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def remote_location remote_name
    shell("git config remote.#{remote_name}.url").split(':', 2)
  end
  def remote_head remote_name
    host, path = remote_location(remote_name)
    shell "ssh #{host} 'cd #{path} && git rev-parse --short HEAD 2>/dev/null'"
  end
end

dep 'push!' do
  define_var :ref, :message => "What would you like to push?", :default => 'HEAD'
  requires [
    'ready.push',
    'before push',
    'pushed.push',
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
      raise UnmeetableDep, "The repo is currently #{state}."
    else
      log_ok "The repo is clean."
    end
  }
end

dep 'pushed.push' do
  define_var :remote,
    :message => "Where would you like to push to?",
    :default => 'production',
    :choices => repo.repo_shell('git remote').split("\n")
  requires [
    'on origin.push',
    'ok to update.push'
  ]
  met? {
    @remote_head = remote_head(var(:remote))
    (@remote_head == shell("git rev-parse --short #{var(:ref)} 2>/dev/null")).tap {|result|
      log "#{var(:remote)} is on #{@remote_head}.", :as => (:ok if result)
    }
  }
  meet {
    log shell("git log --graph --pretty=format:'%Cblue%h%d%Creset %ad %Cgreen%an%Creset %s' #{@remote_head}..#{var(:ref)}")
    confirm "OK to push to #{var(:remote)} (#{repo.repo_shell("git config remote.#{var(:remote)}.url")})?" do
      push_cmd = "git push #{var(:remote)} #{var(:ref)}:babs -f"
      log push_cmd.colorize("on red") do
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'ok to update.push' do
  met? {
    remote_head = remote_head(var(:remote))
    (shell("git merge-base #{var(:ref)} #{remote_head}")[0...7] == remote_head) or
    confirm("Pushing #{var(:ref)} to #{var(:remote)} would not fast forward (#{var(:remote)} is on #{remote_head}). That OK?")
  }
end

dep 'on origin.push' do
  requires Dep('remote exists.push').with('origin')
  met? {
    shell("git branch -r --contains #{var(:ref)}").split("\n").map(&:strip).include? "origin/#{repo.current_branch}"
  }
  meet {
    confirm("#{var(:ref)} isn't pushed to origin/#{repo.current_branch} yet. Do that now?") do
      shell("git push origin #{repo.current_branch}")
    end
  }
end

dep 'remote exists.push' do |remote|
  met? {
    repo.repo_shell("git config remote.#{remote}.url") or log_error("The #{remote} remote isn't configured.")
  }
end
