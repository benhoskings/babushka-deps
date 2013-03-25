meta :task do
  accepts_block_for :run
  template {
    deprecated! "2013-09-25", :method_name => "The 'benhoskings:task' template", :callpoint => false, :instead => "the core 'task' template"
    met? { @run }
    meet { invoke(:run).tap {|result| @run = result } }
  }
end
