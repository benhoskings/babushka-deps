dep 'existing db' do
  setup {
    requires "existing #{var(:db, :default => 'postgres')} db"
  }
end

dep 'db gem' do
  setup {
    requires var(:db) == 'postgres' ? 'pg.gem' : "#{var(:db)}.gem"
  }
end
