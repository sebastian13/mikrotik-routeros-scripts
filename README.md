# Mikrotik RouterOS Scripts Collection

**[Backup & Auto Upgrade](#backup-&-auto-upgrade)**<br>
**[Download RouterOS Packages for CAPs](#download-routeros-packages-for-caps-on-a-capsman)**

## Backup & Auto Upgrade

1. Setup SMTP

	```
	/tool e-mail
	set address=smtp.gmail.com from=___@gmail.com port=587 tls=starttls \
	    user=___@gmail.com password=___
	```

2. Download the required scripts, **backup2mail**, **upgrade-firmware**, **upgrade-routeros**

	```
	/system script
	:foreach Script in={ "backup2mail";
	                     "globals";
	                     "slack";
	                     "upgrade-firmware";
	                     "upgrade-routeros"  } do={
	    :if ([:len [ find where name=$Script ]] = 0) do={ add name=$Script }
	    set numbers=[find where name=$Script] source=([ \
	        /tool fetch \
	        url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/$Script.rsc" \
	        output=user as-value]->"data");
	};
	```

3. Create schedulers

	```
	/system scheduler
	add name=upgrade-routeros on-event=upgrade-routeros start-time=04:00:00 interval=1d
	add name=upgrade-firmware on-event=":delay 30s\n/system script run upgrade-firmware" start-time=startup
	add name=backup2mail on-event=backup2mail start-time=06:00:00 interval=4w
	```

## Download RouterOS Packages for CAPs on a CAPsMAN

1. Download **download-caps-routeros**

	```
	/system script
	:foreach Script in={ "download-caps-packages"  } do={
	    :if ([:len [ find where name=$Script ]] = 0) do={ add name=$Script }
	    set numbers=[find where name=$Script] source=([ \
	        /tool fetch \
	        url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/$Script.rsc" \
	        output=user as-value]->"data");
	};
	```

2. Add a scheduler

	```
	/system scheduler
	add name=download-caps-routeros on-event=":delay 120s\
	    \n/system script run download-caps-routeros" start-time=startup
	```

3. Set the Package-Path

	```
	/caps-man manager
	set package-path=/___/capsman-routeros upgrade-policy=suggest-same-version
	```

4. Optional: Add the [upgrade-firmware script](https://github.com/sebastian13/mikrotik-routeros-scripts/blob/main/upgrade-firmware.rsc) to the cap and set a startup scheduler.
