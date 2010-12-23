dep 'hudson' do
  requires [
    'installed.hudson',
    'cli.hudson',
    'git.hpi', 'github.hpi', 'ruby.hpi', 'rake.hpi'
  ]
end

dep 'installed.hudson' do
  def path
    '~/hudson'.p
  end
  requires 'tomcat.managed'
  met? { (path / 'hudson.war').exists? }
  meet {
    in_dir path, :create => true do
      shell 'wget http://hudson-ci.org/latest/hudson.war'
    end
  }
end

dep 'cli.hudson' do
  met? { (path / 'hudson-cli.jar').exists? }
  meet {
    in_dir path :create => true do
      shell 'jar -xf hudson.war WEB-INF/hudson-cli.jar'
      shell 'mv WEB-INF/hudson-cli.jar .'
      shell 'rmdir WEB-INF'
    end
  }
end

meta :hpi do
  accepts_value_for :name
  template {
    met? {
      "~/.hudson/plugins/#{name}".p.exists?
    }
    meet {
      Resource.get "http://hudson-ci.org/latest/#{name}" do |hpi|
        shell "java -jar ~/hudson/hudson-cli.jar -s http://localhost:8080/ install-plugin #{hpi}"
      end
    }
  }
end

dep 'tomcat.managed' do
  provides %w[catalina.sh startup.sh shutdown.sh]
end

dep 'git.hpi'
dep 'github.hpi'
dep 'ruby.hpi'
dep 'rake.hpi'
