@test "ceph is installed from the official repo" {
  cephversion=`apt-cache policy ceph | grep -B 1 ceph.com | head -n 1 | sed 's/^[^0-9]\+\([^ ]\+\).*/\1/'`
  installedversion=`apt-cache policy ceph | grep 'Installed:' | awk '{print $2}'`
  test "$cephversion" = "$installedversion"
}

