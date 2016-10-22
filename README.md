# osmobridge

## Purpose
Since the DJI Osmo uses a mobile device's WiFi for control, the mobile's WiFi is unusable for accessing the internet. This is annoying. Osmobridge fixes this by using a Raspberry Pi 3 as a bridge between your mobile device and your Osmo, routing traffic desined for the Osmo to its WiFi network, and sending other traffic out through the RPi's default gateway (either eth0 or some other network interface such as a USB MiFi dongle). It also gives the benefit of letting the mobile stay connected to the bridge when the Osmo goes offline, minimizing the annoyance of having to manually reconnect the mobile to the Osmo's network (the RPi should reconnect to the Osmo automatically).

## Installation
Copy `osmobridge.inc` and `osmobridge.sh` to /root on a freshly installed Raspbian install. Edit osmobridge.inc with your Osmo's WiFi settings, and add the WiFi settings that you want the bridge to use. They should be different than the Osmo's settings so you can ensure your mobile is connecting to the correct device. After the settings are in place, run the following to initialize things. It will blow away any network configs you might have and configure some default settings, so be warned.
```
sudo -i
cd /root
chmod +x osmobridge.sh
./osmobridge.sh init
```

This will update the raspbian install, make sure dependencies are installed, and then populate the necessary configuration files. If all works as expected, all you should need to do is reboot the RPi and the bridge should initialize when it comes up!

## Gotchas
* If you happen to have multiple mobile devices trying to use the bridge to talk to the Osmo, the message in the DJI GO app that would normally be displayed on the second device stating that the Osmo is already in use may not be displayed. Instead, the Go app will appear to disconnect and reconnect ad infinitum. Make sure only one device is trying to connect!


## To Do
* Make sure it actually works! (I'm still testing it. Damn you slow SD cards!)
* Make the firewall provide security instead of just routing traffic.
  * Alternate ssh ports?
* Maybe have the script ask questions when initializing itself instead of having the user edit the config file
