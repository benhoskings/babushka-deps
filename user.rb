dep 'dot files', :username do
  username.default!(shell('whoami'))
  requires 'user exists'.with(:username => username), 'git', 'curl.managed', 'git-smart.gem'
  met? { File.exists?(ENV['HOME'] / ".dot-files/.git") }
  meet { shell %Q{curl -L "http://github.com/#{var :github_user, :default => 'benhoskings'}/#{var :dot_files_repo, :default => 'dot-files'}/raw/master/clone_and_link.sh" | bash} }
end

dep 'user auth setup', :username, :password, :key do
  requires 'user exists with password'.with(username, password), 'passwordless ssh logins'.with(username, key)
end

dep 'user exists with password', :username, :password do
  requires 'user exists'.with(:username => username)
  on :linux do
    met? { shell('sudo cat /etc/shadow')[/^#{username}:[^\*!]/] }
    meet {
      sudo %{echo "#{password}\n#{password}" | passwd #{username}}
    }
  end
end

dep 'user exists', :username, :home_dir_base do
  home_dir_base.default(username['.'] ? '/srv/http' : '/home')

  on :osx do
    met? { !shell("dscl . -list /Users").split("\n").grep(username).empty? }
    meet {
      homedir = home_dir_base / username
      {
        'Password' => '*',
        'UniqueID' => (501...1024).detect {|i| (Etc.getpwuid i rescue nil).nil? },
        'PrimaryGroupID' => 'admin',
        'RealName' => username,
        'NFSHomeDirectory' => homedir,
        'UserShell' => '/bin/bash'
      }.each_pair {|k,v|
        # /Users/... here is a dscl path, not a filesystem path.
        sudo "dscl . -create #{'/Users' / username} #{k} '#{v}'"
      }
      sudo "mkdir -p '#{homedir}'"
      sudo "chown #{username}:admin '#{homedir}'"
      sudo "chmod 701 '#{homedir}'"
    }
  end
  on :linux do
    met? { grep(/^#{username}:/, '/etc/passwd') }
    meet {
      sudo "mkdir -p #{home_dir_base}" and
      sudo "useradd -m -s /bin/bash -b #{home_dir_base} -G admin #{username}" and
      sudo "chmod 701 #{home_dir_base / username}"
    }
  end
end
