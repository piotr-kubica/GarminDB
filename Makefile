#
# This Makefile handles downloading data from Garmin Connect and generating SQLite DB files from that data. The Makefile targets handle the dependaancies
# between downloading and geenrating varies types of data. It wraps the core Python scripts and runs them with appropriate parameters.
#
export PROJECT_BASE=$(CURDIR)

include defines.mk


#
# Master targets
#
all: update_dbs

# install all needed code
setup_repo: $(CONF_DIR)/GarminConnectConfig.json $(PROJECT_BASE)/.venv submodules_update

setup_install: deps devdeps install_all

setup: setup_repo setup_install

setup_pipeline: devdeps install_all

clean_dbs: clean_mshealth_db clean_fitbit_db clean_garmin_dbs

# Use for an intial download or when the start dates have been changed.
download_all: download_all_garmin

# build dbs from already downloaded data files
build_dbs: build_garmin mshealth fitbit
create_dbs: garmin mshealth fitbit
create_copy_dbs: copy_garmin mshealth fitbit

# delete the exisitng dbs and build new dbs from already downloaded data files
rebuild_dbs: rebuild_fitbit rebuild_mshealth rebuild_garmin

# update the exisitng dbs by downloading data files for dates after the last in the dbs and update the dbs
update_dbs: update_garmin
update_dbs_bin: update_garmin_bin
update_copy_dbs: copy_garmin_latest


#
# Project maintainance targets
#
SUBMODULES=Fit Tcx utilities
SUBDIRS=fitbitdb garmindb healthdb mshealthdb

$(CONF_DIR):
	mkdir $(CONF_DIR)

$(CONF_DIR)/GarminConnectConfig.json: $(CONF_DIR)
	cp $(PROJECT_BASE)/garmindb/GarminConnectConfig.json.example $(CONF_DIR)/GarminConnectConfig.json

$(PROJECT_BASE)/.venv:
	$(PYTHON) -m venv --upgrade-deps $(PROJECT_BASE)/.venv
	source $(PROJECT_BASE)/.venv/bin/activate

update: submodules_update
	git pull --rebase

submodules_update:
	git submodule init
	git submodule update

$(SUBMODULES:%=%-install):
	$(MAKE) -C $(subst -install,,$@) install

publish_check: build
	$(PYTHON) -m twine check dist/*

publish: clean publish_check
	$(PYTHON) -m twine upload dist/* --verbose

build: devdeps
	$(PYTHON) -m build

$(PROJECT_BASE)/dist/$(MODULE)-*.whl: build

install: $(PROJECT_BASE)/dist/$(MODULE)-*.whl
	$(PIP) install --upgrade $(PROJECT_BASE)/dist/$(MODULE)-*.whl

reinstall: $(PROJECT_BASE)/dist/$(MODULE)-*.whl
	$(PIP) install --upgrade --force-reinstall --no-deps $(PROJECT_BASE)/dist/$(MODULE)-*.whl

install_all: $(SUBMODULES:%=%-install) install

$(SUBMODULES:%=%-uninstall):
	$(MAKE) -C $(subst -uninstall,,$@) uninstall

uninstall:
	$(PIP) uninstall -y $(MODULE)

uninstall_all: uninstall $(SUBMODULES:%=%-uninstall)

reinstall_all: uninstall_all install_all

republish_plugins:
	$(MAKE) -C Plugins republish_plugins

$(SUBMODULES:%=%-deps):
	$(MAKE) -C $(subst -deps,,$@) deps

pip_upgrade:
	$(PIP) install --upgrade pip

deps: pip_upgrade $(SUBMODULES:%=%-deps)
	$(PIP) install --upgrade --requirement requirements.txt

$(SUBMODULES:%=%-devdeps):
	$(MAKE) -C $(subst -devdeps,,$@) devdeps

devdeps: $(SUBMODULES:%=%-devdeps)
	$(PIP) install --upgrade --requirement dev-requirements.txt

$(SUBMODULES:%=%-remove_deps):
	$(MAKE) -C $(subst -remove_deps,,$@) remove_deps

remove_deps: $(SUBMODULES:%=%-remove_deps)
	$(PIP) uninstall -y --requirement requirements.txt
	$(PIP) uninstall -y --requirement dev-requirements.txt

clean_deps: remove_deps

$(SUBMODULES:%=%-clean):
	$(MAKE) -C $(subst -clean,,$@) clean

$(SUBDIRS:%=%-clean):
	rm -f garmindb/$(subst -clean,,$@)/*.pyc
	rm -rf garmindb/$(subst -clean,,$@)/__pycache__

clean: $(SUBMODULES:%=%-clean) $(SUBDIRS:%=%-clean) test_clean
	rm -f *.pyc
	rm -f *.log
	rm -f scripts/*.log
	rm -f Jupyter/*.log
	rm -f *.spec
	rm -f *.zip
	rm -f *.png
	rm -f *stats.txt
	rm -f scripts/*stats.txt
	rm -f Jupyter/*stats.txt
	rm -rf __pycache__
	rm -rf *.egg-info
	rm -rf build
	rm -rf dist

graphs:
	garmindb_graphs.py --all

graph_yesterday:
	garmindb_graphs.py --day $(YESTERDAY)

checkup: update_garmin
	garmindb_checkup.py --battery
	garmindb_checkup.py --goals

# define CHECKUP_COURSE_ID in my-defines.mk
checkup_course:
	garmin_checkup.py --course $(CHECKUP_COURSE_ID)

daily: all checkup graph_yesterday

#
# Garmin targets
#
backup:
	garmindb_cli.py --backup

download_all_garmin:
	garmindb_cli.py --all --download

redownload_garmin_activities:
	garmindb_cli.py --activities --download --overwrite

garmin:
	garmindb_cli.py --all --download --import --analyze

build_garmin:
	garmindb_cli.py --all --import --analyze

rebuild_garmin:
	garmindb_cli.py --rebuild_db

build_garmin_monitoring:
	garmindb_cli.py --monitoring --import --analyze

build_garmin_activities:
	garmindb_cli.py --activities --import --analyze

copy_garmin_settings:
	garmindb_cli.py --copy

copy_garmin:
	garmindb_cli.py --all --copy --import --analyze

update_garmin:
	garmindb_cli.py --all --download --import --analyze --latest

copy_garmin_latest:
	garmindb_cli.py --all --copy --import --analyze --latest

# define EXPORT_ACTIVITY_ID in my-defines.mk
export_activity:
	garmindb_cli.py --export-activity $(EXPORT_ACTIVITY_ID)

# define EXPORT_ACTIVITY_ID in my-defines.mk
basecamp_activity:
	garmindb_cli.py --basecamp-activity $(EXPORT_ACTIVITY_ID)

# define EXPORT_ACTIVITY_ID in my-defines.mk
google_earth_activity:
	garmindb_cli.py --google-earth-activity $(EXPORT_ACTIVITY_ID)

clean_garmin_dbs:
	garmindb_cli.py --delete_db --all

clean_garmin_monitoring_dbs:
	garmindb_cli.py --delete_db --monitoring

clean_garmin_activities_dbs:
	garmindb_cli.py --delete_db --activities


#
# FitBit target
#
fitbit:
	fitbit.py

clean_fitbit_db:
	fitbit.py --delete_db

rebuild_fitbit:
	fitbit.py --rebuild_db


#
# MS Health target
#
mshealth: $(MSHEALTH_DB)
	mshealth.py

clean_mshealth_db:
	mshealth.py --delete_db

rebuild_mshealth:
	mshealth.py --rebuild_db


#
# test targets
#
$(SUBMODULES:%=%-test):
	$(MAKE) -C $(subst -test,,$@) test

test: $(SUBMODULES:%=%-test)
	$(MAKE) -C test all

$(SUBMODULES:%=%-verify_commit):
	$(MAKE) -C $(subst -verify_commit,,$@) verify_commit

verify_commit: $(SUBMODULES:%=%-test)
	$(MAKE) -C test verify_commit

$(SUBMODULES:%=%-test_clean):
	$(MAKE) -C $(subst -test_clean,,$@) clean

test_clean:
	$(MAKE) -C test clean

$(SUBMODULES:%=%-flake8):
	$(MAKE) -C $(subst -flake8,,$@) flake8

flake8: $(SUBMODULES:%=%-flake8)
	$(PYTHON) -m flake8 garmindb/*.py garmindb/garmindb/*.py garmindb/summarydb/*.py garmindb/fitbitdb/*.py garmindb/mshealthdb/*.py --max-line-length=180 --ignore=E203,E221,E241,W503

regression_test_run: flake8 rebuild_dbs
	grep ERROR garmin.log || [ $$? -eq 1 ]

regression_test: clean regression_test_run test


#
# bugreport target
#
bugreport:
	./bugreport.sh

.PHONY: all setup install install_all uninstall uninstall_all update deps create_dbs rebuild_dbs update_dbs clean clean_dbs test zip_packages release clean test test_clean daily flake8 $(SUBMODULES:%=%-flake8)
