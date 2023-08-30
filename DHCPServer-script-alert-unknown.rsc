# Name: DHCPServer-script-alert-unknown v711.1
# Description: Notify to email if new ip on dhcp server. Just add to IP -> DHCP Server -> DHCP (tab) -> DHCP server instance -> Alerts -> Lease Script 
# Author: Whyborn77 2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:local DevName [/system identity get name];
#Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};

:local MessageText "%E2%9A%A0%EF%B8%8F$DevName - DHCP Alert: Discovered%0D%0A<b>unknown</b> dhcp server $address $"portname" $"mac-address" $interface ";

/tool e-mail send to=report@miassmobili.com subject=("DHCP Alert: Discovered unknown dhcp server") body=("MikroTik have been detected unknown dhcp-server: \n\n$address  $portname \n$interface \n$"mac-address" "\n.[/system identity get name] );

;log warning "e-mail send unknown dhcp-server"

    #START Send Telegram Module
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module
