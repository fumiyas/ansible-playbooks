ANSIBLE_PLAYBOOK_PATH=	ansible-playbook
ANSIBLE_OPTS=		-v
ANSIBLE_REMOTE_TEMP=	/tmp/.ansible.$$LOGNAME@`hostname`.tmp
ANSIBLE_PLAYBOOK_YAML=	site.yml

ANSIBLE_PLAYBOOK_CMD=	ANSIBLE_REMOTE_TEMP="$(ANSIBLE_REMOTE_TEMP)" \
			$(ANSIBLE_PLAYBOOK_PATH) $(ANSIBLE_OPTS)

VAGRANT=		vagrant

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
	rm -f */*.tmp staging/ssh_config
	[ -L staging ] && rm staging

distclean: destroy clean

## CMS
## ======================================================================

.PHONY: staging production

staging::
	[ -d staging ] || ln -s staging.example staging

staging:: staging/ssh_config

staging production::
	ANSIBLE_CONFIG=$@/ansible.cfg \
	$(ANSIBLE_PLAYBOOK_CMD) -i $@/inventory.ini $(ANSIBLE_PLAYBOOK_YAML)

staging/ssh_config:
	$(VAGRANT) ssh-config >$@.tmp
	mv $@.tmp $@

## VM management
## ======================================================================

.PHONY: up halt down suspend resume destroy status

up halt suspend resume status:
	$(VAGRANT) $@

destroy:
	$(VAGRANT) $@ --force
	rm -rf .vagrant

down: halt

