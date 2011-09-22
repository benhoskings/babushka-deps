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
    sudo "mkdir -p -m 700 '#{ssh_dir}'"
  }
  meet {
    append_to_file var(:your_ssh_public_key), (ssh_dir / 'authorized_keys'), :sudo => true
  }
  after {
    sudo "chown -R #{var(:username)}:#{group} '#{ssh_dir}'"
    sudo "chmod 600 #{(ssh_dir / 'authorized_keys')}"
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
