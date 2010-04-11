dep 'mirror has assets' do
  helper :assets do
    var(:mirror_path).p.glob("**/*").select {|f|
      f[/\.(html?|css)$/i]
    }.map {|f|
      f.p.read.scan(/url\(['"]?([^)'"]+)['"]?\)/).map {|url|
        url.starts_with?('/') ? url : (f.p.dirname / url).to_s.gsub('/Users/ben/projects/corkboard/current/public', '')
      }
    }.flatten
  end
  helper :nonexistent_assets do
    assets.reject {|asset|
      (var(:mirror_path) / asset).exists?
    }
  end
  met? { nonexistent_assets.empty? }
  meet {
    nonexistent_assets.each {|asset|
      shell "mkdir -p '#{var(:mirror_path) / asset.p.dirname}"
      log_shell "Downloading #{asset}", "wget -O '#{var(:mirror_path) / asset}' '#{asset}'"
    }
  }
end
