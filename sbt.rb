dep 'sbt' do
  requires 'java.managed'
  merge :versions, :sbt => '0.5.4'
  met? { which 'sbt' }
  meet {
    cd var(:install_path, :default => '/usr/local') do
      cd 'lib/sbt', :create => true do
        download "http://simple-build-tool.googlecode.com/files/sbt-launcher-#{var(:versions)[:sbt]}.jar"
        shell "ln -sf sbt-launcher-#{var(:versions)[:sbt]}.jar sbt-launcher.jar"
      end
      cd 'bin' do
        shell %Q{echo '#!/bin/bash\njava -Xmx512M -jar `dirname $0`/../lib/sbt/sbt-launcher.jar "$@"' > sbt}
        shell 'chmod +x sbt'
      end
    end
  }
end
