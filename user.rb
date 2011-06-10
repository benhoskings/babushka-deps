dep 'passwordless ssh logins' do
  def ssh_dir
    "~#{var(:username)}" / '.ssh'
  end
  def group
    shell "id -gn #{var(:username)}"
  end
  met? {
    sudo "grep '#{var(:your_ssh_public_key)}' '#{ssh_dir / 'authorized_keys'}'"
  }
  before {
    sudo "mkdir -p '#{ssh_dir}'"
    sudo "chmod 700 '#{ssh_dir}'"
  }
  meet {
    append_to_file var(:your_ssh_public_key), (ssh_dir / 'authorized_keys'), :sudo => true
  }
  after {
    sudo "chown -R #{var(:username)}:#{group} '#{ssh_dir}'"
    sudo "chmod 600 #{(ssh_dir / 'authorized_keys')}"
  }
end

dep 'public key installed' do
  def group
    shell "id -gn #{shell('whoami')}"
  end
  met? {
    shell "grep '#{var(:your_ssh_public_key)}' ~/.ssh/authorized_keys"
  }
  before {
    shell "mkdir -p ~/.ssh"
    shell "chmod 700 ~/.ssh"
  }
  meet {
    append_to_file var(:your_ssh_public_key), '~/.ssh/authorized_keys'
  }
  after {
    shell "chown -R #{shell('whoami')}:#{group} ~/.ssh"
    shell "chmod 600 ~/.ssh/authorized_keys"
  }
end

dep 'public key' do
  met? { grep /^ssh-dss/, '~/.ssh/id_dsa.pub' }
  meet { log shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''") }
end

dep 'dot files' do
  requires 'user exists', 'git', 'curl.managed', 'git-smart.gem'
  met? { File.exists?(ENV['HOME'] / ".dot-files/.git") }
  meet { shell %Q{curl -L "http://github.com/#{var :github_user, :default => 'benhoskings'}/#{var :dot_files_repo, :default => 'dot-files'}/raw/master/clone_and_link.sh" | bash} }
end

dep 'user auth setup' do
  requires 'user exists with password', 'passwordless ssh logins'
end

dep 'user exists with password' do
  requires 'user exists'
  on :linux do
    met? { shell('sudo cat /etc/shadow')[/^#{var(:username)}:[^\*!]/] }
    meet {
      sudo "echo -e '#{var(:password)}\n#{var(:password)}' | passwd #{var(:username)}"
    }
  end
end

dep 'user exists' do
  setup {
    define_var :home_dir_base, :default => L{
      var(:username)['.'] ? '/srv/http' : '/home'
    }
  }
  on :osx do
    met? { !shell("dscl . -list /Users").split("\n").grep(var(:username)).empty? }
    meet {
      homedir = var(:home_dir_base) / var(:username)
      {
        'Password' => '*',
        'UniqueID' => (501...1024).detect {|i| (Etc.getpwuid i rescue nil).nil? },
        'PrimaryGroupID' => 'admin',
        'RealName' => var(:username),
        'NFSHomeDirectory' => homedir,
        'UserShell' => '/bin/bash'
      }.each_pair {|k,v|
        # /Users/... here is a dscl path, not a filesystem path.
        sudo "dscl . -create #{'/Users' / var(:username)} #{k} '#{v}'"
      }
      sudo "mkdir -p '#{homedir}'"
      sudo "chown #{var(:username)}:admin '#{homedir}'"
      sudo "chmod 701 '#{homedir}'"
    }
  end
  on :linux do
    met? { grep(/^#{var(:username)}:/, '/etc/passwd') }
    meet {
      sudo "mkdir -p #{var :home_dir_base}" and
      sudo "useradd -m -s /bin/bash -b #{var :home_dir_base} -G admin #{var(:username)}" and
      sudo "chmod 701 #{var(:home_dir_base) / var(:username)}"
    }
  end
end
