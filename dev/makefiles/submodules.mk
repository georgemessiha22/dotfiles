#!/usr/bin/env make


### submodules.% Submodules

.PHONY: init master pull 

include ./dev/makefiles/help.mk

.DEFAULT_GOAL=help

## fetch all submodules
init:
	git submodule update --init --remote --recursive
.PHONY: init

## checkout master on all submodules
master:
	git submodule foreach --recursive git checkout main
.PHONY: master

## pull submodules
pull:
	git submodule foreach --recursive git pull
.PHONY: pull
