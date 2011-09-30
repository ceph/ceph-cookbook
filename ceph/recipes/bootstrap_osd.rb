# this recipe bootstraps a simple osd, with help from single_mon

# TODO manage actual disks, handle multiple OSDs per node, etc

include_recipe "ceph::osd"
include_recipe "ceph::conf"

ruby_block 'bootstrap a single (fake) osd' do
  block do
    require 'tempfile'
    require 'open4'

    def subprocess(*args)
      Open4::spawn(args, :stdout=>STDERR, :stderr=>STDERR)
    end

    def get_bootstrap_osd_key()
      nodes = search(:node, 'recipes:ceph\:\:single_mon AND ceph_bootstrap_osd_key:*')
      raise 'No single_mon found.' if nodes.length < 1
      raise 'Too many single_mons found.' if nodes.length > 1
      node = nodes[0]
      key = node["ceph_bootstrap_osd_key"]
      return key
    end

    def ceph_bootstrap_osd(path)
      bootstrap_key = get_bootstrap_osd_key()


      bootstrap_file = Tempfile.new('bootstrap-osd')
      begin
        bootstrap_path = bootstrap_file.path

        monmap = Tempfile.new('monmap')
        begin

          # TODO don't put the key in "ps" output
          subprocess 'cauthtool', bootstrap_path, '--name=client.bootstrap-osd', '--add-key='+bootstrap_key

          osd_id = ''
          Open4::spawn(
                       [
                        'ceph',
                        '-k', bootstrap_path,
                        '-n', 'client.bootstrap-osd',
                        'osd', 'create', '--concise',
                       ],
                       :stdout=>osd_id,
                       :stderr=>STDERR
                       )
          osd_id.chomp!
          raise 'osd id is not numeric' unless /^[0-9]+$/.match(osd_id)

          subprocess(
                      'ceph',
                      '-k', bootstrap_path,
                      '-n', 'client.bootstrap-osd',
                      'mon', 'getmap', '-o', monmap.path
                      )

          Dir.mkdir(path, 0755)

          # TODO fix this to have sane paths
          File.symlink(path, '/srv/osd.'+osd_id)
          subprocess 'cosd', '--mkfs', '--mkkey', '-i', osd_id, '--monmap', monmap.path

        ensure
          monmap.close
          monmap.unlink
        end

        subprocess(
                    'ceph',
                    '--name', 'client.bootstrap-osd',
                    '--keyring', bootstrap_path,
                    'auth', 'add', 'osd.'+osd_id,
                    '-i', '/etc/ceph/osd.'+osd_id+'.keyring',
                    'osd', 'allow *',
                    'mon', 'allow rwx'
                    )

        # TODO default crushmap already contains osd_id=='0'
        if osd_id != '0'
          subprocess(
                     'ceph',
                     '--name', 'client.bootstrap-osd',
                     '--keyring', bootstrap_path,
                     'osd', 'crush', 'add', osd_id, 'osd.'+osd_id,
                     '1',
                     'domain=root'
                     )
        end

      ensure
        bootstrap_file.close
        bootstrap_file.unlink
      end

      File.open('/srv/ceph-fake-osd/done', 'w') { |f|
          f.write('ok')
      }
    end

    if not ::File.exists?('/srv/ceph-fake-osd/done')
      ceph_bootstrap_osd('/srv/ceph-fake-osd')
    end
  end
  notifies :start, "service[ceph-osd-all]"
end
