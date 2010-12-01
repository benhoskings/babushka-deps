meta :apt_repo do
  accepts_value_for :adds
  template {
    met? {
      adds[/^\w+\:\w+/]
      Dir.glob("/etc/apt/sources.list.d").any? {|f|
        f[Regexp.new('https?\:\/\/' + adds.sub(':', '\.*\/ubuntu\ '))]
      }
    }
    meet {
      sudo "sudo add-apt-repository #{adds}"
    }
  }
end

dep 'ppa postgres.apt_repo' do
  adds 'ppa:pitti/postgresql'
end
