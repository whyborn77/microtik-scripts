# Name: CheckUpdate_all_in1 v711.2
# Description: Optimized the code for the current version of RouterOS. Check for RouterOS update and send notification to telegram. 
# Author: Whyborn77  2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts

:local TGSendMessage do={
:local tgUrl "https://api.telegram.org/bot$Token/sendMessage?chat_id=$ChatID&text=$Text&parse_mode=html";
/tool fetch http-method=get url=$tgUrl keep-result=no;
}

# Constants
:local TelegramBotToken "<PLACE HERE BOT ID >";
:local TelegramChatID "<PLAE HERE CHAT ID TO REPORT>";
:local DeviceName [/system identity get name];
:local TelegramMessageText " <b> $DeviceName:</b> ";

# Check if proper identity name is set
if ([:len [/system identity get name]] = 0 or [/system identity get name] = "MikroTik") do={
    :log warning ("$SMP Please set identity name of your device (System -> Identity), keep it short and informative.");
};

# Check Update
:local MyVar [/system package update check-for-updates as-value];
:local Chan ($MyVar -> "channel");
:local InstVer ($MyVar -> "installed-version");
:local LatVer ($MyVar -> "latest-version");


:if ($InstVer = $LatVer) do={
:set TelegramMessageText ($TelegramMessageText . "System is already up to date");
} else={

:set TelegramMessageText "$TelegramMessageText New version $LatVer is available! <a href=\"https://mikrotik.com/download/changelogs\">Changelogs</a>. [Installed version $InstVer, chanell $Chan].";

$TGSendMessage Token=$TelegramBotToken ChatID=$TelegramChatID Text=$TelegramMessageText;
}

:log info $TelegramMessageText;
