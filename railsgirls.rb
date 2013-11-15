dep 'railsgirls' do
  requires [
    'bundle locally',
    'ruby.bin',
    'bundler.gem',
    'sqlite.bin',
  ]
end

require 'yaml'

dep 'bundle locally' do
  met? {
    ('~/.bundle/config'.p.read || '').val_for('BUNDLE_PATH') == './vendor/bundle'
  }
  meet {
    '~/.bundle/config'.p.write("---
BUNDLE_PATH: ./vendor/bundle
BUNDLE_BIN: bin
BUNDLE_DISABLE_SHARED_GEMS: '1'
")
  }
end

dep 'ruby.bin'

dep 'sqlite.bin' do
  provides 'sqlite3'
end
