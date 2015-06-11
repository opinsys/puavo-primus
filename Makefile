prefix ?= /usr/local
sysconfdir = /etc
installdir = $(prefix)/lib/puavo-primus

RUBY = /usr/bin/ruby2.2
BUNDLE = $(RUBY) /usr/bin/bundle

build:
	$(BUNDLE) install --deployment

update-gemfile-lock: clean
	rm -f Gemfile.lock
	GEM_HOME=.tmpgem $(BUNDLE) install
	rm -rf .tmpgem
	$(BUNDLE) install --deployment

clean:
	rm -rf .bundle vendor

migrate:
	$(BUNDLE) exec sequel -m migrations/ postgres://puavo-primus:password@localhost/puavo-primus

clean-for-install:
		$(BUNDLE) install --deployment --without test
		$(BUNDLE) clean

install: clean-for-install
	mkdir -p $(DESTDIR)$(installdir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	cp -r *.*rb *.ru Gemfile* Makefile i18n lib models  public vendor views .bundle $(DESTDIR)$(installdir)

ansible:
	ansible-playbook  puavo-primus.yml

install-ansible:
	apt-add-repository ppa:ansible/ansible --yes
	apt-get update
	apt-get install -y ansible

install-build-dep:
	mk-build-deps --install debian.default/control \
		--tool "apt-get --yes --force-yes" --remove

deb:
	rm -rf debian
	cp -a debian.default debian
	dpkg-buildpackage -us -uc

server:
	$(BUNDLE) exec puma --port 9595

server-dev:
	$(BUNDLE) exec shotgun --host 0.0.0.0 --port 9595 --server puma

.PHONY: test
test:
	$(BUNDLE) exec $(RUBY) test/all.rb
