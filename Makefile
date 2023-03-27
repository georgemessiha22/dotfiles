#!/usr/bin/env make

.PHONY: info

include dev/makefiles/help.mk

.DEFAULT_GOAL=help

OS := $(shell uname)

## Call submodules.help to find all commands within submodules
submodules.%:
	$(eval T:=$(shell echo $@ | cut -d "." -f 2))
	@make -f dev/makefiles/submodules.mk $T

## Call docker.help to find all commands within docker
docker.%:
	$(eval T:=$(shell echo $@ | cut -d "." -f 2))
	@make -f dev/makefiles/docker.mk $T

ifeq ($(OS), Darwin)
include dev/makefiles/macos.mk

else ifeq ($(OS), Linux)
RELEASE := $(shell lsb_release -si)

# Garuda Arch
ifeq ($(RELEASE), Garuda)
include dev/makefiles/archos.mk
endif

# Arch
ifeq ($(RELEASE),  Arch)
include dev/makefiles/archos.mk
endif

endif

## Print OS information
info:
	@echo OS: $(OS)
	@echo Release: $(RELEASE)

