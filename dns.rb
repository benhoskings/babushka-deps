dep 'dnsmasq' do
  requires 'dnsmasq.managed'
  def dnsmasq_conf
    "/etc/dnsmasq.conf".p
  end
  setup {
    define_var :dhcp_network,
      :type => :ip_range,
      :default => '10.0.1.x',
      :message => "What network range would you like to serve DHCP on?"

    set :dhcp_subnet, L{ Babushka::IPRange.new(var(:dhcp_network)).subnet }
    set :dhcp_broadcast_ip, L{ Babushka::IPRange.new(var(:dhcp_network)).broadcast }

    define_var :dns_domain, :message => "The network's domain", :default => 'example.org'
    define_var :dns_server_ip, :message => "The DNS server itself", :default => L{ Babushka::IPRange.new(var(:dhcp_network)).first }
    define_var :dhcp_router_ip, :message => "Default gateway", :default => L{ var :dns_server_ip }
    define_var :dhcp_start_address, :message => "DHCP starting address", :default => L{ Babushka::IP.new(var(:dns_server_ip)).next }
    define_var :dhcp_end_address, :message => "DHCP ending address", :default => L{ Babushka::IPRange.new(var(:dhcp_network)).last.prev }
  }
  met? { babushka_config? dnsmasq_conf }
  meet { render_erb "dnsmasq/dnsmasq.conf.erb", :to => dnsmasq_conf, :sudo => true }
end

dep 'dnsmasq.managed'
