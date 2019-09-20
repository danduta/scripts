#!/bin/bash
usage()
{
    echo "Usage: enable -s [SSID] -p [PASSWORD] -d [DRIVE LETTER]" >&2
    echo "WARNING: Flash the Raspbian image before using this script!" >&2
    echo "DRIVE LETTER should be the partition letter of the boot partition of the SD card" >&2 
    echo "Note: Drive letter should be in caps, for example if" >&2
    echo "USB is mounted in H:, use -d H" >&2
    exit 1
}

wifi_ssid=""
widi_password=""
drive=""

if [ "$EUID" -ne 0 ]; then
    echo "Run script with sudo!"
    exit 1
fi

while getopts "s:p:d:h" opt; do
  case $opt in
    s) 
	wifi_ssid="$OPTARG"
	;;
    p) 
	wifi_password="$OPTARG"
	;;
    d) 
	drive="$OPTARG" 
	;;
    h) 
	usage
	;;
    :) 
	usage
	exit 1
	;;
    \?) 
	echo "Invalid option -$OPTARG" >&2
	usage
	exit 1
	;;
    *) 
	usage
	;;
  esac
done

if [ "$wifi_ssid" = "" ] || [ "$wifi_password" = "" ] || [ "$drive" = "" ]; then
    usage
fi

mount -t drvfs "$drive": /mnt/x

echo -e "country=RO" > wpa_supplicant.conf
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> wpa_supplicant.conf
echo -e "network={" >> wpa_supplicant.conf
echo -e "\tssid=\"$wifi_ssid\"" >> wpa_supplicant.conf
echo -e "\tpsk=\"$wifi_password\"" >> wpa_supplicant.conf
echo -e "\tkey_mgmt=WPA-PSK" >> wpa_supplicant.conf
echo -e "}" >> wpa_supplicant.conf

mv wpa_supplicant.conf /mnt/x
touch /mnt/x/ssh
sync
umount /mnt/x
