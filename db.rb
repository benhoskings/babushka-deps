dep 'existing db', :username, :db_name do
  setup {
    requires "existing #{var(:db, :default => 'postgres')} db".with(username, db_name)
  }
end

dep 'db gem' do
  setup {
    define_var :db, :choices => %w[postgres mysql]
    requires var(:db) == 'postgres' ? 'pg.gem' : "#{var(:db)}.gem"
  }
end

dep 'activerecord db migrated' do
  requires_when_unmet 'benhoskings:maintenance page up'
  met? {
    if @run
      true # done
    else
      # If the branch was changed, git supplies 0000000 for var(:old_id), so
      # it looks the commit range is 'everything'.
      old_id = var(:old_id)[/^0+$/] ? '' : var(:old_id)
      pending = shell("git diff --numstat #{old_id}..#{var(:new_id)}").split("\n").grep(/^[\d\s]+db\/migrate\//)
      if pending.empty?
        log "No new migrations."
        true
      else
        log "#{pending.length} migration#{'s' unless pending.length == 1} to run:"
        pending.each {|p| log p }
        false
      end
    end
  }
  meet {
    shell 'bundle exec rake db:migrate --trace RAILS_ENV=production', :log => true
    @run = true
  }
end
