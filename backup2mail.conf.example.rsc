# Example config for backup2mail.rsc
#
# Store this as a FILE named backup2mail.conf.rsc (or flash/backup2mail.conf.rsc),
# NOT as a script. Script sources are part of every /export, files are not.
# Never commit your real values.

:global b2mRecipient "admin@example.com"
:global b2mBackupPassword ""
:global b2mHealthcheckUrl "https://healthchecks.example.com/ping/00000000-0000-0000-0000-000000000000"

# Include the cloud backup secret-download-key in the mail (default: true).
# Required to restore the cloud backup onto replacement hardware. The backup
# itself stays encrypted - keep b2mBackupPassword in your password manager,
# never in a script or mail.
:global b2mMailDownloadKey true
