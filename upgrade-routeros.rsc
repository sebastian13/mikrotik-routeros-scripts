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
    :if ([:len [/system script find where name="backup2mail"]] > 0) do={
        :log info message="Running optional backup script: backup2mail"
        /system script run backup2mail
    } else={
        :log warning message="Optional backup script not found: backup2mail. Continuing without backup."
    }

    # Optional: Notify on slack
    # :global SlackMessage "Upgrading RouterOS on router *$[/system identity get name]* from $[/system package update get installed-version] to *$[/system package update get latest-version] (channel:$[/system package update get channel])*";
    # :do {/system script run slack;} on-error={}
    
    /system package update install
}
