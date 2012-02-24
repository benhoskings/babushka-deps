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
dep 'git-smart.gem' do
  provides %w[git-smart-log git-smart-merge git-smart-pull]
end
dep 'htop.managed'
dep 'imagemagick.managed' do
  provides %w[compare animate convert composite conjure import identify stream display montage mogrify]
end
dep 'image_science.gem' do
  requires 'freeimage.managed'
  provides []
end
dep 'iotop.managed'
dep 'java.managed' do
  installs { via :apt, 'sun-java6-jre' }
  after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
end
dep 'jnettop.managed' do
  installs { via :apt, 'jnettop' }
end
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
  installs { via :apt, 'libxml2-dev' }
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
dep 'pcre.managed' do
  installs {
    via :brew, 'pcre'
    via :macports, 'pcre'
    via :apt, 'libpcre3-dev'
    via :yum, 'pcre-devel'
  }
  provides 'pcre-config'
end
dep 'pv.managed'
dep 'rcconf.managed' do
  installs { via :apt, 'rcconf' }
end
dep 'sed.managed' do
  installs {
    via :brew, 'gnu-sed'
    via :macports, 'gsed'
  }
  provides 'sed'
  after {
    cd pkg_manager.bin_path do
      shell "ln -s gsed sed", :sudo => pkg_manager.should_sudo?
    end
  }
end
dep 'sshd.managed' do
  installs {
    via :apt, 'openssh-server'
  }
end
dep 'tmux.managed'
dep 'traceroute.managed'
dep 'tree.managed'
dep 'vim.managed'
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
