dep 'ngircd', :host, :description, :admin_email, :channels do
  host.default("irc.#{shell('hostname -f')}")
  description.default("#{hostname} IRC server")
  admin_email.default("root@#{shell('hostname -f')}")
  channels.ask("Channel names (space-separated, don't worry about the '#')")

  requires 'ngircd.bin'

  met? {
    Babushka::Renderable.new().from?(dependency.load_path.parent / "nginx/vhost.conf.erb")
  }
  meet {
    render_erb "nginx/vhost.conf.erb", :to => vhost_conf, :sudo => true
  }
end

dep 'ngircd.bin'
