@test "ceph is running" {
  ceph -s | grep HEALTH
}

@test "ceph is healthy" {
  ceph -s | grep HEALTH_OK
}
