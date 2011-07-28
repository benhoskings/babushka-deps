dep 'coffeescript.src' do
  requires 'nodejs.src'
  source 'http://github.com/jashkenas/coffee-script/tarball/1.1.1'
  provides 'coffee ~> 1.1.1'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install" }
end

dep 'nodejs.src' do
  source 'git://github.com/joyent/node.git'
  provides 'node', 'node-waf'
end
