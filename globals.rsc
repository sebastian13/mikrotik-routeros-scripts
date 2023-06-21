# +------------------------------+
# |                              |
# |  Mikrotik RouterOS Scripts   |
# |     __Global Variables__     |
# |                              |
# +------------------------------+
#  https://github.com/sebastian13/mikrotik-routeros-scripts
#

:global replaceChar do={
  :for i from=0 to=([:len $1] - 1) do={
    :local char [:pick $1 $i]
    :if ($char = $2) do={
      :set $char $3
    }
    :set $output ($output . $char)
  }
  :return $output
}

:global identity [ /system identity get name ]
:global identitySlug [ $replaceChar [ /system identity get name ] " " "" ]

:local date [ $replaceChar [ /system/clock/get date ] "-" "" ]
:local time [ $replaceChar [ /system/clock/get time ] ":" "" ]
:global timestamp ($date.$time)
