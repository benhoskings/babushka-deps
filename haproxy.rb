dep 'haproxy', :for => :linux do
  requires 'haproxy configured', 'syslog tcp logging'
  met? { shell "netstat -an | grep -E '^tcp.*#{var :listen_address}[.:]#{var :listen_port} +.*LISTEN'" }
  meet { change_line 'ENABLED=0', 'ENABLED=1', '/etc/default/haproxy' }
  after { sudo '/etc/init.d/haproxy restart' }
end

dep 'haproxy configured' do
  requires 'haproxy config generated'
  met? {
    if grep "babushka needs this line to be deleted", '/etc/haproxy/haproxy.cfg'
      log_error "You need to hand-edit /etc/haproxy/haproxy.cfg next."
      :fail
    else true
    end
  }
end

dep 'haproxy config generated' do
  requires pkg('haproxy')
  met? { babushka_config? '/etc/haproxy/haproxy.cfg' }
  meet { render_erb 'haproxy/haproxy.cfg.erb', :to => '/etc/haproxy/haproxy.cfg', :sudo => true }
end

dep 'syslog tcp logging' do
  met? { grep 'SYSLOGD="-r"', '/etc/default/syslogd' }
  meet { change_line 'SYSLOGD=""', 'SYSLOGD="-r"', '/etc/default/syslogd' }
  after { sudo '/etc/init.d/sysklogd restart' }
end
