name "ceph-mds"
description "Ceph Metadata Server"
run_list(
        'recipe[ceph::repo]',
        'recipe[ceph::mds]'
)
