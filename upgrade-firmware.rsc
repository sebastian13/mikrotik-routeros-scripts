# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Upgrade Firmware__     |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

:log info "Checking firmware...";
/system routerboard
:if ([get current-firmware] != [get upgrade-firmware]) do={
     :log info "Updating firmware";

     # Optional: Notify on slack
     # :global SlackMessage "Upgrading firmware on router *$[/system identity get name]* from $[/system routerboard get current-firmware] to *$[/system routerboard get upgrade-firmware]*";
     # :do {/system script run slack;} on-error={}

     upgrade;
     :delay 10s
     /system reboot
     } else={
     :log info "No firmware update pending."
}
