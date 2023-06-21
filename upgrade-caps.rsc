# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |       __Upgrad cAPs__        |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

:local installed [/system package get routeros version]

# Initiate Upgrade
:local outdatedcaps [/caps-man remote-cap find where version!=$installed]

:foreach i in=$outdatedcaps do={
  :put "Initiate Upgrade on $i"
  /caps-man remote-cap upgrade numbers=$i
  :delay 60s
};
