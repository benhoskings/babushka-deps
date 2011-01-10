meta :bab_tarball do
  def uri
    'git://github.com/benhoskings/babushka.git'
  end
  def latest
    var(:tarball_path) / 'LATEST'
  end
  def repo
    GitRepo.new(Babushka::BuildPrefix / 'babushka')
  end
  def tarball
    var(:tarball_path) / "babushka-#{repo.current_head}.tgz"
  end
end

dep 'babushka tarball' do
  requires 'linked.bab_tarball', 'LATEST.bab_tarball'
  setup {
    set :tarball_path, './public/tarballs'.p
  }
end

dep 'LATEST.bab_tarball' do
  met? {
    latest.exists? && (latest.read.strip == repo.current_head)
  }
  meet {
    shell "echo #{repo.current_head} > '#{latest}'"
  }
end

dep 'linked.bab_tarball' do
  requires 'exists.bab_tarball'
  setup {
    git uri, :path => 'babushka'
  }
  met? {
    (var(:tarball_path) / 'babushka.tgz').readlink == tarball
  }
  meet {
    shell "ln -sf #{tarball} babushka.tgz", :dir => var(:tarball_path), :create => true
  }
end

dep 'exists.bab_tarball' do
  met? {
    shell "tar -t -f #{tarball}"
  }
  before { shell "mkdir -p #{tarball.parent}" }
  meet {
    shell "tar -zcv --exclude .git -f '#{tarball}' babushka/", :dir => Babushka::BuildPrefix
  }
end

dep 'babushka.me db dump' do
  def db_dump_path
    './public/db'.p
  end
  def db_dump
    db_dump_path / 'babushka.me.psql'
  end
  met? {
    db_dump.exists? && (db_dump.mtime + 300 > Time.now) # less than 5 minutes old
  }
  before { db_dump_path.mkdir }
  meet {
    shell "pg_dump babushka.me > '#{db_dump}.tmp' && mv '#{db_dump}.tmp' '#{db_dump}'"
  }
end
