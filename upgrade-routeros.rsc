# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Upgrade RouterOS__     |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

:log info message="Checking for RouterOS Updates"

/system package update
check-for-updates once
:delay 5s;

:if ( [get status] = "New version is available") do={
    /system script run backup2mail

    # Optional: Notify on slack
    # :global SlackMessage "Upgrading RouterOS on router *$[/system identity get name]* from $[/system package update get installed-version] to *$[/system package update get latest-version] (channel:$[/system package update get channel])*";
    # :do {/system script run slack;} on-error={}
    
    /system package update install
}
