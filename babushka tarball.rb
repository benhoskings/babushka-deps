meta :bab_tarball do
  template {
    helper :uri do
      'git://github.com/benhoskings/babushka.git'
    end
    helper :prefix do
      '~/current/public/tarballs'.p
    end
    helper :latest do
      prefix / 'LATEST'
    end
    helper :tarball_for do |commit_id|
      prefix / "babushka-#{commit_id}.tgz"
    end
    helper :current_head do
      in_build_dir 'babushka' do
        `git rev-parse --short HEAD`.strip
      end
    end
  }
end

bab_tarball 'babushka tarball' do
  requires 'babushka tarball linked', 'babushka tarball LATEST'
  setup { git uri, :dir => 'babushka' }
end

bab_tarball 'babushka tarball LATEST' do
  met? {
    latest.exists? && (latest.read.strip == current_head)
  }
  meet {
    shell "echo #{current_head} > '#{latest}'"
  }
end

bab_tarball 'babushka tarball linked' do
  requires 'babushka tarball exists'
  met? {
    (prefix / 'babushka.tgz').readlink == tarball_for(current_head)
  }
  meet {
    in_dir prefix, :create => true do
      shell "ln -sf #{tarball_for(current_head)} babushka.tgz"
    end
  }
end

bab_tarball 'babushka tarball exists' do
  met? {
    shell "tar -t -f #{tarball_for(current_head)}"
  }
  before { shell "mkdir -p #{tarball_for(current_head).parent}" }
  meet {
    in_build_dir do
      shell "tar -zcv --exclude .git -f '#{tarball_for(current_head)}' babushka/"
    end
  }
end
