# Mikrotik RouterOS Scripts Collection

**[Backup & Auto Upgrade](#backup--auto-upgrade)**<br>
**[Download RouterOS Packages for CAPs](#download-routeros-packages-for-caps-on-a-capsman)**

## Backup & Auto Upgrade

1. Setup SMTP

	```
	/certificate settings set builtin-trust-anchors=trusted
	/tool e-mail
	set address=smtp.gmail.com from=___@gmail.com port=587 tls=starttls \
	    user=___@gmail.com password=___ certificate-verification=yes
	```

	`builtin-trust-anchors` requires RouterOS 7.19+. On older versions import the CA certificates manually.

2. Download the required scripts, **backup2mail**, **upgrade-firmware**, **upgrade-routeros**

	```
	/system script
	:foreach Script in={ "backup2mail";
	                     "globals";
	                     "slack";
	                     "upgrade-firmware";
	                     "upgrade-routeros";
	                     "upgrade-routeros-skipfirstmajor" } do={
	    :if ([:len [ find where name=$Script ]] = 0) do={ add name=$Script }
	    set numbers=[find where name=$Script] source=([ \
	        /tool fetch \
	        url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/$Script.rsc" \
	        check-certificate=yes output=user as-value]->"data");
	};
	```

3. Create the config file backup2mail.conf.rsc (required)

	`backup2mail` loads its settings from the **file** `backup2mail.conf.rsc` (or `flash/backup2mail.conf.rsc`).
	Do not store them in a script: script sources are always part of `/export`, so the backup password would be mailed along with every export.

	```
	/file add name=backup2mail.conf.rsc contents=":global b2mRecipient \"admin@example.com\"\r\n:global b2mBackupPassword \"CHANGE-ME\"\r\n:global b2mHealthcheckUrl \"\"\r\n:global b2mMailDownloadKey true"
	```

	Alternatively edit [backup2mail.conf.example.rsc](backup2mail.conf.example.rsc) locally and upload it as `backup2mail.conf.rsc` via WinBox or SCP.

	- `b2mHealthcheckUrl` is optional. Set it to `""` to disable healthcheck pings.
	- `b2mMailDownloadKey` (default `true`) adds the cloud backup's secret download key to the mail. You need it to restore the backup onto replacement hardware. The key only allows downloading the *encrypted* backup, so store `b2mBackupPassword` in your password manager and nowhere else.

	**Upgrading from an older version:** create the file as shown above and rotate the backup password, since it was part of every previous export. This applies to both older variants:
	- password stored in the script `backup2mail.conf`: also remove that script with `/system script remove backup2mail.conf`
	- password hardcoded directly in `backup2mail` (versions before October 2026): updating the script removes it, but older exports still contain it

	**Note:** the mailed export still contains the source of *all other* scripts. Do not put credentials into any script source.

4. Create schedulers

	```
	/system scheduler
	add name=upgrade-routeros on-event=upgrade-routeros start-time=04:00:00 interval=1d
	add name=upgrade-firmware on-event=":delay 30s\n/system script run upgrade-firmware" start-time=startup
	add name=backup2mail on-event=backup2mail start-time=06:00:00 interval=4w
	```

## Download RouterOS Packages & Upgrade CAPs on CAPsMAN

1. Download **download-caps-routeros** and **upgrade-caps**

	```
	/system script
	:foreach Script in={ "download-caps-packages";
	                     "upgrade-caps"  } do={
	    :if ([:len [ find where name=$Script ]] = 0) do={ add name=$Script }
	    set numbers=[find where name=$Script] source=([ \
	        /tool fetch \
	        url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/$Script.rsc" \
	        check-certificate=yes output=user as-value]->"data");
	};
	```

2. Add a scheduler

	```
	/system scheduler
	add name=download-caps-packages on-event=":delay 120s\
	    \n/system script run download-caps-packages" start-time=startup
	add name=upgrade-caps comment="Upgrade CAPs every Monday" \
	    on-event=upgrade-caps \
        start-date=2025-01-06 start-time=04:00:00 interval=1w
	```

3. Set the Package-Path

	```
	/caps-man manager
	set package-path=/___/capsman-routeros upgrade-policy=none
	```

4. Optional: Add the [upgrade-firmware script](https://github.com/sebastian13/mikrotik-routeros-scripts/blob/main/upgrade-firmware.rsc) to the cap and set a startup scheduler:

    ```
    /system script
	:foreach Script in={ "upgrade-firmware"  } do={
	    :if ([:len [ find where name=$Script ]] = 0) do={ add name=$Script }
	    set numbers=[find where name=$Script] source=([ \
	        /tool fetch \
	        url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/$Script.rsc" \
	        check-certificate=yes output=user as-value]->"data");
	};
	/system scheduler
	add name=upgrade-firmware on-event=":delay 30s\n/system script run upgrade-firmware" start-time=startup
    ```
