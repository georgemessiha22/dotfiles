#!/usr/bin/env make

### docker.% Docker commands

.PHONY: help build sh

include ./dev/makefiles/help.mk

.DEFAULT_GOAL := help

## Build using docker
build:
	DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t workspace:latest --target workspace --file dev/docker/Dockerfile .

## Build base image "workspacebase" using docker
build-base:
	DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t workspacebase:latest --target workspacebase --file dev/docker/Dockerfile .

## build packages installed image "workspacepackage"
build-package:
	DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t workspacepackage:latest --target workspacepackage --file dev/docker/Dockerfile .

## shell docker "workspace" image
sh:
	docker run --platform linux/amd64 -v .:/home/gmessiha/backup/linux-workspace/ -it workspace:latest bash 

## shell docker "workspacebase" image
sh-base:
	docker run --platform linux/amd64 -v .:/home/gmessiha/backup/linux-workspace/ -it workspacebase:latest bash 

## shell docker "workspacepackage" image
sh-package:
	docker run --platform linux/amd64 -v .:/home/gmessiha/backup/linux-workspace/ -it workspacepackage:latest bash 

