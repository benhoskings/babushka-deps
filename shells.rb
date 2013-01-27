meta :shell_setup do
  template {
    met? { '/etc/shells'.p.grep(which(basename)) }
    meet { append_to_file which(basename), '/etc/shells', :sudo => true }
  }
end

dep 'fish.shell_setup' do
  requires 'fish.src'
end

dep 'fish.src' do
  requires 'ncurses.managed', 'coreutils.managed', 'gettext.lib'
  source "git://github.com/benhoskings/fish.git"
end

dep 'zsh', :username do
  username.default!(shell('whoami'))
  requires 'zsh.shell_setup'
  # It would be great to be able to do this, but GNU `login` doesn't have '-f'.
  # met? { shell("login -f '#{username}' env").val_for('SHELL') == which('zsh') }
  met? { shell("sudo su - '#{username}' -c 'echo $SHELL'") == which('zsh') }
  meet { sudo("chsh -s '#{which('zsh')}' #{username}") }
end

dep 'zsh.shell_setup' do
  requires 'zsh.bin'
end

dep 'zsh.bin'
