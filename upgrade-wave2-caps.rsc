# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |    __Upgrad Wave2 cAPs__     |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

:local installed [/system package get routeros version]

# Initiate Upgrade
:local outdatedcaps [/interface/wifi/capsman/remote-cap find where version!=$installed]

:foreach i in=$outdatedcaps do={
  :put "Initiate Upgrade on $i"
  /interface/wifi/capsman/remote-cap upgrade numbers=$i
  :delay 60s
};
