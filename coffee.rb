dep 'coffeescript.src' do
  requires 'nodejs.src'
  source 'http://github.com/jashkenas/coffee-script/tarball/1.1.1'
  provides 'coffee ~> 1.1.1'

  process_source {
    cd 'jashkenas-coffee-script-d4d0271' do
      shell "bin/cake build"
      shell "bin/cake install"
    end
  }
end

dep 'nodejs.src' do
  source 'git://github.com/joyent/node.git'
  provides 'node', 'node-waf'
end
