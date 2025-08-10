# Mikrotik Blocklist & Address Lists Downloader

:warning: DISCLAIMER: Never run any /import script you have not verified. Never use a schedule to download and /import scripts you do not control! The scripts might change. They might be used for malicous activities in the future!

Mikrotik devices are fairly capable of running the following script. There's no need for a server preprocessing the lists. On slower mipsbe devices the script might take a few minutes, on ccr or newer arm devices it will take a few seconds.

The script will not delete any address, rather, it sets a timeout of 26h when creating. Thus, updating the address list once a day is recommended.

```
# Download
{
    :local script update-blocklist
    /system script
    :if ([:len [ find where name=$script ]] = 0) do={ add name=$script policy=read,write comment="github.com/sebastian13" }
    set numbers=[find where name=$script] source=([ \
    /tool fetch \
    url="https://raw.githubusercontent.com/sebastian13/mikrotik-routeros-scripts/main/firewall/$script.rsc" \
        output=user as-value]->"data");
}

# Set Schedule
{
    :local script update-blocklist
    /system/scheduler/
    add name=$script policy=read,write interval=1d start-time=05:15:00 on-event="$script"
}

# Set raw block rule. They need to be enabled manually.
/ip/firewall/raw/
add disabled=yes action=drop chain=prerouting in-interface-list=WAN log=yes log-prefix="DROP BLOCKLISTED OUT" src-address-list=blacklist
add disabled=yes action=drop chain=output dst-address-list=blacklist log=yes log-prefix="DROP BLOCKLISTED IN" out-interface-list=WAN
```

### Ressources

- Scripts by Shumkov, https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640
