meta :shell_setup do
  template {
    met? { grep which(name), '/etc/shells' }
    meet { append_to_file which(name), '/etc/shells', :sudo => true }
  }
end

dep 'fish.shell_setup' do
  requires 'fish.src'
end

dep 'fish.src' do
  requires 'ncurses', 'coreutils', 'gettext'
  source "git://github.com/benhoskings/fish.git"
end

dep 'zsh.shell_setup' do
  requires 'zsh.managed'
end

dep 'zsh', :template => 'managed'
