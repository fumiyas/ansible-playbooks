LIMIT=		*
TAGS=		all
PLAYBOOK=	site.yml

ANSIBLE_PLAYBOOK_PATH=	ansible-playbook
ANSIBLE_OPTS=		-v
ANSIBLE_REMOTE_TEMP=	/tmp/.ansible.$$LOGNAME@`hostname`.tmp

ANSIBLE_PLAYBOOK_CMD=\
  $(ANSIBLE_PLAYBOOK_PATH) \
    $(ANSIBLE_OPTS) \
    --limit="$(LIMIT)" \
    --tags="$(TAGS)" \
    "$(PLAYBOOK)"

## ----------------------------------------------------------------------

VAGRANT_PATH=		vagrant

## ======================================================================

default: usage

.PHONY: default

-include Makefile.hosts
-include Makefile.local

## ======================================================================

usage:
	@echo "Configuration management by Ansible"
	@echo "  Usage: $(MAKE) <staging|production>"
	@echo
	@echo "VM management for staging environment by Vagrant and VirtualBox"
	@echo "  Usage: $(MAKE) <up|down|restart|suspend|resume|status|destroy>"

clean:
	rm -rf $(PLAYBOOK:.yml=.retry) Makefile.hosts tmp */*.tmp staging/ssh_config

distclean: destroy clean

.PHONY: usage clean distclean

## Configuration management
## ======================================================================

staging:: staging/ssh_config

staging production::
	$(MAKE) play \
	  ANSIBLE_CONFIG="$@/ansible.cfg" \
	  ANSIBLE_INVENTORY="$@/inventory.ini" \
	  ANSIBLE_REMOTE_TEMP="$(ANSIBLE_REMOTE_TEMP)" \
	  ANSIBLE_PLAYBOOK_CMD="$(ANSIBLE_PLAYBOOK_CMD)" \

play:
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_INVENTORY='$(ANSIBLE_INVENTORY)' \
	ANSIBLE_REMOTE_TEMP="$(ANSIBLE_REMOTE_TEMP)" \
	  $(ANSIBLE_PLAYBOOK_CMD)

staging/ssh_config: .vagrant/machines/*/*/*
	: >$@.tmp
	for host in `$(VAGRANT_PATH) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  set -- $(VAGRANT_PATH) ssh-config $$host; \
	  echo "$$*"; \
	  "$$@" >>$@.tmp || exit 1; \
	done
	mv $@.tmp $@

.vagrant/machines/*/*/*: up

.PHONY: staging production

## VM management
## ======================================================================

up halt reload suspend resume status::
	$(VAGRANT_PATH) $@

up:: Makefile.hosts

destroy:
	$(VAGRANT_PATH) $@ --force
	rm -rf .vagrant

down: halt

restart: reload

Makefile.hosts: staging/group_vars/all/hosts.yml
	: >$@.tmp
	for host in `$(VAGRANT_PATH) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  for cmd in up halt reload suspend resume destroy status ssh ssh-config port rdp; do \
	    echo "$$cmd.$$host:"; \
	    echo '	$$(VAGRANT_PATH) '"$$cmd $$host"; \
	  done; \
	  echo "down.$$host:"; \
	  echo '	$$(VAGRANT_PATH) '"halt $$host"; \
	done >$@.tmp
	mv $@.tmp $@

.PHONY: up halt down reload suspend resume destroy status

