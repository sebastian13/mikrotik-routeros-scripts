# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Upgrade RouterOS__     |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Helper function to log and put messages
:local logput do={ :log info $1; :put $1 }

# Get latest RouterOS update information
$logput "[INFO] Checking for RouterOS Updates..."
/system package update check-for-updates once
:delay 10s

:local status [/system package update get status]
:local currentVer [/system resource get version]
:local newVer [/system package update get latest-version]

$logput ("[INFO] Update status: " . $status)
$logput ("[INFO] Current version: " . $currentVer)
$logput ("[INFO] Latest version: " . $newVer)

# Check if a new version is available
:if ($status = "New version is available") do={

    # Check release channel
    :local dotCount 0
    :for i from=0 to=([:len $newVer] - 1) do={
        :if ([:pick $newVer $i] = ".") do={
            :set dotCount ($dotCount + 1)
        }
    }

    # Install if the new version is a patch release
    # e.g. 7.18 will be skipped, but 7.18.1 will be installed
    :if ($dotCount = 2) do={
        $logput ("[OK] Patch Release detected, installing update: " . $newVer)
        :if ([:len [/system script find where name="backup2mail"]] > 0) do={
            $logput "[INFO] Running optional backup script: backup2mail"
            /system script run backup2mail
        } else={
            $logput "[WARN] Optional backup script not found: backup2mail. Continuing without backup."
        }
        /system package update install
    } else={
        $logput ("[SKIP] Major release without patch, skipping: " . $newVer)
    }

} else={
    $logput "[OK] No new version available."
}
