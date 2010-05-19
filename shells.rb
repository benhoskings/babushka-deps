meta :shell_setup do
  template {
    setup { requires "#{name} installed" }
    met? { grep which(name), '/etc/shells' }
    meet { append_to_file which(name), '/etc/shells', :sudo => true }
  }
end

shell_setup 'fish'

src 'fish installed' do
  requires 'ncurses', 'coreutils', 'gettext'
  source "git://github.com/benhoskings/fish.git"
  provides 'fish'
end

shell_setup 'zsh'

pkg 'zsh installed' do
  installs 'zsh'
  provides 'zsh'
end
