name "ceph-cookbooks-mds"
description "Ceph Metadata Server"
run_list(
        'recipe[ceph-cookbooks::mds]'
)
