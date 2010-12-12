dep 'coffeescript.src' do
  requires 'nodejs.src'
  source 'git://github.com/jashkenas/coffee-script.git'
  provides 'coffee'

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install" }
end

dep 'nodejs.src' do
  source 'git://github.com/ry/node.git'
  provides 'node', 'node-repl', 'node-waf'
end
