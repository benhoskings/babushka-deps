dep 'coffeescript.src', :version do
  version.default!('1.1.2')
  requires 'nodejs.src'
  source "http://github.com/jashkenas/coffee-script/tarball/#{version}"
  provides "coffee >= #{version}"

  configure { true }
  build { shell "bin/cake build" }
  install { shell "bin/cake install", :sudo => Babushka::SrcHelper.should_sudo? }
end

dep 'nodejs.src' do
  source 'git://github.com/joyent/node.git'
  provides 'node', 'node-waf'
end
