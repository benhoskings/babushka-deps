# Usage:
# [install rbenv like normal] https://github.com/sstephenson/rbenv
# babushka 1.9.3.rbenv
# rbenv set-default 1.9.3-preview1
# rbenv rehash

dep 'rbenv' do
  met? {
    in_path? 'rbenv'
  }
end

meta :rbenv do
  accepts_value_for :builds
  accepts_value_for :installs, :builds
  template {
    def version
      builds
    end
    def prefix
      "~/.rbenv/versions" / version
    end
    def version_group
      version.scan(/^\d\.\d/).first
    end
    requires 'rbenv', 'yaml headers.managed'
    met? {
      (prefix / 'bin/ruby').executable? and
      shell(prefix / 'bin/ruby -v')[/^ruby #{installs}\b/]
    }
    meet {
      yaml_location = shell('brew info libyaml').split("\n").collapse(/\s+\(\d+ files, \S+\)/)
      handle_source "http://ftp.ruby-lang.org/pub/ruby/#{version_group}/ruby-#{version}.tar.gz" do |path|
        log_shell 'Configure', "./configure --prefix='#{prefix}' --with-libyaml-dir='#{yaml_location}' CC=/usr/bin/gcc-4.2"
        log_shell 'Build',     "make"
        log_shell 'Install',   "make install"
      end
    }
    after {
      # TODO: hack for ruby bug where bin/* aren't installed when the build path
      # contains a dot-dir.
      shell "cp bin/* #{prefix / 'bin'}"

      log_shell 'rbenv rehash', 'rbenv rehash'
    }
  }
end

dep '1.9.2.rbenv' do
  builds '1.9.2-p290'
  installs '1.9.2p290'
end

dep '1.9.3.rbenv' do
  builds '1.9.3-preview1'
  installs '1.9.3dev'
end

dep '1.8.6.rbenv' do
  builds '1.8.6-p420'
  installs '1.8.6p420'
end

dep '1.8.7.rbenv' do
  builds '1.8.7-p352'
  installs '1.8.7p352'
end
