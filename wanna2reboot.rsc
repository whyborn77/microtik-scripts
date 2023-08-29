# Name: wanna2reboot v711.3
# Author: Whyborn77 2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:local DeviceName [/system identity get name];
#Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};
:local MessageText "%E2%84%B9%EF%B8%8F$DevName is going to rebootю, <b>keep calm and drink some coffees</b>";
:log info "Script wanna2reboot - prepare to reboot, send notify to telegram.";
    #START Send Telegram Module
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module
:delay 7s
:log warning ("$SMP Script "wanna2reboot" - system is expected to reboot.");
/system reboot
