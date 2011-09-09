dep 'osx supervisor' do
  met? { in_path? 'supervisord' }
  meet {
    Babushka::Resource.extract 'http://pypi.python.org/packages/source/s/supervisor/supervisor-3.0a9.tar.gz' do
      log_shell "Installing supervisor", "python setup.py install"
    end
  }
end
