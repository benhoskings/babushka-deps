dep 'lamp stack removed', :template => 'apt_packages_removed', :for => :apt do
  removes %r{apache|mysql|php}
end
