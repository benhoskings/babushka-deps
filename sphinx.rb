dep 'sphinx.src' do
  source 'http://www.sphinxsearch.com/downloads/sphinx-0.9.9.tar.gz'
  provides 'search', 'searchd', 'indexer'
  configure_args L{
    [
      ("--with-pgsql=#{shell 'pg_config --pkgincludedir'}" if confirm("Build with postgres support?")),
      ("--without-mysql" unless confirm("Build with mysql support?"))
    ].compact.join(" ")
  }
end
