#!/bin/bash

# Stop any services that are running, so that they receive the new env var when they restart.
systemctl --user stop pipewire.socket pipewire xdg-desktop-portal xdg-desktop-portal-wlr wireplumber ;
systemctl --user start pipewire xdg-desktop-portal xdg-desktop-portal-wlr ;
systemctl --user start wireplumber ;
