#!/bin/bash

#Script to set static ip infos t.fichtl@airitsystems.de
#First try of a bash script for a while, crappy code, i know. Use it with caution. If you have any improvements/ideas, let me know.
#TODO ==> refactor code and add more checks, to not mess it up.... making a main function to avoid recursion and unexpected script end

ipValidation() {
#local locIP = "$1"
if [[ $1 =~ (([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])) ]]; then

	printf "\nIP OK\n\n"
	return 0
else
	printf "\n\nThis is not a valid IP"
	return 1
	
fi
}

chkRoot () {
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root\n\n" 1>&2
exit 1   
fi
}

getIpInfos () {
printf "type in your new IP-Address in A.B.C.D/SN format\n"

read newIP

ipValidation $newIP


printf "type in your new GW in A.B.C.D format\n"

read newGW

ipValidation $newGW


printf "type in your new Name Server (DNS) IP-Address in A.B.C.D format\n"

read newDNS

ipValidation $newDNS

printf "type in your search domain , if more than one please searchdomain.a,searchdomain.b\n"

read newSearchdomain

printf "New IP:  $newIP \nNew GW:  $newGW \nNew DNS: $newDNS \nNewSearchdomain: $newSearchdomain\n"


}

userIpValidation(){

local validationInput
validationInput="99"

while [ 0 ]
do
printf "\nAre you happy with your input? 0 for yes, 1 for no and do it again...\n2 for cancel this script\n Your Choice: "
read validationInput
printf "\n\nYour input $validationInput\n\n"



	if [[ $validationInput == "2" ]]; then
		printf "Bye!"
		exit 1
	fi
	if [[ $validationInput == "1" ]]; then
		printf "Lets do it again\n"
		getIpInfos
		
	fi
	if [[ $validationInput == "0" ]]; then
		printf "ok"
		return 0
	fi
done
}


generateNetplanfile() {
ethernetInterface=$(ip -o link | grep ether | awk '{ print $2 }' | tr -d \: )


touch /tmp/60-static-ip.yaml

cat << ENDFILE > /tmp/60-static-ip.yaml

network:
  version: 2
  renderer: networkd
  ethernets:
    $ethernetInterface:
      dhcp4: false
      dhcp6: false
      addresses:
      - $newIP
      routes:
      - to: default
        via: $newGW
      nameservers:
       addresses: [$newDNS]
ENDFILE

cat /tmp/60-static-ip.yaml

}

netPlanMagic()(

echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
echo | netplan try --config-file /tmp/60-static-ip.yaml
)


printf "\n\nHi there! We are going to set you a static / persistent IP Address on a Ubuntu 24.4 machine using Netplan\n\n"


chkRoot
getIpInfos
userIpValidation
generateNetplanfile
netPlanMagic

