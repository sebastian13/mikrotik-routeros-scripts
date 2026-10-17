# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Backup to Mail__       |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Load variables from a dedicated config script (backup2mail.conf)
# Keep this script logic-only so updates do not overwrite environment values.
:global b2mRecipient
:global b2mBackupPassword
:global b2mHealthcheckUrl

:do {
  /system script run backup2mail.conf
} on-error={
  :error "backup2mail.conf not found or failed"
}

# Validate required values loaded from config.
:if ([:len $b2mRecipient] = 0) do={ :error "Missing b2mRecipient in backup2mail.conf" }
:if ([:len $b2mBackupPassword] = 0) do={ :error "Missing b2mBackupPassword in backup2mail.conf" }

:local recipient $b2mRecipient
:local backupPassword $b2mBackupPassword
:local healthcheckUrl $b2mHealthcheckUrl
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
:set mailBody ($mailBody . "Download key: " . $backupk . $NL)

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

# Cleanup initialized global variables
/system script environment remove [find where name~"^b2m"]
