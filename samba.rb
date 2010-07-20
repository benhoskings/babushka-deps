dep 'samba' do
  requires 'samba.managed'
  met? { babushka_config? "/etc/samba/smb.conf" }
  meet { render_erb "samba/smb.conf.erb", :to => "/etc/samba/smb.conf", :sudo => true }
  after { sudo "/etc/init.d/samba restart" }
end

dep 'samba', :template => 'managed' do
  installs { via :apt, 'samba' }
  provides []
end
