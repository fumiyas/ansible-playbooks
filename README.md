My Ansible playbooks
======================================================================

  * Copyright (c) 2015 SATOH Fumiyasu @ OSS Technology Corp., Japan
  * License: GPLv3
  * URL: <https://GitHub.com/fumiyas/ansible-playbooks>
  * Twitter: <https://twitter.com/satoh_fumiyasu>

NOTE: Ansible 2.0+ required

How to use
----------------------------------------------------------------------

Copy the example inventory and vars files for staging environment:

```console
$ cp -rp staging.example staging
```

Customize hosts definition and inventory files:

```console
$ vi staging/group_vars/all/hosts.yml
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
...
```

