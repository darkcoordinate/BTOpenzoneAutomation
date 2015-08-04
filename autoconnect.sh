#!/bin/bash

# Have you ever thought about sharing the BT openzone Internet inside your house without needing to enter username password all the time in the web interface? or without switching to stronger WiFis? I tried to address these issues here and make sure that the connection is secure
# run it like this:
# ./autoconnect.sh wlan0 test@example.com BtBroadbandPass
# or
# watch -n 60 ./autoconnect.sh wlan0 test@example.com BtBroadbandPass
# You can also add your favorite VPN connection to this bash script

wirelesscard=(`iw "$1" info`)

if [[ ! "$wirelesscard" == Interface* ]]; then
 echo "Wireless interface (\"$1\") was not found! -- `date`"
 exit 1
fi

status=(`iw "$1" link`)
if [[ "$status" == Not* ]]; then
 echo "Wireless is not connected at the moment -- `date`"
 echo "stopping network-manager..."
 service network-manager stop
 echo "restarting the interface..."
 ifconfig "$1" down
 ifconfig "$1" up
 echo "Now wait for 5 seconds! in silent you may think about great ideas! :p"
 sleep 5
 echo "Done."
 # finding BT openzone networks
 echo "Finding BT openzone networks..."
 # the following only work with network-manager but we cannot connect to wireless when it is running! so we have already stopped it :(
 # btopenzone=(`nm-tool | grep "Freq.*Strength" | sed 's/\(  \+\|,\)/ /g'|sed -ne "s|\(.*Strength \([0-9]\+\).*\)|\2}\1|p" | sort -n -r|egrep -v '(WPA|WPA2|WEP)'| grep -i 'BTWIFI'|grep -v '\-X'`)
 # we need to use the iw command to achieve the same result
 btopenzone=(`iw "$1" scan|egrep -i "ssid|signal|^BSS"|paste -d "" - - -|sed 's/\(  \+\|\t\)/ /g'|sed -ne "s|\(.*signal: -\([0-9]\+\).*\)|\2} \1|p"|sort -n|grep -i 'BTWIFI'`)
 # strongSSID=${btopenzone[1]::-1} # when we use nm-tool
 strongSSID=${btopenzone[9]} 
 if [ ! -z "$strongSSID" ]; 
 then
  echo "A strong SSID was found: $strongSSID"
  echo "Trying to connect..."
  iwconfig "$1" essid "$strongSSID"
  dhclient -v "$1"
 else
   echo "No valid SSID was found!"
   exit 1
 fi
else
 echo "Pass - You are already connected! -- `date`"
fi

# Checking the certificate to ensure it is a valid BT openzone wireless network!
cert=(`echo quit|openssl s_client -CApath ./cert -connect www.btopenzone.com:8443 -crlf 2>&1`)
echo $cert
if [[ "${cert[@]}" == *"Verify return code: 0 (ok)"*  ]]; then
 echo "Good news: certificate of the www.btopenzone.com:8443 server seems legit!"
 echo "Sending the authentication request..."
 curl --data "username=$2&password=$3&x=28&y=18&xhtmlLogon=https%3A%2F%2Fwww.btopenzone.com%3A8443%2FtbbLogon" https://www.btopenzone.com:8443/tbbLogon
 echo "Should be connected now! Just checking..."
 # Connection check as well as security!
 googlestatus=(`curl https://google.com/ 2>&1`)
 if [[ "${googlestatus[@]}" == *"key was not OK"* ]]; then
  echo "Oh noooo!!! Failed to connect to https://www.google.com"
  echo "Check your credentials!"
  echo "This can be because of a security issue if the wireless network is insecure"
 else
  echo "You have connected successfully! Enjoy it while it lasts ;)"
  echo "You can now probably share the Internet via a wireless router and put this file in loop to run it every minute!"
  #openvpn ./openvpn/profile.conf
 fi
else
 echo "ERROR: Certificate for www.btopenzone.com:8443 is invalid!"
 echo "Shutting down the network interface..."
 ifconfig "$1" down
 echo "Done."
 exit 1
fi
