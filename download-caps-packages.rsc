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
# /file/remove [ find type=package name~"capsman*" ]

# Starting from RouterOS version 7.13, drivers for older wireless and 60GHz interfaces are
# part of the separate "wireless" package. The existing "wifiwave2" package has been divided
# into distinct packages: "wifi-qcom" and "wifi-qcom-ac".
# https://forum.mikrotik.com/viewtopic.php?t=202423

# Keep 7.12 for now, it's required to upgarde to 7.13
:foreach architecture in={ "arm";
                           "arm64";
                           "mipsbe" } do={
     :foreach package in={ "routeros";
                           "wifiwave2" } do={ :do {
        :put ""
        :put "Download $package 7.12 for $architecture"
        /tool fetch mode=https \
        url="https://download.mikrotik.com/routeros/7.12/$package-7.12-$architecture.npk" \
        dst-path="$dir/$package-7.12-$architecture.npk"
        } on-error={ :put "Error downloading the file. On a 404, note that the package may not exist for the specified architecture!" }
      }
}

:foreach architecture in={ "arm";
                           "arm64";
                           "mipsbe" } do={
     :foreach package in={ "routeros";
                           "wireless";
                           "wifi-qcom";
                           "wifi-qcom-ac" } do={ :do {
        :put ""
        :put "Download $package $latest for $architecture"
        /tool fetch mode=https \
        url="https://download.mikrotik.com/routeros/$latest/$package-$latest-$architecture.npk" \
        dst-path="$dir/$package-$latest-$architecture.npk"
        } on-error={ :put "Error downloading the file. On a 404, note that the package may not exist for the specified architecture!" }
     }
}
