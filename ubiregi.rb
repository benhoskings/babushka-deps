
dep 'ubiregi' do
  requires [
    'redis.bin',
    'mysql.bin',
    'mongodb.bin',

    'common:app bundled'.with('.', 'development'),
  ]
end

dep 'redis.bin' do
  provides 'redis-server', 'redis-cli'
end

dep 'mysql.bin' do
  provides 'mysql ~> 5.6.0'
end

dep 'mongodb.bin' do
  provides 'mongod', 'mongo'
end
