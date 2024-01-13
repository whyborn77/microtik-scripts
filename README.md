# microtik-scripts
моя скромная попытка в код lua под routeros



шаблон шидулера
#replace the script name in run this command in the terminal
/system scheduler add name="<SCRIPTNAME>" policy=read,write,policy,test on-event="/system script run <SCRIPTNAME>" interval=10m comment="Whyborn77 mikrotik scripts"
