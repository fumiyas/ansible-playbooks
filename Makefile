ANSIBLE_PLAYBOOK_PATH=	ansible-playbook
ANSIBLE_PLAYBOOK_YAML=	site.yml

ANSIBLE_LIMIT=		*
ANSIBLE_OPTS=		-v
ANSIBLE_STAGING_OPTS=
ANSIBLE_PRODUCTION_OPTS=--ask-become-pass

ANSIBLE_REMOTE_TEMP=	/tmp/.ansible.$$LOGNAME@`hostname`.tmp

ANSIBLE_PLAYBOOK_CMD=	ANSIBLE_REMOTE_TEMP="$(ANSIBLE_REMOTE_TEMP)" \
			$(ANSIBLE_PLAYBOOK_PATH) $(ANSIBLE_OPTS)

VAGRANT=		vagrant

## ======================================================================

-include Makefile.hosts
-include Makefile.local

## ======================================================================

.PHONY: default usage clean distclean

default: usage

usage:
	@echo "CMS by Ansible"
	@echo "  Usage: $(MAKE) <staging|production>"
	@echo
	@echo "VM management for staging environment by Vagrant and VirtualBox"
	@echo "  Usage: $(MAKE) <up|down|suspend|resume|status|destroy>"

clean:
	rm -f Makefile.hosts */*.tmp staging/ssh_config

distclean: destroy clean

## CMS
## ======================================================================

.PHONY: staging production

production::
	ANSIBLE_CONFIG=production/ansible.cfg \
	$(ANSIBLE_PLAYBOOK_CMD) \
	$(ANSIBLE_PRODUCTION_OPTS) \
	  --inventory=production/inventory.ini \
	  --limit='$(ANSIBLE_LIMIT)' \
	  $(ANSIBLE_PLAYBOOK_YAML)

staging:: staging/ssh_config
	ANSIBLE_CONFIG=staging/ansible.cfg \
	$(ANSIBLE_PLAYBOOK_CMD) \
	$(ANSIBLE_STAGING_OPTS) \
	  --inventory=staging/inventory.ini \
	  --limit='$(ANSIBLE_LIMIT)' \
	  $(ANSIBLE_PLAYBOOK_YAML)

staging/ssh_config: .vagrant/machines/*/*/*
	: >$@.tmp
	for host in `$(VAGRANT) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  set -- $(VAGRANT) ssh-config $$host; \
	  echo "$$*"; \
	  "$$@" >>$@.tmp || exit 1; \
	done
	mv $@.tmp $@

## VM management
## ======================================================================

.PHONY: up halt down suspend resume destroy status

up halt suspend resume status::
	$(VAGRANT) $@

up:: Makefile.ssh

destroy:
	$(VAGRANT) $@ --force
	rm -rf .vagrant

down: halt

Makefile.hosts: staging/group_vars/all/hosts.yml
	: >$@.tmp
	for host in `$(VAGRANT) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  for cmd in up down status destroy; do \
	    echo "$$cmd.$$host:"; \
	    echo '	$$(VAGRANT) '"$$cmd $$host"; \
	  done; \
	done >$@.tmp
	mv $@.tmp $@

