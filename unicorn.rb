dep 'unicorn configured', :path do
  requires 'unicorn.gem'
  requires 'unicorn config exists'.with(path)
  requires 'unicorn paths'.with(path)
end

dep 'unicorn.gem' do
  provides %w[unicorn unicorn_rails]
end

dep 'unicorn config exists', :path do
  def unicorn_config
    path / 'config/unicorn.rb'
  end
  def unicorn_socket
    path / 'tmp/sockets/unicorn.socket'
  end
  met? { unicorn_config.exists? }
  meet { render_erb 'unicorn/unicorn.rb.erb', :to => unicorn_config }
end

dep 'unicorn paths', :root do
  def missing_paths
    %w[log tmp/pids tmp/sockets].reject {|p| (root / p).dir? }
  end
  met? { missing_paths.empty? }
  meet { missing_paths.each {|p| (root / p).mkdir } }
end

dep 'unicorn running', :app_root, :env do
  app_root.default('~/current')
  requires 'lsof.managed'
  met? {
    running_count = shell('lsof -U').split("\n").grep(/#{Regexp.escape(app_root / 'tmp/sockets/unicorn.socket')}$/).count
    expected_count = 1 + (app_root / 'config/unicorn.rb').read.val_for('worker_processes').to_i
    (running_count == expected_count).tap {|result|
      log "There #{running_count == 1 ? 'is' : 'are'} #{running_count} unicorn process#{'es' unless running_count == 1} running (1 master + #{running_count - 1} workers).", :as => (:ok if result)
    }
  }
  meet {
    shell "bundle exec unicorn -D -E #{env} -c config/unicorn.rb", :cd => app_root
  }
end
