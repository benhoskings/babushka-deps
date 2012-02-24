dep 'passwordless sudo', :username do
  setup {
    unmeetable! "This dep must be run as root." unless shell('whoami') == 'root'
  }
  met? {
    shell 'sudo -k', :as => 'ben' # expire an existing cached password
    shell? 'sudo -n true', :as => 'ben'
  }
  meet {
    shell "echo '#{username} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
  }
end

dep 'passwordless sudo removed', :username do
  setup {
    unmeetable! "This dep must be run as root." unless shell('whoami') == 'root'
  }
  met? {
    shell 'sudo -k', :as => 'ben' # expire an existing cached password
    raw_shell('sudo -n true', :as => 'ben').stderr['sorry, a password is required to run sudo']
  }
  meet {
    # We have to use a trailing space instead of \b because BSD sed is nub.
    shell "sed -i '' '/^#{Regexp.escape(username)} /d' /etc/sudoers"
  }
end
