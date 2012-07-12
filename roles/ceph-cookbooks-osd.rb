name "ceph-osd"
description "Ceph Object Storage Device"
run_list(
        'recipe[ceph-cookbooks::bootstrap_osd]'
)
