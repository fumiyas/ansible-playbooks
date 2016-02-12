# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'pathname'

Vagrant.configure(2) do |config|
  now = Time.now

  vagrant_vars = YAML.load_file('staging/group_vars/all/vagrant.yml')['vagrant']
  hosts_vars = YAML.load_file('staging/group_vars/all/hosts.yml')['hosts']

  vagrant_network = vagrant_vars['network']
  vm_name_prefix = vagrant_vars['vm']['name_prefix'] || Pathname.new(Dir.pwd).split[-1] + '_'
  vm_name_suffix = vagrant_vars['vm']['name_suffix'] || ".%Y%m%d.%H%M%S.#{Process.pid}"
  vm_box = vagrant_vars['vm']['box']
  vm_networks = vagrant_vars['vm']['networks'] || {'name' => 'vagrant'}

  config.vm.provider(:virtualbox) do |vbox|
    vbox.customize(['modifyvm', :id, '--natnet1', vagrant_network])
    vbox.customize(['modifyvm', :id, '--natdnsproxy1', 'off'])
  end

  hosts_vars.each do |name, host|
    config.vm.define(name) do |node|
      node.vm.box = host['vagrant_box'] || vm_box
      node.vm.hostname = host['hostname']
      ## FIXME: Multiple network support
      node.vm.network(
	:private_network,
	virtualbox__intnet:host['networks'][0]['name'] || vm_networks[0]['name'],
	ip:host['networks'][0]['address'],
	netmask:host['networks'][0]['netmask'] || '255.255.255.0'
      )

      node.vm.synced_folder('.', '/vagrant', disabled: true)

      node.vm.provider(:virtualbox) do |vbox|
	vbox.name = now.strftime(vm_name_prefix) + name + now.strftime(vm_name_suffix)
	vbox.cpus = host['cpus'] || 1
	vbox.memory = host['memory'] || 512
	2.upto(4) do |n|
	  vbox.customize(["modifyvm", :id, "--nictype" + n.to_s, "virtio" ])
	end
      end
    end
  end
end

