# coding: utf-8

dep '☕', :path do
  def to_brew
    Dir.glob(File.join(path, '**/*.coffee')).reject {|coffee|
      js = coffee.sub(/^#{Regexp.escape(path.to_s)}/, 'public/javascripts/').sub(/\.coffee$/, '.js')
      File.exists?(js) && File.mtime(js) > File.mtime(coffee)
    }
  end
  met? {
    (count = to_brew.length).zero?.tap {|result|
      log result ? "☕ Mmmm!" : "Found #{count} unbrewed coffee#{'s' unless count == 1}."
    }
  }
  meet {
    log_shell "Brewing", "coffee --compile --output public/javascripts '#{path}'"
  }
end

dep 'scss built', :path do
  def missing_css
    Dir.glob(File.join(path, '**/*.scss')).reject {|scss|
      scss[/\/_[^\/]+\.scss$/] # Don't try to build _partials.scss
    }.reject {|scss|
      css = scss.sub(/^#{Regexp.escape(path)}/, 'public/stylesheets/').sub(/\.scss$/, '.css')
      File.exists?(css) && File.mtime(css) > File.mtime(scss)
    }
  end
  met? {
    if !missing_css.empty?
      log "There #{missing_css.length == 1 ? 'is' : 'are'} #{missing_css.length} scss file#{'s' unless missing_css.length == 1} to rebuild."
    elsif !shell("grep -ri 'syntax error' public/stylesheets/") {|s| s.stdout.empty? }
      log "There are syntax errors in the scss."
    else
      log_ok "The scss is built."
    end
  }
  meet {
    shell "bundle exec sass --update '#{path}':public/stylesheets" do |shell|
      log_error shell.stdout.split("\n").grep(/error/).map(&:strip).join("\n") unless shell.ok?
    end
  }
end

dep 'untracked assets removed' do
  def to_remove
    existing_sources = Dir.glob('app/{stylesheets,coffeescripts}/**/*')
    existing_assets = shell("git clean -xn -- public/*style* public/*script*").split("\n").collapse(/^Would remove /)
    (existing_assets - existing_sources.map {|path|
      path.
        gsub(/\.coffee$/, '.js'). # .coffee is compiled to .js
        gsub(/\.s[ac]ss$/, '.css'). # .sass and .scss are compiled to .css
        gsub(/^app\/coffeescripts\//, 'public/javascripts/'). # the coffee in app/coffeescripts/ ends up in public/javascripts/
        gsub(/^app\//, 'public/') # and everything else is in the same subpath, within public/ instead of app/.
    })
  end
  met? {
    to_remove.empty?
  }
  meet {
    cached_to_remove = to_remove
    log_shell "Removing:\n#{cached_to_remove.join("\n")}", "rm -f #{cached_to_remove.map {|f| "'#{f}'" }.join(' ')}"
  }
end
