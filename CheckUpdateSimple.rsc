# Name: CheckUpdateSimple v711.2
# Description: Optimized the code for the current version of RouterOS. Check for RouterOS update (simple, not functions)  and send notification. 
# Link: Need script function "MyTGBotSendMessage"
# Author: Whyborn77  2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts
# Original author: Yun Sergey https://mhelp.pro/mikrotik-scripts-check-routeros-update/

:local DevName [/system identity get name];
#Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};

:local CheckUpdate [/system package update check-for-updates as-value];
:local Channel ($CheckUpdate -> "channel");
:local InstalledVersion ($CheckUpdate -> "installed-version");
:local LatestVersion ($CheckUpdate -> "latest-version");

:log info "Script CheckUpdateSimple - Run.";


:if ($InstalledVersion != $LatestVersion) do={

    :local MessageText "%F0%9F%86%99$DevName: MikroTik RouterOS %F0%9F%86%95 version <u>$LatestVersion</u> is available! %0D%0AInstalled version <b>$InstalledVersion</b> $Channel.%0D%0A<a href=\"https://mikrotik.com/download/changelogs\">Changelogs</a>";

    :log info "Script CheckUpdateSimple - New version is available, send notify.";

    # START Send Telegram Module
    :local SendTelegramMessage [:parse [/system script  get MyTGBotSendMessage source]]; 
    $SendTelegramMessage MessageText=$MessageText;
    #END Send Telegram Module

    } else={
:log info "Script CheckUpdateSimple - System is already up to date.";
};
:delay 1;
:log info "Script CheckUpdateSimple - Completed.";
