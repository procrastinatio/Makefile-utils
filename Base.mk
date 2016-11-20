SHELL = /bin/bash


USER_NAME := $(shell whoami)
CURRENT_DIRECTORY := $(shell pwd)
PYTHON_FILES := $(shell find * -path .venv -prune -o  -path build -prune -o -type f -name "*.py" -print)
INSTALL_DIRECTORY := $(CURRENT_DIRECTORY)/.venv

PYTHON_VERSION := $(shell python --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)

PYTHONPATH ?= .$(INSTALL_DIRECTORY)/lib/python${PYTHON_VERSION}/site-packages:/usr/lib64/python${PYTHON_VERSION}/site-packages


variables = USER_NAME CURRENT_DIRECTORY
project_variale ?= $(variable)

# Colors
RESET := $(shell tput sgr0)
RED := $(shell tput setaf 1)
GREEN := $(shell tput setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)


# Commands
PYTHON_CMD := $(INSTALL_DIRECTORY)/bin/python
AUTOPEP8_CMD := $(INSTALL_DIRECTORY)/bin/autopep8
FLAKE8_CMD := $(INSTALL_DIRECTORY)/bin/flake8
PIP_CMD := $(INSTALL_DIRECTORY)/bin/pip
FLASK_CMD := $(INSTALL_DIRECTORY)/bin/flask
NOSE_CMD := $(INSTALL_DIRECTORY)/bin/nosetests
PSERVE_CMD := $(INSTALL_DIRECTORY)/bin/pserve
PSHELL_CMD := $(INSTALL_DIRECTORY)/bin/pshell


# Linting rules
PEP8_IGNORE := "E128,E221,E241,E251,E265,E266,E272,E501,E711"

# E128: continuation line under-indented for visual indent
# E221: multiple spaces before operator
# E241: multiple spaces after ':'
# E251: multiple spaces around keyword/parameter equals
# E265: block comment should start with '# '
# E266: too many leading '#' for block comment
# E272: multiple spaces before keyword
# E501: line length 79 per default
# E711: comparison to None should be 'if cond is None:' (SQLAlchemy's filter syntax requires this ignore!)

# Some helper function

current_value_%: ;@IFS=$$'\n' ; printf " ${YELLOW}%-28s ${GREEN}%s\n${RESET}" "$*" "$($*)" ; 

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
# A category can be added with @category
HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'Targets'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
    print "Usage: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }

help: ##@Help Show this help.
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)
	@IFS=$$'\n' ; printf " ${YELLOW}%-28s ${GREEN}%s\n${RESET}" "Variables" "Current values" ; 
	@echo
	@$(MAKE) -s --no-print-directory project_variables
	
	
	
.PHONY: user
user: ##@Build Build for user
	source $(USER_SOURCE) && make all

.PHONY: all  ##@Setup Build all
all:: setup 

setup: ##@Setup  Setup 
	venv 

templates:

.PHONY: dev
dev: ##@Build Build for dev environment
	source rc_dev && make all

.PHONY: int
int:  ##@Build Build for int environment
	source rc_int && make all

.PHONY: prod
prod:  ##@Build Build for prod environment
	source rc_prod && make all

.PHONY: serve
serve: ##@Test Serving with a builtin http server
	PYTHONPATH=${PYTHONPATH} ${PSERVE_CMD} development.ini --reload
	
	
	
fixrights: ##@Setup  Fixing right on install directories
	@echo "${GREEN}Fixing rights...${RESET}";
	chgrp -f -R geodata . || :
	chmod -f -R g+srwX . || :

guard-%:
	@ if test "${${*}}" = ""; then \
	  echo "Environment variable $* not set. Add it to your command."; \
	  exit 1; \
	fi


.PHONY: test
test:: ##@Test Running test
	ifndef TEST_DIR
		$(error TEST_DIR is not set)
	endif
	PYTHONPATH=$(PYTHONPATH) $(NOSE_CMD) $(TEST_DIR)
	
	
Makefile: ##@Setup Create a basic project Makefile from template
	cp Makefile.in $@



	
.PHONY: lint
lint: ##@Test  Linting python files
	@echo "${GREEN}Linting python files...${RESET}";
	${FLAKE8_CMD} --ignore=${PEP8_IGNORE} $(PYTHON_FILES) && echo ${RED}	
autolint:  ##@Test Auto correction of python files
	@echo "${GREEN}Auto correction of python files...${RESET}";
	${AUTOPEP8_CMD} --in-place --aggressive --aggressive --verbose --ignore=${PEP8_IGNORE} $(PYTHON_FILES);

venv: $(INSTALL_DIRECTORY)/requirements.timestamp ##@Setup Install python virtualenv

venv/bin/activate: requirements.txt
	test -d $(INSTALL_DIRECTORY) || virtualenv $(INSTALL_DIRECTORY)
	$(PIP_CMD) install -Ur requirements.txt
	touch venv/bin/activate
	
$(INSTALL_DIRECTORY): 
	test -d $(INSTALL_DIRECTORY) || echo "${GREEN}Setting up python virtual env...${RESET}";  virtualenv $(INSTALL_DIRECTORY)

requirements.txt:
$(INSTALL_DIRECTORY)/requirements.timestamp: requirements.txt $(INSTALL_DIRECTORY)
	$(PIP_CMD) install -Ur requirements.txt
	touch $@
	
clean:   ##@Cleanup  Cleanup
	rm -rf $(INSTALL_DIRECTORY) build dist *.egg-info
	find . -name __pycache__ | xargs rm -rf
	find . -name \*.pyc | xargs rm -f

.PHONY: init venv base_help all clean test

.DEFAULT_GOAL := help
