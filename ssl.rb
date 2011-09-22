dep 'passwordless ssh logins', :user, :key do
  user.default(shell('whoami'))
  def ssh_dir
    "~#{user}" / '.ssh'
  end
  def group
    shell "id -gn #{user}"
  end
  def sudo?
    @sudo ||= user == shell('whoami')
  end
  met? {
    shell "grep '#{key}' '#{ssh_dir / 'authorized_keys'}'", :sudo => sudo?
  }
  before {
    shell "mkdir -p -m 700 '#{ssh_dir}'", :sudo => sudo?
  }
  meet {
    append_to_file key, (ssh_dir / 'authorized_keys'), :sudo => sudo?
  }
  after {
    shell "chown -R #{user}:#{group} '#{ssh_dir}'", :sudo => sudo?
    shell "chmod 600 #{(ssh_dir / 'authorized_keys')}", :sudo => sudo?
  }
end

dep 'public key' do
  met? { grep(/^ssh-dss/, '~/.ssh/id_dsa.pub') }
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
    unless [:debian, :ubuntu].include?(Babushka::Base.host.flavour)
      unmeetable "Not sure where to find certs on a #{Babushka::Base.host.description} system."
    end
  }
  met? { existing_certs.empty? }
  meet { existing_certs.each(&:rm) }
end
