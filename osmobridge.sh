#!/bin/bash

# source configuration from config file
if [ -r /root/osmobridge.inc ];
then
	. /root/osmobridge.inc
else
	echo "Config file is not present. Exiting unhappily."
	exit 1
fi

if [ "x$OSMOSSID" == "x" ];
then
	echo "Configuration seems to be missing. Exiting unhappily."
	exit 2
fi

if [ "$1" == "init" ];
then
	# get the OS up to date and necessities installed
	apt-get update
	apt-get -y upgrade
	apt-get -y install hostapd dnsmasq wpasupplicant iptables

	# populate wpa_supplicant.conf
	cat <<EOF > /etc/wpa_supplicant/wpa_supplicant.conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="${OSMOSSID}"
    psk="${OSMOPASS}"
}
EOF

	# populate hostapd.conf
	cat <<EOF > /etc/hostapd/hostapd.conf
interface=wlan0_ap
driver=nl80211
ssid=${BRIDGESSID}
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=${BRIDGEPASS}
rsn_pairwise=CCMP
EOF

	# Apparently there is no default config file
	echo "DAEMON_CONF=/etc/hostapd/hostapd.conf" >> /etc/default/hostapd

	# populate dnsmasq.conf
	cat <<EOF > /etc/dnsmasq.conf
interface=wlan0_ap
listen-address=192.168.2.1
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.2.50,192.168.2.150,12h
EOF

	# initialize an (essentially) blank /etc/network/interfaces
	cat <<EOF >  /etc/network/interfaces
source-directory /etc/network/interfaces.d
auto lo
iface lo inet loopback
EOF

	# populate /etc/network/interfaces.d/eth0
	cat <<EOF >  /etc/network/interfaces.d/eth0
allow-hotplug eth0
iface eth0 inet manual
EOF

# populate /etc/network/interfaces.d/eth1 (for things like USB MiFi)
cat <<EOF >  /etc/network/interfaces.d/eth1
allow-hotplug eth1
iface eth1 inet manual
EOF


	# populate /etc/network/interfaces.d/wlan0
	# we use 192.168.1.25 because it seems to be in the range the Osmo will
	# give out via DHCP. IPs lower than .20 get denied streaming/control by
	# the osmo.
	cat <<EOF >  /etc/network/interfaces.d/wlan0
allow-hotplug wlan0
iface wlan0 inet manual
	wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

EOF

	# populate /etc/network/interfaces.d/wlan0_ap
	cat <<EOF >  /etc/network/interfaces.d/wlan0_ap
iface wlan0_ap inet static
    address 192.168.2.1
    network 255.255.255.0
EOF
	# run out of rc.local
	cat <<EOF >  /etc/rc.local
#!/bin/sh -e
/root/osmobridge.sh
exit 0
EOF

	# add directives to dhcpcd.conf
	cat <<EOF >> /etc/dhcpcd.conf
denyinterfaces wlan0_ap
EOF

	chmod +x /root/osmobridge.sh
	chmod +x /etc/rc.local


	# enable/disable applicable services
	systemctl disable dnsmasq
	systemctl disable hostapd
	systemctl enable dhcpcd
	systemctl enable wpa_supplicant

	# disable unnecessary crap
	systemctl disable avahi-daemon
	systemctl disable bluetooth
else
	# make it go!
	iw wlan0 interface add wlan0_ap type __ap
	ifup wlan0_ap

	echo 1 > /proc/sys/net/ipv4/ip_forward

	# TODO: make the firewall more secure instead of just functional
	iptables -P INPUT ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -P FORWARD ACCEPT

	iptables -F INPUT
	iptables -F OUTPUT
	iptables -F FORWARD
	iptables -F POSTROUTING -t nat

	iptables -I FORWARD 1 -i wlan0_ap -s 192.168.2.1/24 -j ACCEPT
	iptables -t nat -A POSTROUTING -o wlan0 -s 192.168.2.1/24 -d 192.168.1.0/24 -j MASQUERADE
	iptables -t nat -A POSTROUTING -o eth0 -s 192.168.2.0/24 -j MASQUERADE
	iptables -t nat -A POSTROUTING -o eth1 -s 192.168.2.0/24 -j MASQUERADE


	service hostapd start
	service dnsmasq start

	#  start the DHCP interfaces later after all the other stuff is running
	ifup wlan0 > /dev/null 2>&1 &
	ifup eth0  > /dev/null 2>&1 &

fi
