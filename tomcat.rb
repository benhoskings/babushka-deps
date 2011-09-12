dep 'tomcat app' do
  requires 'tomcat configured', 'java build chain', 'writable deploy dir'
end

dep 'tomcat configured' do
  requires 'tomcat'
  met? { ENV['CATALINA_HOME'] && File.directory?(ENV['CATALINA_HOME']) }
  meet {
    if !ENV['CATALINA_HOME']
      catalina_home = IO.read('/etc/init.d/tomcat6').val_for('CATALINA_HOME').sub('$NAME', 'tomcat6')
      # TODO refactor to shell_helpers
      shell %Q{fish -c 'set -Ux CATALINA_HOME "#{catalina_home}"'}
      ENV['CATALINA_HOME'] = catalina_home # fake it for this session
    end
  }
end

dep 'writable deploy dir' do
  requires 'user in tomcat group', 'tomcat configured'
  met? { File.writable? ENV['CATALINA_HOME'] / 'webapps' }
  meet {
    sudo "chgrp tomcat6 '#{ENV['CATALINA_HOME'] / 'webapps'}'"
    sudo "chmod g+w '#{ENV['CATALINA_HOME'] / 'webapps'}'"
  }
end

dep 'user in tomcat group' do
  requires 'tomcat'
  met? { shell("groups #{var :username}").words.include? 'tomcat6' }
  meet { sudo "usermod -G tomcat6 #{var :username}" }
end

pkg 'tomcat' do
  requires 'jdk'
  installs { apt 'tomcat6' }
  provides []
end

dep 'java build chain' do
  requires 'jdk', pkg('ant')
end

# dep 'java' do
#   setup { requires var(:jdk_or_jre, :default => 'jdk') }
#   after { shell "set -Ux JAVA_HOME /usr/lib/jvm/java-6-sun" }
# end

pkg 'jre' do
  installs { apt 'sun-java6-jre' }
  provides 'java', 'javac'
end

pkg 'jdk' do
  installs { apt 'sun-java6-jdk' }
  provides 'java', 'javac'
end
