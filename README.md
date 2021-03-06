# osmobridge

## Purpose
Since the DJI Osmo uses a mobile device's WiFi for control, the mobile's WiFi is unusable for accessing the internet. This is annoying. Osmobridge fixes this by using a Raspberry Pi 3 as a bridge between your mobile device and your Osmo, routing traffic destined for the Osmo to its WiFi network, and sending other traffic out through the RPi's default gateway (either eth0 or some other network interface such as a USB MiFi dongle). It also gives the benefit of letting the mobile stay connected to the bridge when the Osmo goes offline, minimizing the annoyance of having to manually reconnect the mobile to the Osmo's network (the RPi should reconnect to the Osmo automatically).

## Installation
The install process overwrites things indiscrimnately, so if you care about your install, it's best to start fresh on a separate sdcard with a fresh Raspbian install.

* Copy `osmobridge.inc` and `osmobridge.sh` to `/root`.
* Edit `osmobridge.inc` with your Osmo's WiFi settings, and add the WiFi settings that you want the bridge to use. They should be different than the Osmo's settings so you can ensure your mobile is connecting to the correct device.
* Run the `osmobridge.sh init` to initialize things. This will update the raspbian install, make sure dependencies are installed, and then populate the necessary configuration files.

Simple copypasta:
```bash
$ sudo -i
# cd /root
# wget -O osmobridge.sh https://raw.githubusercontent.com/d0ct0rvenkman/osmobridge/master/osmobridge.sh
# wget -O osmobridge.inc https://raw.githubusercontent.com/d0ct0rvenkman/osmobridge/master/osmobridge.inc
# chmod +x osmobridge.sh
```
Edit settings in `osmobridge.sh`
```bash
# ./osmobridge.sh init
```
* If all works as expected, all you should need to do is reboot the RPi and the bridge should initialize when it comes up!


## Gotchas
* You'll need a second wifi interface to make this work. I really wanted this to work using a virtual wifi interface (it did initially) as an AP, but a Raspbian update seemed to break that. The [official Raspberry Pi USB wifi NIC](https://www.amazon.com/gp/product/B014HTNO52/ref=od_aui_detailpages00?ie=UTF8&psc=1) works great
* You'll need to make sure that your Osmo is configured to use a 2.4GHz band for its WiFi AP. The RPi3 doesn't seem to have a 5GHz radio.
* If you happen to have multiple mobile devices trying to use the bridge to talk to the Osmo, the message in the DJI GO app that would normally be displayed on the second device stating that the Osmo is already in use may not be displayed. Instead, the Go app will appear to disconnect and reconnect ad infinitum. Make sure only one device is trying to connect!
* The Pi seems to have very little RNG entropy populated on boot, so it seems to take multiple attempts to connect to the bridge because hostapd needs to wait before it can generate keys.
* The Pi's dhcp clients seem slow to see that a new connection has been made (ethernet, Mifi, or the Osmo). It seems best at this point to start the Pi with your internet connection plugged in, and the Osmo on.

## To Do
* Figure out how to make osmobridge.sh run after the whole OS boots up instead of doing it badly with a sleep command.
* Instead of a monolithic script running from rc.local, see about having everything run out of normal Raspbian OS locations
* Run with read-only partitions so sudden powercycles are safe
