My Ansible playbooks
======================================================================

  * Copyright (c) 2015 SATOH Fumiyasu @ OSS Technology Corp., Japan
  * License: GPLv3
  * URL: <https://GitHub.com/fumiyas/ansible-playbooks>
  * Twitter: <https://twitter.com/satoh_fumiyasu>

Requirements
----------------------------------------------------------------------

  * Ansible 2.0+
    * Not yet released, tested on Ansible 2.0.0rc1
  * Vagrant
    * For staging environment, tested on Vagrant 1.7.4
  * VirtualBox 
    * For staging environment, tested on VirtualBox 5.0.10

How to use
----------------------------------------------------------------------

Customize hosts definition and inventory files:

```console
$ vi staging/group_vars/all/hosts.yml
...
$ vi staging/host_vars/*/*.yml
...
$ vi staging/inventory.ini
...
```

Invoke VM(s) by Vagrant:

```console
$ make up
...
```

Provision by Ansible:

```console
$ make staging
...
```

Login to the OS in the VM via SSH through Vagrant:

```console
$ vagrant ssh ldap-master1
$ vagrant ssh ldap-master2
$ vagrant ssh ldap-slave1
```

Discard VMs:

```console
$ make destroy
...
```

TODO
----------------------------------------------------------------------

  * Add more roles
  * Support Deiban and Ubuntu
  * Support other VM softwares (e.g., KVM, VMware)

