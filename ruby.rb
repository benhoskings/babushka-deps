dep 'ruby trunk.src' do
  requires 'bison.managed', 'readline headers.managed'
  source 'git://github.com/ruby/ruby.git'
  provides 'ruby == 1.9.3.dev', 'gem', 'irb'
  configure_args '--disable-install-doc', '--with-readline-dir=/usr'
end

dep 'ruby19.src', :version do
  version.default!('1.9.2p290')
  requires 'readline headers.managed', 'yaml headers.managed'
  source "ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-#{version}.tar.gz"
  provides "ruby == #{version}", 'gem', 'irb'
  configure_args '--disable-install-doc',
    "--with-readline-dir=#{Babushka::Base.host.pkg_helper.prefix}",
    "--with-libyaml-dir=#{Babushka::Base.host.pkg_helper.prefix}"
  postinstall {
    # TODO: hack for ruby bug where bin/* aren't installed when the build path
    # contains a dot-dir.
    shell "cp bin/* #{prefix / 'bin'}", :sudo => Babushka::SrcHelper.should_sudo?
  }
end
