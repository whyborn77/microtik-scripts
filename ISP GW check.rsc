# Name: ISP GW check v711.1
# Description: Optimized the code for the current version of RouterOS. Check ISP1 and send notification to telegram in ISP GW is down 
# Link: need script function "MyTGBotSendMessage"
# Author: Whyborn77 2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:log info "check ISP1 GW";
#Vars
:local PingCount 3
#RemoteIP
:local WanGW <SET HERE YOUR ISP GW IP>
#Interfac. Needed to rename yours WAN ethernet port
:local InF ISP1
#Ping
:local StatusWan [/ping $WanGW interface=$InF count=$PingCount]
:if ($StatusWan<=0) do={

    # START Send Telegram Module
    :local MessageText "ISP1 is <b>DOWN</b>(script)";
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module

:put "HOME ISP Down" ;
}
