dep 'unicorn configured', :path do
  requires 'unicorn.gem', 'unicorn config exists.nginx'.with(path)
end

dep 'unicorn.gem' do
  provides %w[unicorn unicorn_rails]
end

dep 'unicorn config exists.nginx', :path do
  def unicorn_config
    path / 'config/unicorn.rb'
  end
  met? { Babushka::Renderable.new(unicorn_config).from?(dependency.load_path.parent / "unicorn/unicorn.rb.erb") }
  meet { render_erb 'unicorn/unicorn.rb.erb', :to => unicorn_config }
end
