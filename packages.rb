dep 'bison.managed'
dep 'bundler.gem' do
  installs 'bundler >= 1.0.13'
  provides 'bundle'
end
dep 'coreutils.managed', :for => :osx do
  provides 'gecho'
  after :on => :osx do
    cd pkg_manager.bin_path do
      sudo "ln -s gecho echo"
    end
  end
end
dep 'curl.lib' do
  installs {
    on :osx, [] # It's provided by the system.
    otherwise 'libcurl4-openssl-dev'
  }
end
dep 'erlang.managed' do
  provides 'erl', 'erlc'
end
dep 'freeimage.managed' do
  installs {
    via :apt, %w[libfreeimage3 libfreeimage-dev]
    otherwise 'freeimage'
  }
  provides []
end
dep 'git-smart.gem' do
  provides %w[git-smart-log git-smart-merge git-smart-pull]
end
dep 'htop.bin'
dep 'imagemagick.managed' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end
dep 'image_science.gem' do
  requires 'freeimage.managed'
  provides []
end
dep 'iotop.bin'
dep 'java.managed' do
  installs { via :apt, 'sun-java6-jre' }
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
dep 'jnettop.bin'
dep 'readline headers.managed' do
  installs {
    on :lenny, 'libreadline5-dev'
    via :apt, 'libreadline6-dev'
  }
  provides []
end
dep 'libssl headers.managed' do
  installs {
    via :apt, 'libssl-dev'
    via :yum, 'openssl-devel'
  }
  provides []
end

dep 'libxml.managed' do
  installs {
    # The latest libxml2 on 12.04 doesn't have a corresponding libxml2-dev.
    on :precise, [
      'libxml2 == 2.7.8.dfsg-5.1ubuntu4',
      'libxml2-dev == 2.7.8.dfsg-5.1ubuntu4'
    ]

    via :apt, 'libxml2-dev'
  }
  provides []
end

dep 'libxslt.managed' do
  installs { via :apt, 'libxslt1-dev' }
  provides []
end
dep 'logrotate.managed'
dep 'mdns.managed' do
  installs {
    via :apt, 'avahi-daemon'
  }
  provides []
end
dep 'lsof.bin'
dep 'memcached.managed'
dep 'ncurses.managed' do
  installs {
    via :apt, 'libncurses5-dev', 'libncursesw5-dev'
    otherwise 'ncurses'
  }
  provides []
end
dep 'nmap.bin'
dep 'oniguruma.managed'
dep 'openssl.lib' do
  installs {
    via :apt, 'openssl', 'libssl-dev'
    otherwise 'openssl'
  }
end
dep 'pcre.managed' do
  installs {
    via :apt, 'libpcre3-dev'
    via :yum, 'pcre-devel'
    otherwise 'pcre'
  }
  provides 'pcre-config'
end
dep 'pv.bin'
dep 'rcconf.managed' do
  installs { via :apt, 'rcconf' }
end
dep 'sed.bin' do
  installs {
    via :brew, 'gnu-sed'
  }
  after {
    cd pkg_manager.bin_path do
      shell "ln -s gsed sed", :sudo => pkg_manager.should_sudo?
    end
  }
end
dep 'sshd.bin' do
  installs {
    via :apt, 'openssh-server'
  }
end
dep 'tmux.bin'
dep 'traceroute.bin'
dep 'tree.bin'
dep 'unzip.managed'
dep 'vim.bin'
dep 'wget.managed'
dep 'yaml headers.managed' do
  installs {
    via :brew, 'libyaml'
    via :apt, 'libyaml-dev'
  }
  provides []
end
dep 'zlib headers.managed' do
  installs {
    via :apt, 'zlib1g-dev'
    via :yum, 'zlib-devel'
  }
  provides []
end
