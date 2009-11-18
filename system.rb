def ssh_conf_path file
  "/etc#{'/ssh' if host.linux?}/#{file}_config"
end

dep 'hostname', :for => :linux do
  met? {
    stored_hostname = read_file('/etc/hostname')
    !stored_hostname.blank? && hostname == stored_hostname
  }
  meet {
    sudo "echo #{var :hostname, :default => shell('hostname')} > /etc/hostname"
    sudo "sed -ri 's/^127.0.0.1.*$/127.0.0.1 #{var :hostname} localhost.localdomain localhost/' /etc/hosts"
    sudo "/etc/init.d/hostname.sh"
  }
end

dep 'secured ssh logins' do
  requires 'sshd', 'sed'
  met? {
    # -o NumberOfPasswordPrompts=0
    output = failable_shell('ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no nonexistentuser@localhost').stderr
    if output.downcase['connection refused']
      log_ok "sshd doesn't seem to be running."
    elsif (auth_methods = output.scan(/\((.*)\)/).join.split(/[^a-z]+/)).empty?
      log_error "sshd returned unexpected output."
    else
      returning auth_methods == %w[publickey] do |result|
        log_verbose "sshd #{'only ' if result}accepts #{auth_methods.to_list} logins.", :as => (result ? :ok : :error)
      end
    end
  }
  meet {
    change_with_sed 'PasswordAuthentication',          'yes', 'no', ssh_conf_path(:sshd)
    change_with_sed 'ChallengeResponseAuthentication', 'yes', 'no', ssh_conf_path(:sshd)
  }
  after { sudo "/etc/init.d/ssh restart" }
end

dep 'lax host key checking' do
  requires 'sed'
  met? { grep /^StrictHostKeyChecking[ \t]+no/, ssh_conf_path(:ssh) }
  meet { change_with_sed 'StrictHostKeyChecking', 'yes', 'no', ssh_conf_path(:ssh) }
end

dep 'admins can sudo' do
  requires 'admin group'
  met? { !sudo('cat /etc/sudoers').split("\n").grep(/^%admin/).empty? }
  meet { append_to_file '%admin  ALL=(ALL) ALL', '/etc/sudoers', :sudo => true }
end

dep 'admin group' do
  met? { grep /^admin\:/, '/etc/group' }
  meet { sudo 'groupadd admin' }
end

dep 'build tools' do
  requires {
    on :osx, 'xcode tools'
    on :snow_leopard, 'llvm in path'
    on :linux, 'build-essential', 'autoconf'
  }
end

dep 'tmp cleaning grace period', :for => :ubuntu do
  met? { !grep(/^[^#]*TMPTIME=0/, "/etc/default/rcS") }
  meet { change_line "TMPTIME=0", "TMPTIME=30", "/etc/default/rcS" }
end
