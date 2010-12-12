dep 'lvm' do
  requires 'lvm2.managed', 'lvm startup commands'
end

dep 'lvm2.managed' do
  provides 'lvdisplay'
end

dep 'lvm startup commands' do
  setup { set :lvm_startup_command, "modprobe dm_mod; vgscan; vgchange -a y; mount -a # manually initialise lvm" }
  met? { grep var(:lvm_startup_command), '/etc/rc.local' }
  meet { append_to_file var(:lvm_startup_command), "/etc/rc.local" }
end
