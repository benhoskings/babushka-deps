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
    met? {
      (prefix / 'bin/ruby').executable? and
      shell(prefix / 'bin/ruby -v')[/^ruby #{installs}\b/]
    }
    meet {
      handle_source "http://ftp.ruby-lang.org/pub/ruby/#{version_group}/ruby-#{version}.tar.gz" do |path|
        log_shell 'Configure', "./configure --prefix='#{prefix}'"
        log_shell 'Build',     "make"
        log_shell 'Install',   "make install"
      end
    }
  }
end

dep '1.9.2.rbenv' do
  builds '1.9.2-p290'
end

dep '1.9.3.rbenv' do
  builds '1.9.3-preview1'
  installs '1.9.3dev'
end
