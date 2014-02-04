name "ceph-tgt"
description "Ceph iSCSI Target"
run_list(
        'recipe[ceph::repo]',
        'recipe[ceph::tgt]'
)
