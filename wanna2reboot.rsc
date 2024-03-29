# Name: wanna2reboot v711.6
# Author: Whyborn77 2024
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:local DevName [/system identity get name];
#Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};
#Check if uptime low than 2w dont reboot device
:if ([ /system/resource/get uptime ] > 2w0d0h0m0s) do={
:local MessageText "%E2%9A%A0%EF%B8%8F$DevName is going to <b>reboot</b>.%0D%0A<i>Keep calm and drink some coffees</i>";
:log info ("Script wanna2reboot send notify to telegram and prepare to reboot.");
    #START Send Telegram Module
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module
:log warning ("$SMP Script wanna2reboot - system is expected to reboot.");
:delay 30s
/system reboot 
} else={
:log info ("Script wanna2reboot will not be executed due to low uptime");}
