/ip firewall address-list

:local update do={
    
    # Create an index of currently blocklisted IPs
    :local blocklisted
    :put "Querying currently blocklisted IPs of $description. This may take a few seconds ..."
    :foreach id in=[find list=blocklist description=$description] do={
        :set ($blocklisted->[get $id address]) $id
    }

    :do {
        :local data
        :if ([:len $httpAuth] > 0) do={
            :set data ([:tool fetch url=$url mode=https http-auth-scheme=$httpAuth user=$user \
                         password=$password idle-timeout="30s" output=user as-value]->"data")
        } else={
            :set data ([:tool fetch url=$url mode=https output=user as-value]->"data")
        }
        :set data ($data . "\n")

        :while ([:len $data] != 0) do={
            :local nl [:find $data "\n"]
            :local line [:pick $data 0 $nl]
            :set data [:pick $data ($nl+1) [:len $data]]

            :local skip false

            # Skip empty or command lines
            :if ([:len $line] = 0) do={ :set skip true }
            :if ([:pick $line 0 1] = "#") do={ :set skip true }
            :if ([:pick $line 0 1] = ";") do={ :set skip true }

            :local delp [:find $line $delimiter]
            :if ([:typeof $delp] = "nil") do={ :set delp [:len $line] }

            :local addr [:pick $line 0 $delp]

            :local delp [:find $line $delimiter]
            :if ([:len $delimiter] = 0) do={ 
                :set delp [:len $line] 
            } else={
                :if ([:typeof $delp] = "nil") do={ :set delp [:len $line] }
            }

            :local addr [:pick $line 0 $delp]

            # Skip invalid IPs
            :if (!($addr ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}")) do={ :set skip true }

            # Skip 0.0.0.0
            :if ($addr = "0.0.0.0" || $addr = "0.0.0.0/0") do={ :set skip true }

            # Add CIDR if defined
            :if ([:typeof [:find $addr "/"]] = "nil") do={
                :if ([:len $cidr] > 0) do={ :set addr ($addr . $cidr) }
            }

            :if ($skip = false) do={
                :local existing ($blocklisted->"$addr")

                :if ([:typeof $existing] = "nothing" || [:typeof $existing] = "nil") do={
                    :put ("  * Adding " . $addr . " to blocklist " . $description)
                    :do { add list=blocklist address=$addr comment=$description timeout=26h } on-error={}
                    :log info message="Added $addr to address list blocklist, reported by $description."
                } else={
                    :put ("  > Update " . $addr . " in blocklist " . $description)
                    set $existing comment=$description timeout=26h
                }
            }
        }
    }
    :put "Blocklist $description was imported sucessfully."
    :put ""
}

$update url=https://www.dshield.org/block.txt description=DShield delimiter=("\t") cidr="/24"
$update url=https://www.spamhaus.org/drop/drop.txt description=Spamhaus delimiter=" " cidr=""

# Example: Basic Authentication 
# Crowdsec Raw Integration
# :local crowdsecUsername ""
# :local crowdsecPassword ""
# :local crowdsecRawUrl "https://admin.api.crowdsec.net/v1/integrations/___/content"
# $update url=$crowdsecRawUrl httpAuth=basic user=$crowdsecUsername password=$crowdsecPassword description=CrowdSec delimiter="" cidr=""
