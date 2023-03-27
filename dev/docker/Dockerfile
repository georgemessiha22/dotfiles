FROM archlinux:latest as workspacebase

RUN pacman-key --init && pacman-key --recv-key 0706B90D37D9B881 3056513887B78AEB  --keyserver keyserver.ubuntu.com && pacman-key --lsign-key 0706B90D37D9B881 3056513887B78AEB  && pacman --noconfirm -U 'https://geo-mirror.chaotic.cx/chaotic-aur/chaotic-'{keyring,mirrorlist}'.pkg.tar.zst' && echo "[multilib]" >>/etc/pacman.conf && echo "Include = /etc/pacman.d/mirrorlist" >>/etc/pacman.conf && echo -e "[garuda]\\nInclude = /etc/pacman.d/chaotic-mirrorlist\\n[chaotic-aur]\\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf && echo "" >>/etc/pacman.conf && pacman -Scc --noconfirm

RUN pacman -Sy --noconfirm --needed base-devel wayland sudo lsb-release wget git
RUN useradd --create-home gmessiha
RUN usermod --append --groups wheel gmessiha
RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# Locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

# User files
USER gmessiha
WORKDIR /home/gmessiha/backup/linux-workspace

COPY ./dev/docker/entry_point.sh /home/gmessiha/entrypoint
RUN sudo chmod +x /home/gmessiha/entrypoint

COPY . .
RUN sudo chown gmessiha:gmessiha -R /home/gmessiha

# RUN make setup
RUN make install-tools 

ENTRYPOINT ["/home/gmessiha/entrypoint"]

FROM workspacebase as workspacepackage

RUN make install-packages
RUN make install-sway 
RUN make install-qtgreet 
RUN make install-chezmoi

FROM workspacepackage as workspace

RUN make apply-chezmoi

