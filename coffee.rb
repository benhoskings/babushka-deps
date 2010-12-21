dep 'coffeescript.src' do
  requires 'nodejs.src'
  source 'git://github.com/jashkenas/coffee-script.git'
  provides 'coffee ~> 0.9.6'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install" }
end

dep 'nodejs.src' do
  source 'git://github.com/ry/node.git'
  provides 'node', 'node-waf'
end
