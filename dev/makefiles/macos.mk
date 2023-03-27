#!/usr/bin/env make

### MacOS (commands works only included if OS is Mac)

.PHONY: install-tools install-chezmoi install-packages backup-packages setup

## Installing tools on MacOS like HomeBrew
install-tools:
	@echo " 🔥 Installing tools on MacOS"
	ifeq (, ${shell which brew})
		@echo "Installing HomeBrew 🛂"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	endif

## installing and configuring chezmoi
install-chezmoi: 
	mkdir -p ~/.config/chezmoi
	cp -r ./dotfiles/dot_config/chezmoi ~/.config/chezmoi
	chezmoi apply --force

## Install Homebrew Packages
install-packages:
	@echo "Installing Homebrew 📦"
	brew bundle --file install/brew/Brewfile;
	brew install --cask alacritty --no-quarantine;

## Backup packages
backup-packages:
	@echo "Backing up HomeBrew"
	brew bundle --file=install/brew/Brewfile dump --force

## Install tools and config files
setup: init install-tools install-packages init-chezmoi
