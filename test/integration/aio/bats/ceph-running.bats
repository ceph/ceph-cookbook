@test "ceph is running" {
  ceph -s | grep HEALTH
}

@test "ceph is healthy" {
  ceph -s | grep HEALTH_OK
}

@test "cephfs is mounted" {
  mount | grep -E 'type (fuse\.)?ceph'
}

@test "radosgw is running" {
  ps auxwww | grep radosg[w]
}

@test "apache is running and listening" {
  netstat -ln | grep -E '^\S+\s+\S+\s+\S+\s+\S+:80\s+'
}
