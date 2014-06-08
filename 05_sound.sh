#!/bin/sh
 # File: "/etc/pm/sleep.d/05_sound"
 case "${1}" in
 hibernate|suspend)
 # Unbind ehci for preventing error
 echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
 # Unbind snd_hda_intel for sound
 echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
 echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
 ;;
 resume|thaw)
 # Bind ehci for preventing error
 echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/bind
 # Bind snd_hda_intel for sound
 echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
 echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
 ;;
 esac