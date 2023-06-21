# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |  _Download cAP's Packages_   |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Set Package Path if required, set policy to none if using 'upgrade-caps' script
# /caps-man/manager/set package-path="/capsman-packages" upgrade-policy=none

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
	url="https://download.mikrotik.com/routeros/$latest/routeros-$architecture-$latest.npk" \
	dst-path="capsman-packages/routeros-$architecture-$latest.npk"
}
