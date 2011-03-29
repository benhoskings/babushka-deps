meta :apt_packages_removed do
  accepts_list_for :removes
  template {
    def packages
      shell("dpkg --get-selections").split("\n").select {|l|
        l[/\binstall$/]
      }.map {|l|
        l.split(/\s+/, 2).first
      }
    end
    def to_remove
      packages.select {|pkg|
        removes.any? {|r| pkg[r] }
      }
    end
    met? {
      to_remove.empty?
    }
    meet {
      to_remove.each {|pkg|
        log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", :sudo => true
      }
    }
    after {
      log_shell "Autoremoving packages", "apt-get -y autoremove", :sudo => true
    }
  }
end
