#!/bin/bash

while getopts ":s:p:d:" opt; do
  case $opt in
    s) wifi_ssid="$OPTARG"
    ;;
    p) wifi_password="$OPTARG"
    ;;
    d) drive="$OPTARG" 
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

mount -t drvfs H: /mnt/x

echo -e "country=RO" > wpa_supplicant.conf
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> wpa_supplicant.conf
echo -e "network={" >> wpa_supplicant.conf
echo -e "\tssid=\"$wifi_ssid\"" >> wpa_supplicant.conf
echo -e "\tpsk=\"$wifi_password\"" >> wpa_supplicant.conf
echo -e "\tkey_mgmt=WPA-PSK" >> wpa_supplicant.conf
echo -e "}" >> wpa_supplicant.conf

mv wpa_supplicant.conf /mnt/x
touch /mnt/x/ssh
umount /mnt/x
