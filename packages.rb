dep 'coreutils', :template => 'managed', :for => :osx do
  provides 'gecho'
  after :on => :osx do
    in_dir pkg_manager.bin_path do
      sudo "ln -s gecho echo"
    end
  end
end
dep 'erlang', :template => 'managed'
dep 'freeimage', :template => 'managed' do
  installs {
    via :apt, %w[libfreeimage3 libfreeimage-dev]
    via :macports, 'freeimage'
    via :brew, 'freeimage'
  }
  provides []
end
dep 'gettext', :template => 'managed'
dep 'htop', :template => 'managed'
dep 'image_science.gem' do
  requires 'freeimage'
  provides []
end
dep 'java', :template => 'managed' do
  installs { via :apt, 'sun-java6-jre' }
  provides 'java'
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
dep 'jnettop', :template => 'managed' do
  installs { via :apt, 'jnettop' }
end
dep 'libssl headers', :template => 'managed' do
  installs { via :apt, 'libssl-dev' }
  provides []
end
dep 'libxml', :template => 'managed' do
  installs { via :apt, 'libxml2-dev' }
  provides []
end
dep 'mdns', :template => 'managed' do
  installs {
    via :apt, 'avahi-daemon'
  }
  provides []
end
dep 'memcached', :template => 'managed'
dep 'ncurses', :template => 'managed' do
  installs {
    via :apt, 'libncurses5-dev', 'libncursesw5-dev'
    via :macports, 'ncurses', 'ncursesw'
  }
  provides []
end
dep 'nmap', :template => 'managed'
dep 'oniguruma', :template => 'managed'
dep 'passenger.gem' do
  installs 'passenger' => '>= 2.2.9'
  provides 'passenger-install-nginx-module'
end
dep 'pcre', :template => 'managed' do
  installs {
    via :brew, 'pcre'
    via :macports, 'pcre'
    via :apt, 'libpcre3-dev'
  }
  provides 'pcretest'
end
dep 'rcconf', :template => 'managed' do
  installs { via :apt, 'rcconf' }
end
dep 'screen', :template => 'managed'
dep 'sed', :template => 'managed' do
  installs { via :macports, 'gsed' }
  provides 'sed'
  after {
    in_dir '/opt/local/bin' do
      sudo "ln -s gsed sed"
    end
  }
end
dep 'sshd', :template => 'managed' do
  installs {
    via :apt, 'openssh-server'
  }
end
dep 'vim', :template => 'managed'
dep 'wget', :template => 'managed'
dep 'zlib headers', :template => 'managed' do
  installs { via :apt, 'zlib1g-dev' }
  provides []
end
