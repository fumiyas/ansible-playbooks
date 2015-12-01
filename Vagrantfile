# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'pathname'

NOW = Time.now

VAGRANT_VARS = YAML.load_file('staging/group_vars/all/vagrant.yml')['vagrant']

VAGRANT_NETWORK = VAGRANT_VARS['network']
VM_NAME_PREFIX = VAGRANT_VARS['vm']['name_prefix'] || Pathname.new(Dir.pwd).split[-1] + '_'
VM_NAME_SUFFIX = VAGRANT_VARS['vm']['name_suffix'] || ".%Y%m%d.%H%M%S.#{Process.pid}"
VM_BOX = VAGRANT_VARS['vm']['box']
VM_NETWORKS = VAGRANT_VARS['vm']['networks'] || {'name' => 'vagrant'}

HOSTS_VARS = YAML.load_file('staging/group_vars/all/hosts.yml')['hosts']

Vagrant.configure(2) do |config|
  config.vm.provider(:virtualbox) do |vbox|
    vbox.customize(['modifyvm', :id, '--natnet1', VAGRANT_NETWORK])
    vbox.customize(['modifyvm', :id, '--natdnsproxy1', 'off'])
  end

  HOSTS_VARS.each do |name, host|
    config.vm.define(name) do |node|
      node.vm.box = host['vagrant_box'] || VM_BOX
      node.vm.hostname = host['hostname']
      ## FIXME: Multiple network support
      node.vm.network(
	:private_network,
	virtualbox__intnet:host['networks'][0]['name'] || VM_NETWORKS[0]['name'],
	ip:host['networks'][0]['address'],
	netmask:host['networks'][0]['netmask'] || '255.255.255.0'
      )

      node.vm.synced_folder('.', '/vagrant', disabled: true)

      node.vm.provider(:virtualbox) do |vbox|
	vbox.name = NOW.strftime(VM_NAME_PREFIX) + name + NOW.strftime(VM_NAME_SUFFIX)
	vbox.cpus = host['cpus'] || 1
	vbox.memory = host['memory'] || 512
	2.upto(4) do |n|
	  vbox.customize(["modifyvm", :id, "--nictype" + n.to_s, "virtio" ])
	end
      end
    end
  end
end

