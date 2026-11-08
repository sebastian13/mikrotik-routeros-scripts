# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Backup to Mail__       |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Load variables from a config FILE (not a script!).
# Script sources are always included in /export, files are not. Keeping the
# secrets in a file prevents them from leaking via the mailed export.
# Supported locations: backup2mail.conf.rsc or flash/backup2mail.conf.rsc
:global b2mRecipient
:global b2mBackupPassword
:global b2mHealthcheckUrl
:global b2mMailDownloadKey

:local confLoaded false
:foreach confFile in={ "backup2mail.conf.rsc"; "flash/backup2mail.conf.rsc" } do={
  :if (!$confLoaded and ([:len [/file find where name=$confFile]] > 0)) do={
    :do {
      :local conf [:parse [/file get $confFile contents]]
      $conf
      :set confLoaded true
    } on-error={
      /system script environment remove [find where name~"^b2m"]
      :error "backup2mail: failed to parse $confFile"
    }
  }
}

# Legacy fallback: config stored as script (secrets end up in every export!)
:if (!$confLoaded and ([:len [/system script find where name="backup2mail.conf"]] > 0)) do={
  :local legacyWarning "backup2mail: config loaded from SCRIPT backup2mail.conf - its secrets are part of every /export. Move it to the file backup2mail.conf.rsc and delete the script."
  :log warning $legacyWarning
  # :put shows the warning when run interactively (no effect from scheduler)
  :put ("WARNING: " . $legacyWarning)
  :do {
    /system script run backup2mail.conf
    :set confLoaded true
  } on-error={}
}

# Copy to locals and remove the globals right away, so the secrets do not
# linger in /system script environment if the script fails later on.
:local recipient $b2mRecipient
:local backupPassword $b2mBackupPassword
:local healthcheckUrl $b2mHealthcheckUrl
:local mailDownloadKey ([:tostr $b2mMailDownloadKey] != "false")
/system script environment remove [find where name~"^b2m"]

:if (!$confLoaded) do={
  # Typical after updating from a version that had the password hardcoded in
  # this script: the update removed it, but it was part of every former export.
  :local missingConf "backup2mail: config file backup2mail.conf.rsc not found - backup NOT created. If your backup password used to be stored in a script (e.g. directly in backup2mail), it was included in every previous export: rotate it."
  :log error $missingConf
  :put ("ERROR: " . $missingConf)
  :error "backup2mail: config file backup2mail.conf.rsc not found"
}
:if ([:len $recipient] = 0) do={
  :log error "backup2mail: missing b2mRecipient in config"
  :error "backup2mail: missing b2mRecipient in config"
}
:if ([:len $backupPassword] = 0) do={
  :log error "backup2mail: missing b2mBackupPassword in config"
  :error "backup2mail: missing b2mBackupPassword in config"
}

:local cloudBackupOk true

# Notify Healthchecks that the job started.
:if ([:len $healthcheckUrl] > 0) do={
  :do {
    /tool fetch url=($healthcheckUrl . "/start") output=user as-value
  } on-error={
    :log warning "Failed to ping healthcheck start URL"
  }
}

/system/script/run globals

:global identity
:global identitySlug
:global timestamp

:local filename "$timestamp-$identitySlug"

:log info message="Sending Export Compact to $recipient"
/export compact file=$filename
:delay 10s;

# Create Cloud-Backup
:do {
  # we are not interested in output, but print without count-only is
  # required to fetch information from cloud
  / system backup cloud print as-value;
  :if ([ / system backup cloud print count-only ] > 0) do={
    / system backup cloud upload-file action=create-and-upload \
        password=$backupPassword replace=[ get ([ find ]->0) name ];
  } else={
    / system backup cloud upload-file action=create-and-upload \
        password=$backupPassword;
  }
} on-error={
  :log error ("Failed uploading backup for " . $identity . " to cloud.");
  :set cloudBackupOk false;
}

# Get latest Cloud-Backup Details
:local backupn [:tostr [/system backup cloud get 0 name ]]
:local backupk [:tostr [/system backup cloud get 0 secret-download-key ]]
:local backupd [:tostr [/system backup cloud get 0 date ]]
:local backupr [:tostr [/system backup cloud get 0 ros-version ]]
:local backups [:tostr [/system backup cloud get 0 size ]]

# Build mail body using SMTP-compatible CRLF
:local NL "\r\n"
:local mailBody ("Please find the Export Compact attached!" . $NL . $NL)
:set mailBody ($mailBody . "A Cloud-Backup was created." . $NL)
:set mailBody ($mailBody . "Name: " . $backupn . $NL)
:set mailBody ($mailBody . "Time: " . $backupd . $NL)
:set mailBody ($mailBody . "RouterOS: " . $backupr . $NL)
:set mailBody ($mailBody . "Size: " . $backups . $NL)
# The download key is required to restore the cloud backup onto replacement
# hardware. Without the backup password (not part of the export) it only
# allows downloading the encrypted backup. Disable with b2mMailDownloadKey false.
:if ($mailDownloadKey) do={
  :set mailBody ($mailBody . "Download key: " . $backupk . $NL)
}

# Send e-mail
/tool e-mail send \
    to=$recipient \
    subject=("Export-Compact | " . $identity) \
    body=$mailBody \
    file=($filename . ".rsc")

:delay 10s
/file remove ($filename . ".rsc")

# Notify Healthchecks only when backup finished successfully.
:if (($cloudBackupOk = true) and ([:len $healthcheckUrl] > 0)) do={
  :do {
    /tool fetch url=$healthcheckUrl output=user as-value
  } on-error={
    :log warning "Failed to ping healthcheck success URL"
  }
}
