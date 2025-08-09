/ip firewall address-list

:local update do={
    
    # Create an index of currently blacklisted IPs
    :local blacklisted
    :put "Querying currently blacklisted IPs. This may take a few seconds ..."
    :foreach id in=[find list=blacklist description=$description] do={
        :set ($blacklisted->[get $id address]) $id
    }

    :do {
        :local data ([:tool fetch url=$url mode=https output=user as-value]->"data")
        :set data ($data . "\n")

        :while ([:len $data] != 0) do={
            :local nl [:find $data "\n"]
            :local line [:pick $data 0 $nl]
            :set data [:pick $data ($nl+1) [:len $data]]

            :local skip false
            :if ([:len $line] = 0) do={ :set skip true }
            :if ([:pick $line 0 1] = "#") do={ :set skip true }
            :if ([:pick $line 0 1] = ";") do={ :set skip true }

            :if ($skip = false) do={
                :local delp [:find $line $delimiter]
                :if ([:typeof $delp] = "nil") do={ :set delp [:len $line] }

                :local addr [:pick $line 0 $delp]

                :local isIP false
                :if ($addr ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}") do={ :set isIP true }

                :if ($isIP = true) do={
                    :if ([:typeof [:find $addr "/"]] = "nil") do={
                        :if ([:len $cidr] > 0) do={ :set addr ($addr . $cidr) }
                    }

                    :if ([:pick $addr 0 8] = "0.0.0.0") do={
                        :put "skip 0.0.0.0"
                    } else={

                        :local existing ($blacklisted->"$addr")

                        :if ([:typeof $existing] = "nothing" || [:typeof $existing] = "nil") do={
                            :put ("Adding " . $addr . " to blacklist of " . $description)
                            :do { add list=blacklist address=$addr comment=$description timeout=1d } on-error={}
                        } else={
                            :put ("Update Timeout of " . $addr . " in " . $description)
                            set $existing comment=$description timeout=1d
                        }
                    }
                }
            }
        }
    }
}

$update url=https://www.dshield.org/block.txt description=DShield delimiter=("\t") cidr="/24"
#$update url=https://www.spamhaus.org/drop/drop.txt description="Spamhaus" delimiter=" " cidr=""
