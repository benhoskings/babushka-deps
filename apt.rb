meta :apt_repo do
  accepts_value_for :adds
  template {
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
      pkg_helper.update_pkg_lists "Updating apt lists to load #{adds}."
    }
  }
end

dep 'ppa postgres.apt_repo' do
  requires dep('python-software-properties.managed')
  adds 'ppa:pitti/postgresql'
end
