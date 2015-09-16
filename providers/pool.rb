#
# Cookbook Name:: ceph
# Provider:: pool
#
# Author:: Sergio de Carvalho <scarvalhojr@users.noreply.github.com>
#

def whyrun_supported?
  true
end

use_inline_resources

action :create do
  if @current_resource.exists
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    converge_by("Creating #{@new_resource}") do
      create_pool
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Deleting #{@new_resource}") do
      delete_pool
    end
  else
    Chef::Log.info "#{@current_resource} does not exist - nothing to do."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephPool.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = pool_exists?(@current_resource.name)
end

def create_pool
  cmd_text = "ceph osd pool create #{new_resource.name} #{new_resource.pg_num}"
  cmd_text << " #{new_resource.create_options}" if new_resource.create_options
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool created: #{cmd.stderr}"
end

def delete_pool
  cmd_text = "ceph osd pool delete #{new_resource.name}"
  cmd_text << " #{new_resource.name} --yes-i-really-really-mean-it" if
    new_resource.force
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool deleted: #{cmd.stderr}"
end

def pool_exists?(name)
  cmd = Mixlib::ShellOut.new("ceph osd pool get #{name} size")
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool exists: #{cmd.stdout}"
  true
rescue
  Chef::Log.debug "Pool doesn't seem to exist: #{cmd.stderr}"
  false
end
