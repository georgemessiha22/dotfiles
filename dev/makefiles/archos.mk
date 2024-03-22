#!/usr/bin/env make

.PHONY: setup install-tools install-packages install-qtgreet install-qtgreet install-sway apply-chezmoi

### Arch OS (commands works only included if Arch OS)
## Install QtGreet for GUI login on wayland
install-qtgreet:
	@echo "🎮 Installing QTGreet"
	sudo paru -S --noconfirm greetd
	sudo cp ./dev/scripts/greetd/config.toml /etc/greetd/config.toml
	sudo cp ./dev/scripts/greetd/swayconfig /etc/greetd/swayconfig
	sudo cp ./dev/scripts/greetd/pam /etc/pam.d/greetd
	sudo cp ./dev/scripts/greetd/pam /etc/pam.d/login
	sudo cp ./dev/scripts/greetd/portal /usr/share/xdg-desktop-portal/portals/gnome-keyring.portal 
	sudo cp ./dev/scripts/qtgreet/Christmas.svg /usr/share/qtgreet/backgrounds/
	sudo cp ./dev/scripts/qtgreet/config.ini /etc/qtgreet/config.ini
	git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

## install my custom sway entrypoint
install-sway:
	@echo "🦢 Sway Setup"
	sudo cp ./dev/scripts/sway/my_sway /usr/local/bin/my_sway
	sudo chmod +x /usr/local/bin/my_sway
	sudo cp ./dev/scripts/sway/my-sway.desktop /usr/share/wayland-sessions/
	sudo cp ./dev/scripts/sway/greetd.toml /etc/greetd/config.toml
	sudo cp ./dev/scripts/sway/swayconfig /etc/greetd/swayconfig

## install my custom hyprland entrypoint
install-hyprland: 
	sudo cp ./dev/scripts/hyprland/my_hyprland /usr/local/bin/my_hyprland
	sudo chmod +x /usr/local/bin/my_hyprland
	sudo cp ./dev/scripts/hyprland/my-hyprland.desktop /usr/share/wayland-sessions/
	sudo cp ./dev/scripts/hyprland/greetd.toml /etc/greetd/config.toml

## installing and configuring chezmoi
install-chezmoi:
	@echo "⏱️  Installing Chezmoi"
	sudo paru -S --noconfirm chezmoi
	mkdir -p ~/.config/chezmoi
	cp ./dotfiles/dot_config/chezmoi/chezmoi.toml ${HOME}/.config/chezmoi/chezmoi.toml

## Install tools
install-tools:
	@echo "💻 Installing Base"
	sudo pacman -Sy --noconfirm --needed base-devel
	@echo "📱 Installing paru an Arch package helper written in Rust"
	git clone https://aur.archlinux.org/paru.git ${HOME}/paru
	@cd ${HOME}/paru && makepkg -si --noconfirm

## Install Packages using Paru
install-packages:
	@echo "📦 Installing Needed packages for Developer workspace"
	paru -Syuu --noconfirm
	paru -S --noconfirm `cat ${HOME}/backup/linux-workspace/install/arch/packages.txt`
	@echo "✅ Tools Installation Finished"

## Applying Workspace configurations
apply-chezmoi:
	@echo "☸️ 🎌 applying chezmoi configuration files"
	chezmoi apply --force

## applying all custom systemd daemons
apply-systemd:
	@echo " enable services autostartup"
	systemctl daemon-reload --user
	systemctl enable --now --user gnome-keyring-daemon

## Setup Arch Workspaces 
setup: install-tools install-packages install-sway install-qtgreet install-chezmoi apply-chezmoi apply-systemd

## backup currently installed packages
backup-packages:
	sh -c 'pacman -Qqe > install/arch/packages.txt'



