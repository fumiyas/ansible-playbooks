LIMIT=		*
TAGS=		all
PLAYBOOK=	site.yml

ANSIBLE=	ansible-playbook
ANSIBLE_OPTS=	-v
ANSIBLE_REMOTE_TEMP=/tmp/.ansible.$$LOGNAME@`hostname`.tmp

ANSIBLE_CMD=\
  $(ANSIBLE) \
    $(ANSIBLE_OPTS) \
    --limit="$(LIMIT)" \
    --tags="$(TAGS)" \
    "$(PLAYBOOK)"

## ----------------------------------------------------------------------

VAGRANT=	vagrant

## ----------------------------------------------------------------------

DIFF=		diff
DIFF_EDITOR=	vimdiff

DIFF_CMD=	LC_ALL=C $(DIFF)
DIFF_RECURSE=	$(DIFF_CMD) -upr -x tmp -x ssh_config staging production

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
	rm -rf $(PLAYBOOK:.yml=.retry) Makefile.hosts */tmp */*.tmp staging/ssh_config

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
	  ANSIBLE_CMD="$(ANSIBLE_CMD)" \

play:
	ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ANSIBLE_INVENTORY='$(ANSIBLE_INVENTORY)' \
	ANSIBLE_REMOTE_TEMP="$(ANSIBLE_REMOTE_TEMP)" \
	  $(ANSIBLE_CMD)

staging/ssh_config: .vagrant/machines/*/*/*
	@: >$@.tmp
	@for host in `$(VAGRANT) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  set -- $(VAGRANT) ssh-config $$host; \
	  echo "$$*"; \
	  "$$@" >>$@.tmp || exit 1; \
	done
	@mv $@.tmp $@

.vagrant/machines/*/*/*: up

.PHONY: staging production

## VM management
## ======================================================================

up halt reload suspend resume status::
	$(VAGRANT) $@

up:: Makefile.hosts

destroy:
	$(VAGRANT) $@ --force
	rm -rf .vagrant

down: halt

restart: reload

Makefile.hosts: Makefile staging/group_vars/all/hosts.yml
	@: >$@.tmp
	@for host in `$(VAGRANT) status |sed -n '3,/^$$/{s/ *running .*//p}'`; do \
	  for cmd in up halt reload suspend resume destroy status ssh ssh-config port rdp; do \
	    echo "$$cmd.$$host:"; \
	    echo '	$$(VAGRANT) '"$$cmd $$host"; \
	  done; \
	  echo "down.$$host:"; \
	  echo '	$$(VAGRANT) '"halt $$host"; \
	done >$@.tmp
	@mv $@.tmp $@

.PHONY: up halt down reload suspend resume destroy status

## ======================================================================

diff:
	@$(DIFF_RECURSE); true

difflist:
	@$(DIFF_RECURSE) \
	|sed -n \
	  -e 's|^diff .* [^/]*/|*/|p' \
	  -e 's|^Only in [^/]*/\(.*\): \(\)|*/\1/\2|p' \
	; true

diffedit:
	@for f in `$(DIFF_RECURSE) |sed -n 's/^diff .* //p'`; do \
	  $(DIFF_EDITOR) "staging/$${f#*/}" "$$f" || break; \
	done

.PHONY: diff difflist diffedit

