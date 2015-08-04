# BTOpenzoneAutomation
Have you ever thought about sharing the BT openzone Internet inside your house without needing to enter username password all the time in the web interface? or without switching to stronger WiFis? I tried to address these issues here and make sure that the connection is secure. 
This will automate the process of connecting to BT Openzone for allowed users in Linux.
You can also add your favourite VPN connection to this bash script.

Usage:

./autoconnect.sh wlan0 test@example.com BtBroadbandPass

watch -n 60 ./autoconnect.sh wlan0 test@example.com BtBroadbandPass
