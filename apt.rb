dep 'apt packages removed', :match, :for => :apt do
  deprecated! "2013-12-12", :method_name => "'benhoskings:apt packages removed'", :callpoint => false, :instead => "'common:apt packages removed'"
  def packages
    shell("dpkg --get-selections").split("\n").select {|l|
      l[/\binstall$/]
    }.map {|l|
      l.split(/\s+/, 2).first
    }
  end
  def to_remove match
    packages.select {|pkg| pkg[match.current_value] }
  end
  met? {
    to_remove(match).empty?
  }
  meet {
    to_remove(match).each {|pkg|
      log_shell "Removing #{pkg}", "apt-get -y remove --purge '#{pkg}'", :sudo => true
    }
  }
  after {
    log_shell "Autoremoving packages", "apt-get -y autoremove", :sudo => true
  }
end
