dep 'dnsmasq', :dns_domain, :dns_server_ip do
  requires 'dnsmasq.managed'

  dns_domain.ask("The network's domain").default('example.org')
  dns_server_ip.ask("The DNS server itself").default('10.0.1.1')

  def dnsmasq_conf
    "/etc/dnsmasq.conf".p
  end
  met? { babushka_config? dnsmasq_conf }
  meet { render_erb "dnsmasq/dnsmasq.conf.erb", :to => dnsmasq_conf, :sudo => true }
end

dep 'dnsmasq.managed'
