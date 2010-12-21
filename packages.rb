dep 'bison.managed'
dep 'bundler.gem' do
  installs 'bundler >= 1.0.0'
  provides 'bundle'
end
dep 'coreutils.managed', :for => :osx do
  provides 'gecho'
  after :on => :osx do
    in_dir pkg_manager.bin_path do
      sudo "ln -s gecho echo"
    end
  end
end
dep 'erlang.managed' do
  provides 'erl', 'erlc'
end
dep 'freeimage.managed' do
  installs {
    via :apt, %w[libfreeimage3 libfreeimage-dev]
    via :macports, 'freeimage'
    via :brew, 'freeimage'
  }
  provides []
end
dep 'gettext.managed'
dep 'htop.managed'
dep 'image_science.gem' do
  requires 'freeimage.managed'
  provides []
end
dep 'java.managed' do
  installs { via :apt, 'sun-java6-jre' }
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
dep 'jnettop.managed' do
  installs { via :apt, 'jnettop' }
end
dep 'readline headers.managed' do
  installs {
    via :apt, 'libreadline5-dev'
  }
  provides []
end
dep 'libssl headers.managed' do
  installs { via :apt, 'libssl-dev' }
  provides []
end
dep 'libxml.managed' do
  installs { via :apt, 'libxml2-dev' }
  provides []
end
dep 'mdns.managed' do
  installs {
    via :apt, 'avahi-daemon'
  }
  provides []
end
dep 'memcached.managed'
dep 'ncurses.managed' do
  installs {
    via :apt, 'libncurses5-dev', 'libncursesw5-dev'
    via :macports, 'ncurses', 'ncursesw'
  }
  provides []
end
dep 'nmap.managed'
dep 'oniguruma.managed'
dep 'passenger.gem' do
  installs 'passenger ~> 3.0'
  provides 'passenger-install-nginx-module'
end
dep 'pcre.managed' do
  installs {
    via :brew, 'pcre'
    via :macports, 'pcre'
    via :apt, 'libpcre3-dev'
  }
  provides 'pcretest'
end
dep 'rcconf.managed' do
  installs { via :apt, 'rcconf' }
end
dep 'screen.managed'
dep 'sed.managed' do
  installs { via :macports, 'gsed' }
  provides 'sed'
  after {
    in_dir '/opt/local/bin' do
      sudo "ln -s gsed sed"
    end
  }
end
dep 'sshd.managed' do
  installs {
    via :apt, 'openssh-server'
  }
end
dep 'tree.managed'
dep 'vim.managed'
dep 'wget.managed'
dep 'zlib headers.managed' do
  installs { via :apt, 'zlib1g-dev' }
  provides []
end
