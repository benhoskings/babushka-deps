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

dep 'deploy!' do
  define_var :ref, :message => "What would you like to deploy?", :default => 'HEAD'
  define_var :production, :message => "What's your production remote called?", :default => 'production'
  requires [
    'ready.push',
    'on production.push'
  ]
end

dep 'ready.push' do
  met? {
    !(
      repo.dirty? # or repo.merging?  or repo.rebasing? or repo.applying? or repo.bisecting?
    )
  }
end

dep 'on production.push' do
  requires [
    'on origin.push',
    'ok to update production.push'
  ]
  met? {
    @production_head = remote_head(var(:production))
    (@production_head[0...7] == shell("git rev-parse --short #{var(:ref)} 2>/dev/null")).tap {|result|
      log "#{var(:production)} is on #{@production_head[0...7]}.", :as => (:ok if result)
    }
  }
  meet {
    log shell("git log --graph --pretty=format:'%Cblue%h%d%Creset %ad %Cgreen%an%Creset %s' #{@production_head}..#{var(:ref)}")
    confirm "OK to push?" do
      push_cmd = "git push #{var(:production)} #{var(:ref)}:babs -f"
      log push_cmd.colorize("on red") do
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'ok to update production.push' do
  met? {
    production_head = remote_head(var(:production))
    (shell("git merge-base #{var(:ref)} #{production_head}")[0...7] == production_head) or
    confirm("Pushing #{var(:ref)} to #{var(:production)} would not fast forward (#{var(:production)} is on #{production_head[0...7]}). That OK?")
  }
end

dep 'on origin.push' do
  requires [
  ]
  met? {
    shell("git branch -r --contains #{var(:ref)}").split("\n").map(&:strip).include? "origin/#{repo.current_branch}"
  }
  meet {
    confirm("#{var(:ref)} isn't pushed to origin/#{repo.current_branch} yet. Do that now?") do
      shell("git push origin #{repo.current_branch}")
    end
  }
end
