meta :rvm do
  template {
    helper :rvm do |args|
      shell "~/.rvm/bin/rvm #{args}", :log => args['install']
    end
  }
end

dep '1.9.2.rvm' do
  requires '1.9.2 installed.rvm'
  met? { login_shell('ruby --version')['ruby 1.9.2p0'] }
  meet { rvm('use 1.9.2 --default') }
end

dep '1.9.2 installed.rvm' do
  requires 'rvm'
  met? { rvm('list')['ruby-1.9.2-p0'] }
  meet { log("rvm install 1.9.2") { rvm 'install 1.9.2'} }
end

dep 'rvm' do
  met? { raw_which 'rvm', login_shell('which rvm') }
  meet { log_shell "Installing rvm using rvm-install-head", 'bash -c "`curl http://rvm.beginrescueend.com/releases/rvm-install-head`"' }
end

meta :rvm_mirror do
  template {
    requires 'rvm'
    helper :urls do
      shell("grep '_url=' ~/.rvm/config/db").split("\n").map {|l|
        l.sub(/^.*_url=/, '')
      }
    end
  }
end

dep 'mirrored.rvm_mirror' do
  define_var :rvm_downloads, :default => '/srv/http/files'
  define_var :rvm_vhost_root, :default => '/srv/http/rvm'
  helper :missing_urls do
    urls.tap {|urls| log "#{urls.length} URLs in the rvm database." }.reject {|url|
      path = var(:rvm_downloads) / File.basename(url)
      path.exists? && !path.empty?
    }.tap {|urls| log "Of those, #{urls.length} aren't present locally." }
  end
  met? { missing_urls.empty? }
  meet {
    in_dir var(:rvm_downloads) do
      missing_urls.each {|url|
        begin
          Babushka::Resource.download url
        rescue StandardError => ex
          log_error ex.inspect
        end
      }
    end
  }
end

dep 'linked.rvm_mirror' do
  requires 'mirrored.rvm_mirror'
  helper :unlinked_urls do
    urls.tap {|urls| log "#{urls.length} URLs in the rvm download pool." }.select {|url|
      path = var(:rvm_downloads) / File.basename(url)
      link = var(:rvm_vhost_root) / url.sub(/^[a-z]+:\/\/[^\/]+\//, '')
      path.exists? && !(link.exists? && link.readlink)
    }.tap {|urls| log "Of those, #{urls.length} aren't symlinked into the vhost." }
  end
  met? { unlinked_urls.empty? }
  meet {
    unlinked_urls.each {|url|
      shell "mkdir -p '#{var(:rvm_vhost_root) / File.dirname(url.sub(/^[a-z]+:\/\/[^\/]+\//, ''))}'"
      log_shell "Linking #{url}", "ln -sf '#{var(:rvm_downloads) / File.basename(url)}' '#{var(:rvm_vhost_root) / url.sub(/^[a-z]+:\/\/[^\/]+\//, '')}'"
    }
  }
  after {
    log urls.map {|url|
      url.scan(/^[a-z]+:\/\/([^\/]+)\//).flatten.first
    }.uniq.reject {|url|
      url[/[:]/]
    }.join(' ')
    log "Those are the domains you should point at #{var(:rvm_vhost_root)}."
  }
end
