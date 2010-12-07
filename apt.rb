dep 'python-software-properties.managed' do
  provides 'add-apt-repository'
end

meta :apt_repo do
  accepts_value_for :adds
  template {
    requires 'python-software-properties.managed'
    met? {
      adds[/^\w+\:\w+/] &&
      Dir.glob("/etc/apt/sources.list.d/*").any? {|f|
        f.p.read[Regexp.new('https?://' + adds.gsub(':', '.*') + '/ubuntu ')]
      }
    }
    meet {
      sudo "sudo add-apt-repository #{adds}"
    }
    after {
      Babushka::Base.host.pkg_helper.update_pkg_lists "Updating apt lists to load #{adds}."
    }
  }
end

dep 'ppa postgres.apt_repo' do
  adds 'ppa:pitti/postgresql'
end
