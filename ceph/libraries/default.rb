def is_crowbar?()
  return defined?(Chef::Recipe::Barclamp) != nil
end
