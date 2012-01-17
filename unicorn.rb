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
    %w[log tmp/pids tmp/sockets].reject {|p| File.directory?(p) }
  end
  met? { missing_paths.empty? }
  meet { missing_paths.each {|p| (root / p).mkdir } }
end
