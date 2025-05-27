# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |       __Upgrad cAPs__        |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Helper function to log and put messages
:local logput do={ :log info $1; :put $1 }

:local installed [/system package get routeros version]

# Initiate Upgrade on outdated cAPs (old CAPs Manager)
:if ([/system/package/find where name="wireless" disabled=no]) do={
    :put message="Old wireless driver detected";

    [:parse "
      /caps-man/remote-cap
      :local outdatedcaps [find where version!=$installed]

      :foreach i in=\$outdatedcaps do={
        \$logput (\"[INFO] Initiate Upgrade on \" . [get value-name=identity \$i])
        upgrade numbers=\$i
        :delay 120s
      };
    "]
}

# Initiate Upgrade on outdated cAPs (new CAPs Manager)
/interface/wifi/capsman/remote-cap/
:local outdatedWifiCaps [find where version!=$installed]

:foreach i in=$outdatedWifiCaps do={
  $logput ("[INFO] Initiate Upgrade on " . [get value-name=identity $i])
  upgrade numbers=$i
  :delay 120s
};
