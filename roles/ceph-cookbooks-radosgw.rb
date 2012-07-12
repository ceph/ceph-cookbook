name "ceph-cookbooks-radosgw"
description "Ceph RADOS Gateway"
run_list(
        'recipe[ceph-cookbooks::radosgw]'
)
