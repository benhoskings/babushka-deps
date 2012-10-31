dep 'passwordless ssh logins', :username, :key do
  username.default(shell('whoami'))
  def ssh_dir
    "~#{username}" / '.ssh'
  end
  def group
    shell "id -gn #{username}"
  end
  def sudo?
    @sudo ||= username != shell('whoami')
  end
  met? {
    shell? "fgrep '#{key}' '#{ssh_dir / 'authorized_keys'}'", :sudo => sudo?
  }
  meet {
    shell "mkdir -p -m 700 '#{ssh_dir}'", :sudo => sudo?
    shell "cat >> #{ssh_dir / 'authorized_keys'}", :input => key, :sudo => sudo?
    sudo "chown -R #{username}:#{group} '#{ssh_dir}'" unless ssh_dir.owner == username
    sudo "chown -R #{username}:#{group} '#{ssh_dir / 'authorized_keys'}'" unless (ssh_dir / 'authorized_keys').owner == username
    shell "chmod 600 #{(ssh_dir / 'authorized_keys')}", :sudo => sudo?
  }
end

dep 'public key' do
  met? { '~/.ssh/id_dsa.pub'.p.grep(/^ssh-dss/) }
  meet { log shell("ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ''") }
end

dep 'bad certificates removed' do
  def cert_names
    %w[
      DigiNotar_Root_CA
    ]
  end
  def existing_certs
    cert_names.map {|name|
      "/etc/ssl/certs/#{name}.pem".p
    }.select {|cert|
      cert.exists?
    }
  end
  setup {
    unless [:debian, :ubuntu].include?(Babushka.host.flavour)
      unmeetable! "Not sure where to find certs on a #{Babushka.host.description} system."
    end
  }
  met? { existing_certs.empty? }
  meet { existing_certs.each(&:rm) }
end
