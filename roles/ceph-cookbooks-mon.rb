name "ceph-cookbooks-mon"
description "Ceph Monitor"
run_list(
        'recipe[ceph-cookbooks::mon]'
)
