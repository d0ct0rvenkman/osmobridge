#!/bin/bash


case "$2" in
    CONNECTED)
        SSID=`iw wlan0 info | grep ssid | sed -r "s/^\s+ssid\s+//g"`
        echo "wpa_supplicant/${1}: connection established to \`${SSID}\`" | /usr/local/bin/slacktee -p
        ;;
    DISCONNECTED)
        echo "wpa_supplicant/${1}: connection lost" | /usr/local/bin/slacktee -p
        ;;
esac
