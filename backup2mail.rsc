# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Backup to Mail__       |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

# Please set a secure password and provide the recipient addresses
:local backupPassword "______"
:local recipient "___@___._"

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
}

# Get latest Cloud-Backup Details
:local backupn [/system backup cloud get 0 name ];
:local backupk [/system backup cloud get 0 secret-download-key ];
:local backupd [/system backup cloud get 0 date ];
:local backupr [/system backup cloud get 0 ros-version ];
:local backups [/system backup cloud get 0 size ];

# Send E-Mail
/tool e-mail send to=$recipient \
subject="Export-Compact | $identity" \
body="Please find the Export Compact attached!\n\nA Cloud-Backup was created.\nName: $backupn \nTime: $backupd \nRouterOS: $backupr \nSize: $backups \nDownload key: $backupk \n" \
file=$filename
:delay 10s;
/file remove $filename
