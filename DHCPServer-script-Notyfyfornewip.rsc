# Name: DHCPServer-script-Notyfyfornewip v711.1
# Description: Notify to email if new ip on dhcp server. Just add to IP -> DHCP Server -> DHCP (tab) -> DHCP server instance -> Script (tab) -> Lease Script 
# Author: Whyborn77 2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:if ($leaseBound = 1) do={
/ip dhcp-server lease;
:foreach i in=[find dynamic=yes] do={
:local dhcpip
:set dhcpip [ get $i address ];
:local clientid
:set clientid [get $i host-name];

:if ($leaseActIP = $dhcpip) do={
:local comment "New IP"
:set comment ( $comment . ": " . $dhcpip . ": " . $clientid);
/log error $comment;
/tool e-mail send to=<SET EMAIL HERE> subject="New device in DHCP" body="$leaseActIP - $leaseActMAC - $leaseServerName - $clientid"
  }
 }
}
