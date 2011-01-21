meta :task do
  accepts_block_for :run
  template {
    met? { @run }
    meet { call_task(:run).tap { @run = true } }
  }
end
