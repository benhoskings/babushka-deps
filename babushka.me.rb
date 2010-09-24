meta :bab_tarball do
  template {
    helper :uri do
      'git://github.com/benhoskings/babushka.git'
    end
    helper :latest do
      var(:tarball_path) / 'LATEST'
    end
    helper :tarball_for do |commit_id|
      var(:tarball_path) / "babushka-#{commit_id}.tgz"
    end
    helper :current_head do
      in_build_dir 'babushka' do
        `git rev-parse --short HEAD`.strip
      end
    end
  }
end

dep 'babushka tarball' do
  requires 'linked.bab_tarball', 'LATEST.bab_tarball'
  setup {
    set :tarball_path, './public/tarballs'.p
  }
end

dep 'LATEST.bab_tarball' do
  met? {
    latest.exists? && (latest.read.strip == current_head)
  }
  meet {
    shell "echo #{current_head} > '#{latest}'"
  }
end

dep 'linked.bab_tarball' do
  requires 'exists.bab_tarball'
  setup {
    git uri, :dir => 'babushka'
  }
  met? {
    (var(:tarball_path) / 'babushka.tgz').readlink == tarball_for(current_head)
  }
  meet {
    in_dir var(:tarball_path), :create => true do
      shell "ln -sf #{tarball_for(current_head)} babushka.tgz"
    end
  }
end

dep 'exists.bab_tarball' do
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

dep 'babushka.me db dump' do
  helper :db_dump_path do
    './public/db'.p
  end
  helper :db_dump do
    db_dump_path / 'babushka.me.psql'
  end
  met? {
    db_dump.exists? && (db_dump.mtime + 10 > Time.now) # less than 1 hour old
  }
  before { db_dump_path.mkdir }
  meet {
    shell "pg_dump babushka.me > '#{db_dump}.tmp' && mv '#{db_dump}.tmp' '#{db_dump}'"
  }
end
