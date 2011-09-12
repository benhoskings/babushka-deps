dep 'firewall' do
  setup {
    requires({
      :ubuntu => 'ufw active'
    })[system_desc]
  }
end

dep 'ufw active' do
  requires 'ufw configured'
  met? { shell('ufw status').val_for('status') == 'active' }
  meet { shell 'ufw enable', :input => 'y' }
end

dep 'ufw configured' do
  requires 'ufw ipv6 support'
end

dep 'ufw ipv6 support' do
  requires pkg('ufw')
  met? { grep 'IPV6=yes', '/etc/default/ufw' }
  meet { change_with_sed 'IPV6', 'no', 'yes', '/etc/default/ufw' }
end
