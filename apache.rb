dep 'lamp stack removed', :for => :apt do
  def packages
    shell("dpkg --get-selections").split("\n").select {|l|
      l[/\binstall$/]
    }.split("\n").map {|l|
      l.split(/\s+/, 2).first
    }.select {|l|
      l[/apache|mysql|php/]
    }
  end
  met? {
    packages.empty?
  }
  meet {
    packages.each {|pkg|
      log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", :sudo => true
    }
  }
  after {
    log_shell "Autoremoving packages", "apt-get -y autoremove", :sudo => true
  }
end
