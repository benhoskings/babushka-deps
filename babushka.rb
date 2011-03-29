dep 'babushka caches removed' do
  def paths
    %w[
      ~/.babushka/downloads/*
      ~/.babushka/build/*
    ]
  end
  def to_remove
    paths.reject {|p|
      Dir[p.p].empty?
    }
  end
  met? {
    to_remove.empty?
  }
  meet {
    to_remove.each {|path|
      shell %Q{rm -rf #{path}}
    }
  }
end
