def debug_packages(packages)
  packages.map { |x| x + debug_ext }
end

def debug_ext
  case node['platform_family']
  when 'debian'
    '-dbg'
  when 'rhel', 'fedora'
    '-debug'
  else
    ''
  end
end
