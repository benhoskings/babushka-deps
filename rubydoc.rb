dep 'rubydoc' do
  requires 'yard', dep('rack_hoptoad.gem'), dep('sequel.gem'), dep('sqlite3-ruby.gem'), 'yard.gem', 'pg.gem', 'sinatra.gem'
  after {
    log "Next:\n$ rackup config.ru"
  }
end

# git clone git://github.com/lsegal/rubydoc.info && cd rubydoc.info
# rake gems:update (to retrieve the latest list of published gems)
# git clone git://github.com/lsegal/yard yard
