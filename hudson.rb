dep 'tomcat.managed'

dep 'hudson' do
  requires 'tomcat.managed'
  met? {
    result = shell('dpkg -s hudson')
    result && result['Status: install ok installed']
  }
  meet {
    shell 'wget -O /tmp/hudson-apt-key http://hudson-ci.org/debian/hudson-ci.org.key'
    sudo 'apt-key add /tmp/hudson-apt-key'
    shell 'wget -O /tmp/hudson.dep http://hudson-ci.org/latest/debian/hudson.deb'
    sudo 'dpkg --install /tmp/hudson.dep'
  }
end

dep 'hudson plugins for rails' do
  requires [
    'hudson',
    'hudson cli',
    'git.hpi', 'github.hpi', 'ruby.hpi', 'rake.hpi',
    'restart hudson'
  ]
end

dep 'restart hudson' do
  met? { @restarted }
  meet {
    sudo '/etc/init.d/hudson stop'
    30.times {
      response = sudo('/etc/init.d/hudson start')
      if response && !response.include?("The selected http port (8080) seems to be in use by another program")
        @restarted = true
        break
      else
        sleep 1
      end
    }
  }
end

dep 'hudson cli' do
  met? {
    "/usr/share/hudson/hudson-cli.jar".p.exists?
  }
  meet {
    in_dir '/usr/share/hudson' do
      sudo 'jar -xf hudson.war WEB-INF/hudson-cli.jar'
      sudo 'mv WEB-INF/hudson-cli.jar .'
      sudo 'rmdir WEB-INF'
    end
  }
  after {
    in_dir '/usr/share/hudson' do
      30.times {
        response = shell 'java -jar hudson-cli.jar -s http://localhost:8080/ version'
        break if response && response =~ /^\d+(\.\d+)*$/
        sleep 1
      }
    end
  }
end


meta :hpi do
  accepts_value_for :name
  template {
    met? {
      "/var/lib/hudson/plugins/#{name}".p.exists?
    }
    meet {
      in_dir '/usr/share/hudson' do
        shell "wget -O /tmp/#{name} http://hudson-ci.org/latest/#{name}"
        shell "java -jar hudson-cli.jar -s http://localhost:8080/ install-plugin /tmp/#{name}"
      end
    }
  }
end

dep 'git.hpi'
dep 'github.hpi'
dep 'ruby.hpi'
dep 'rake.hpi'
