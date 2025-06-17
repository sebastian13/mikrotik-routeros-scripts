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
/interface/wifi/capsman/set package-path="$dir" upgrade-policy=none

:local installed [/system package get value-name=version [find where name="routeros"]]

# Delete old downloads
# /file/remove [ find type=package name~"capsman*" ]

# Starting from RouterOS version 7.13, drivers for older wireless and 60GHz interfaces are
# part of the separate "wireless" package. The existing "wifiwave2" package has been divided
# into distinct packages: "wifi-qcom" and "wifi-qcom-ac".
# RouterOS >=7.12 is required to upgrade to 7.13.
# https://forum.mikrotik.com/viewtopic.php?t=202423

:foreach architecture in={ "arm";
                           "arm64";
                           "mipsbe" } do={
     :foreach package in={ "routeros";
                           "wireless";
                           "wifi-qcom";
                           "wifi-qcom-ac" } do={ :do {
        :put ""
        :put "Download $package $installed for $architecture"
        /tool fetch mode=https \
        url="https://download.mikrotik.com/routeros/$installed/$package-$installed-$architecture.npk" \
        dst-path="$dir/$package-$installed-$architecture.npk"
        } on-error={ :put "Error downloading the file. On a 404, note that the package may not exist for the specified architecture!" }
     }
}
