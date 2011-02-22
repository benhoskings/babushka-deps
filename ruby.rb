dep 'ruby trunk.src' do
  requires 'bison.managed', 'readline headers.managed'
  source 'git://github.com/ruby/ruby.git'
  provides 'ruby == 1.9.3.dev', 'gem', 'irb'
  configure_args '--disable-install-doc', '--with-readline-dir=/usr'
end

dep 'ruby19.src' do
  requires 'readline headers.managed'
  source 'ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p180.tar.gz'
  provides 'ruby == 1.9.2p180', 'gem', 'irb'
  configure_args '--disable-install-doc', '--with-readline-dir=/usr'
  # TODO: hack for ruby bug where bin/* aren't installed when the build path
  # contains a dot-dir.
  postinstall {
    shell "cp bin/* #{prefix / 'bin'}", :sudo => Babushka::SrcHelper.should_sudo?
  }
end
