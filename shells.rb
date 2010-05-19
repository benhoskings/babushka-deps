dep 'fish' do
  requires 'fish installed'
  met? { grep which('fish'), '/etc/shells' }
  meet { append_to_file which('fish'), '/etc/shells', :sudo => true }
end

src 'fish installed' do
  requires 'ncurses', 'coreutils', 'gettext'
  source "git://github.com/benhoskings/fish.git"
  provides 'fish'
end
