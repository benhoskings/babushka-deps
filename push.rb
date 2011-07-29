meta :push do
  def repo
    @repo ||= Babushka::GitRepo.new('.')
  end
  def self.remote_location
    shell("git config remote.#{var(:remote)}.url").split(':', 2)
  end
  def self.remote_head
    host, path = remote_location
    @remote_head ||= shell("ssh #{host} 'cd #{path} && git rev-parse --short HEAD 2>/dev/null'") || ''
  end
  def remote_head
    self.class.remote_head
  end
  def self.uncache_remote_head!
    @remote_head = nil
  end
  def git_log from, to
    log shell("git log --graph --pretty=format:'%Cblue%h%d%Creset %ar %Cgreen%an%Creset %s' #{from}..#{to}")
  end
end

dep 'push!' do
  define_var :ref, :message => "What would you like to push?", :default => 'HEAD'
  requires [
    'ready.push',
    'before push',
    'pushed.push',
    'marked on newrelic.task',
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
    (remote_head == shell("git rev-parse --short #{var(:ref)} 2>/dev/null")).tap {|result|
      log "#{var(:remote)} is on #{remote_head}.", :as => (:ok if result)
    }
  }
  meet {
    git_log remote_head, var(:ref)
    confirm "OK to push to #{var(:remote)} (#{repo.repo_shell("git config remote.#{var(:remote)}.url")})?" do
      push_cmd = "git push #{var(:remote)} #{var(:ref)}:master -f"
      log push_cmd.colorize("on grey") do
        self.class.uncache_remote_head!
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'marked on newrelic.task' do
  run {
    if 'config/newrelic.yml'.p.exists?
      shell "bundle exec newrelic deployments -r #{Babushka::GitRepo.new('.').current_head}"
    end
  }
end

dep 'ok to update.push' do
  met? {
    if !repo.repo_shell("git rev-parse #{remote_head}", &:ok?)
      confirm "The current HEAD on #{var(:remote)}, #{remote_head}, isn't present locally. OK to push #{'(This is probably a bad idea)'.colorize('on red')}"
    elsif shell("git merge-base #{var(:ref)} #{remote_head}", &:stdout)[0...7] != remote_head
      confirm "Pushing #{var(:ref)} to #{var(:remote)} would not fast forward (#{var(:remote)} is on #{remote_head}). That OK?"
    else
      true
    end
  }
end

dep 'on origin.push' do
  requires Dep('remote exists.push', :from => dependency.dep_source).with('origin')
  met? {
    shell("git branch -r --contains #{var(:ref)}").split("\n").map(&:strip).include? "origin/#{repo.current_branch}"
  }
  meet {
    git_log "origin/#{repo.current_branch}", var(:ref)
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
