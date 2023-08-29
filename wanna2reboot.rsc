# Name: wanna2reboot v7.11-2
# Author: Whyborn77  2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:local DeviceName [/system identity get name];
#Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};
:local Time [/system clock get time];
:local BotToken "tokenplacehere";
:local ChatID "idplacehee";
tool fetch url="https://api.telegram.org/bot$BotToken/sendMessage?chat_id=$ChatID8&text=$DeviceName is <b><u>reboot</u></b> $Time &parse_mode=html"
:delay 7s
/system reboot
