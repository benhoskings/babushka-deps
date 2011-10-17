dep 'seeded db', :username, :db_name, :db do
  requires "existing db".with(username, db_name, db)
  met? {
    rows = shell("psql #{db_name} -c '\\d'").scan(/\((\d+) rows?\)/).flatten.first
    (rows && rows.to_i > 0).tap {|result|
      log "The DB looks seeded - there are #{rows} tables present."
    }
  }
  meet {
    shell "bundle exec rake db:seed --trace RAILS_ENV=#{env}", :cd => root, :log => true
  }
end

dep 'existing db', :username, :db_name, :db do
  requires "existing #{db} db".with(username, db_name)
end

dep 'db gem', :db do
  db.choose(%w[postgres mysql])
  requires db == 'postgres' ? 'pg.gem' : "#{db}.gem"
end

dep 'deployed migrations run', :old_id, :new_id, :env do
  setup {
    # If the branch was changed, git supplies 0000000 for old_id,
    # so the commit range is 'everything'.
    effective_old_id = old_id[/^0+$/] ? '' : old_id
    pending = shell("git diff --numstat #{effective_old_id}..#{new_id}").split("\n").grep(/^[\d\s]+db\/migrate\//)
    if pending.empty?
      log "No new migrations."
    else
      log "#{pending.length} migration#{'s' unless pending.length == 1} to run:"
      pending.each {|p| log p }

      requires 'maintenance page up'
      requires 'migrated db'.with(shell('whoami'), '.', env, 'yes', 'no')
    end
  }
end
