# Name: ISP GW check v711.2
# Description: Optimized the code for the current version of RouterOS. Check ISP1 and send notification to telegram in ISP GW is down 
# Link: need script function "MyTGBotSendMessage"
# Author: Whyborn77 2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts
# Permissions: [System] -> [Scripts] -> [+] -> [Name:ISP GW check] -> [Policy: read, write, policy, test]


# Constants
:local PingCount 5
# RemoteIP
:local WanGW <PLACE HERE YOUR ISP GW IP>
# Interface Needed to rename yours WAN ethernet port
:local InF ISP1
#Ping
:local StatusWan [/ping $WanGW interface=$InF count=$PingCount]
:if ($StatusWan<=0) do={

    :local MessageText "%F0%9F%94%B4 $InF is <b>DOWN</b> %0D%0AChecked ISP gateway IPv4 is <tg-spoiler>$WanGW</tg-spoiler>";

    # START Send Telegram Module
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module

:log warning ("$SMP ISP1 is down.");
}
