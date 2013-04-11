dep 'ngircd', :host, :description, :admin_email, :channels do
  def hostname
    shell('hostname -f')
  end
  host.default("irc.#{hostname}")
  description.default("#{hostname} IRC server")
  admin_email.default("root@#{hostname}")
  channels.ask("Channel names (space-separated, don't worry about the '#')")

  requires 'ngircd.bin'

  met? {
    Babushka::Renderable.new('/etc/ngircd/ngircd.conf').from?(dependency.load_path.parent / 'ngircd/ngircd.conf.erb')
  }
  meet {
    render_erb 'ngircd/ngircd.conf.erb', :to => '/etc/ngircd/ngircd.conf', :sudo => true
  }
end

dep 'ngircd.bin'
