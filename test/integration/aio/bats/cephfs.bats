@test "/recipe_ceph is mounted" {
  grep -q -E '^\S+\s+/recipe_ceph\s+' /proc/mounts
}

@test "/ceph is mounted" {
  grep -q -E '^\S+\s+/ceph\s+' /proc/mounts
}
@test "/ceph.fuse is mounted" {
  grep -q -E '^\S+\s+/ceph\.fuse\s+fuse' /proc/mounts
}
@test "/ceph.fstab is mounted" {
  grep -q -E '^\S+\s+/ceph\.fstab\s+fuse' /proc/mounts
}

@test "/ceph is in fstab" {
  grep -q -E '^\S+\s+/ceph\s+\S+\s+\S*_netdev\S*\s' /etc/fstab
}
@test "/ceph.fuse is NOT in fstab" {
  grep -v -q -E '^\S+\s+/ceph.fuse\s+' /etc/fstab
}
@test "/ceph.fstab is in fstab" {
  grep -q -E '^\S+\s+/ceph.fstab\s+\S+\s+\S*_netdev\S*\s' /etc/fstab
}

@test "test file exists in /ceph" {
  test -e /ceph/subdir/file
  grep -q 'It works' /ceph/subdir/file
}
@test "test file exists in /ceph.fuse" {
  test -e /ceph.fuse/subdir/file
  grep -q 'It works' /ceph.fuse/subdir/file
}

# if we are using kernel cephfs
if grep -q -E '^\S+\s+/ceph\s+ceph' /proc/mounts; then
  @test "/subceph is mounted" {
    grep -q -E '^\S+\s+/subceph\s+ceph' /proc/mounts
  }
  @test "/subceph is NOT in fstab" {
    grep -v -q -E '^\S+\s+/subceph\s+' /etc/fstab
  }
  @test "test file exists in /subceph" {
    test -e /subceph/file
    grep -q 'It works' /subceph/file
  }
fi

