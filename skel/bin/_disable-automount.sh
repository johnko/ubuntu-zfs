#!/usr/bin/env bash
set -e
set -x

# setting automount to false will prevent USB from mounting automatically
# this is useful for users who will be writing (dd) to USB often
# source: http://unix.stackexchange.com/questions/282918/how-can-i-use-gsettings-to-disable-device-automount-in-ubuntu-16-04

# disable for GNOME/Unity
if which gsettings; then
  gsettings set org.gnome.desktop.media-handling automount false
fi

if which xfconf-query; then
  # source: https://forum.xfce.org/viewtopic.php?pid=43171#p43171
  # disable for XFCE, default was true
  xfconf-query -c thunar-volman -n -p "/automount-drives/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/automount-media/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autobrowse/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoplay-audio-cds/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoplay-video-cds/enabled" -t string -s false
  # default was false
  xfconf-query -c thunar-volman -n -p "/autorun/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoopen/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoburn/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoipod/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autophoto/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autoprinter/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autokeyboard/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/automouse/enabled" -t string -s false
  xfconf-query -c thunar-volman -n -p "/autotablet/enabled" -t string -s false
fi
