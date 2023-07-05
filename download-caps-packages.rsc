# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |  _Download cAP's Packages_   |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Set a directory path providing the required space
# Add a microSD card https://wiki.mikrotik.com/wiki/Manual:System/Disks
# or setup a RAM-Disk via '/disk/add type=tmpfs tmpfs-max-size=20M slot=ram'
:local dir "/sd1/capsman-packages"

# Set Package Path if required, set policy to none if using 'upgrade-caps' script
# /caps-man/manager/set package-path="$dir" upgrade-policy=none

:local latest
/system package update check-for-updates once
:delay 5s;
:set latest "$[/system package update get latest-version]"

# Delete old downloads
/file/remove [ find type=package name~"capsman*" ]

:foreach architecture in={ "arm";
                           "arm64";
                           "mipsbe" } do={
	/tool fetch mode=http \
	url="https://download.mikrotik.com/routeros/$latest/routeros-$latest-$architecture.npk" \
	dst-path="$dir/routeros-$latest-$architecture.npk"
	/tool fetch mode=http \
	url="https://download.mikrotik.com/routeros/$latest/wifiwave2-$latest-$architecture.npk" \
	dst-path="$dir/wifiwave2-$latest-$architecture.npk"
}
