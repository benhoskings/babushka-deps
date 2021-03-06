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
    on :apt, 'libcurl4-openssl-dev'
    otherwise 'curl'
  }
end
dep 'erlang.managed' do
  provides 'erl', 'erlc'
end
dep 'ffi.lib' do
  installs 'libffi-dev'
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
dep 'java.bin' do
  installs 'openjdk-7-jre'
end
dep 'jnettop.bin'
dep 'readline.lib' do
  installs {
    on :lenny, 'libreadline5-dev'
    via :apt, 'libreadline6-dev'
    otherwise 'readline'
  }
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
dep 'nodejs.src', :version do
  version.default!('0.10.17')
  source "http://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz"
  provides "node >= #{version}"
  after {
    # Trigger the creation of npm's global package dir, which it can't run
    # without. (Only newer nodes bundle npm, though.)
    shell!('npm --version') if which('npm')
  }
end
dep 'oniguruma.managed'
dep 'openssl.lib' do
  installs {
    via :apt, 'libssl-dev'
    via :yum, 'openssl-devel'
    otherwise 'openssl'
  }
end
dep 'pcre.lib' do
  installs {
    via :apt, 'libpcre3-dev'
    via :yum, 'pcre-devel'
    otherwise 'pcre'
  }
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
    via :pacman, 'openssh'
  }
end
dep 'tmux.bin'
dep 'traceroute.bin'
dep 'tree.bin'
dep 'unzip.bin'
dep 'vim.bin'
dep 'wget.managed'
dep 'yaml.lib' do
  installs {
    via :apt, 'libyaml-dev'
    otherwise 'libyaml'
  }
end
dep 'zlib.lib' do
  installs {
    via :apt, 'zlib1g-dev'
    via :yum, 'zlib-devel'
    via :brew, []
    otherwise 'zlib'
  }
end
