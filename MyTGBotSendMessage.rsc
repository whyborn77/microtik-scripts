# Name: MyTGBotSendMessage v711.5
# Description: Optimized the code for the current version of RouterOS. send notification to telegram. 
# Author: Whyborn77  2023
# License: GPL-3.0 License
# URL: https://github.com/whyborn77/microtik-scripts
# Original author: Yun Sergey https://mhelp.pro/mikrotik-scripts-check-routeros-update/
# Permissions: [System] -> [Scripts] -> [+] -> [Name: MyTGBotSendMessage] -> [Don't Require Permissions]


:local BotToken "<PLACE HERE BOT ID >";
:local ChatID "<PLACE HERE CHAT OR GROUP ID TO REPORT>";
:local SubGroupID "<PLACE HERE YOUR REPLY ID>";
:local PM "html";
:local DWPP True;
:local SendText $MessageText;

:local tgUrl "https://api.telegram.org/bot$BotToken/sendMessage?chat_id=$ChatID&text=$SendText&parse_mode=$PM&disable_web_page_preview=$SWPP&reply_to_message_id=$SubGroupID";
/tool fetch http-method=get url=$tgUrl output=none;
:log info "Send Telegram Message: $MessageText";
