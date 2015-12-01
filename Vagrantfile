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

HOSTS_VARS = YAML.load_file('staging/group_vars/all/hosts.yml')['hosts']

Vagrant.configure(2) do |config|
  config.vm.provider(:virtualbox) do |vbox|
    vbox.customize(['modifyvm', :id, '--natnet1', VAGRANT_NETWORK])
    vbox.customize(['modifyvm', :id, '--natdnsproxy1', 'off'])
  end

  HOSTS_VARS.each do |host|
    config.vm.define(host['name']) do |node|
      node.vm.box = host['vagrant_box'] || VM_BOX
      node.vm.hostname = host['hostname']
      node.vm.network(
	:private_network,
	ip:host['ips'][0]['address'],
	netmask:host['ips'][0]['netmask'] || '255.255.255.0'
      )

      node.vm.synced_folder('.', '/vagrant', disabled: true)

      node.vm.provider(:virtualbox) do |vbox|
	vbox.name = NOW.strftime(VM_NAME_PREFIX) + host['name'] + NOW.strftime(VM_NAME_SUFFIX)
	vbox.cpus = host['cpus'] || 1
	vbox.memory = host['memory'] || 512
      end
    end
  end
end

