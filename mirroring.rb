dep 'mirror has assets' do
  define_var :mirror_domain, :default => L{ "http://#{var(:mirror_path).p.basename}" }
  helper :assets do
    var(:mirror_path).p.glob("**/*").select {|f|
      f[/\.(html?|css)$/i]
    }.map {|f|
      f.p.read.scan(/url\(['"]?([^)'"]+)['"]?\)/).map {|url|
        url.starts_with?('/') ? url : (f.p.dirname / url).to_s.gsub(/^#{Regexp.escape(var(:mirror_path).p.to_s)}/, '')
      }
    }.flatten
  end
  helper :nonexistent_assets do
    assets.reject {|asset|
      (var(:mirror_path) / asset).exists? && !(var(:mirror_path) / asset).empty?
    }
  end
  met? { nonexistent_assets.empty? }
  meet {
    nonexistent_assets.each {|asset|
      shell "mkdir -p '#{var(:mirror_path) / asset.p.dirname}'"
      log_shell "Downloading #{asset}", "wget -O '#{var(:mirror_path) / asset}' '#{File.join var(:mirror_domain), asset}'"
    }
  }
end
