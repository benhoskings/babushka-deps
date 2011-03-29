meta :logrotate do
  accepts_value_for :renders
  accepts_value_for :as
  template {
    def conf_dest
      "/etc/logrotate.d/#{as}"
    end
    requires 'logrotate.managed'
    met? {
      Babushka::Renderable.new(conf_dest).from?(dependency.load_path.parent / renders)
    }
    meet {
      render_erb renders, :to => conf_dest, :sudo => true
    }
  }
end

dep 'nginx.logrotate' do
  renders "logrotate/nginx.conf"
  as "nginx"
end

dep 'rails.logrotate' do
  renders "logrotate/rails.conf"
  as var(:domain)
end
