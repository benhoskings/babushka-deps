dep 'unicorn configured' do
  requires 'unicorn.gem', 'unicorn config exists.nginx'
end

dep 'unicorn.gem' do
  provides %w[unicorn unicorn_rails]
end

dep 'unicorn config exists.nginx' do
  def unicorn_config
    var(:app_root) / 'config/unicorn.rb'
  end
  met? { Babushka::Renderable.new(unicorn_config).from?(dependency.load_path.parent / "unicorn/unicorn.rb.erb") }
  meet { render_erb 'unicorn/unicorn.rb.erb', :to => unicorn_config }
end
