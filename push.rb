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
  def self.uncache_remote_head!
    @remote_head = nil
  end
  def git_log from, to
    if from[/^0+$/]
      log "Starting HEAD at #{to[0...7]} (a #{shell("git rev-list #{to} | wc -l").strip}-commit history) since the repo is blank."
    else
      log shell("git log --graph --pretty='format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset' #{from}..#{to}")
    end
  end
end

dep 'push!', :ref, :remote, :env do
  ref.ask("What would you like to push?").default('HEAD')
  env.default!(remote)

  requires 'ready.push'
  requires 'current dir:before push'.with(ref, remote, env) if Dep('current dir:before push')
  requires 'pushed.push'.with(ref, remote)
  requires 'schema up to date.push'.with(ref, remote, env)
  requires 'marked on newrelic.task'.with(ref, env)
  requires 'marked on airbrake.task'.with(ref, env)
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
    confirm "OK to push to #{remote} (#{repo.repo_shell("git config remote.#{remote}.url")})?" do
      push_cmd = "git push #{remote} #{ref}:master -f"
      log push_cmd.colorize("on grey") do
        self.class.uncache_remote_head!
        shell push_cmd, :log => true
      end
    end
  }
end

dep 'schema up to date.push', :ref, :remote, :env do
  def db_name
    'config/database.yml'.p.yaml[env.to_s]['database']
  end
  def dump_schema_cmd
    pg_dump = "pg_dump #{db_name} --no-privileges --no-owner"
    # Dump the schema, and then the schema_migrations table including its contents.
    "#{pg_dump} --schema-only -T schema_migrations && #{pg_dump} -t schema_migrations"
  end
  def fetch_schema
    shell "ssh #{remote_host} '#{dump_schema_cmd}' > db/schema.sql.tmp"
  end
  def move_schema_into_place
    shell "mv db/schema.sql.tmp db/schema.sql"
  end
  setup {
    # We fetch to a temporary file first and move it into place on ssh
    # success, because a failed connection can result in an empty file.
    fetch_schema and move_schema_into_place
  }
  met? {
    Babushka::GitRepo.new('.').clean?
  }
  meet {
    shell "git add db/schema.sql && git commit db/schema.sql -m 'Update DB schema after deploying #{shell("git rev-parse --short #{ref}")}.'"
  }
end

dep 'marked on newrelic.task', :ref, :env do
  requires 'app bundled'.with('.', 'development')
  run {
    if 'config/newrelic.yml'.p.exists?
      shell "bundle exec newrelic deployments -e #{env} -r #{shell("git rev-parse --short #{ref}")}"
    end
  }
end

dep 'marked on airbrake.task', :ref, :env do
  requires 'app bundled'.with('.', 'development')
  run {
    if 'config/initializers/airbrake.rb'.p.exists?
      shell "bundle exec rake airbrake:deploy TO=#{env} REVISION=#{shell("git rev-parse --short #{ref}")} REPO=#{shell("git config remote.origin.url")} USER=#{shell('whoami')}"
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
