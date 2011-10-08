dep 'unicorn configured', :path do
  requires 'unicorn.gem', 'unicorn config exists'.with(path)
end

dep 'unicorn.gem' do
  provides %w[unicorn unicorn_rails]
end

dep 'unicorn config exists', :path do
  def unicorn_config
    path / 'config/unicorn.rb'
  end
  met? { unicorn_config.exists? }
  meet { render_erb 'unicorn/unicorn.rb.erb', :to => unicorn_config }
end
