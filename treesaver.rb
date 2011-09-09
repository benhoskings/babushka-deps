dep 'treesaver' do
  requires [
    'paver',
    'closure-compiler.managed'
  ]
  
end

dep 'paver' do
  met? { in_path? 'paver' }
  meet { shell 'easy_install Paver' }
end

dep 'closure-compiler.managed' do
  provides 'closure'
end

