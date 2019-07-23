function phone_battery_status --description='Get battery status and level from KDEConnect to display in i3status-rs'

  argparse --name phone_battery_status 'd/device=' -- $argv
  or return 1  #error

  set path "/modules/kdeconnect/devices/$_flag_device"
  set charging (qdbus org.kde.kdeconnect $path org.kde.kdeconnect.device.battery.isCharging)
  set level (qdbus org.kde.kdeconnect $path org.kde.kdeconnect.device.battery.charge)

  if test $level -ge 80
    # battery-full
    set icon ""
  else if test ($level -ge 51) -a ($level -lt 80)
    # battery-three-quarters
    set icon ""
  else if test ($level -ge 26) -a ($level -lt 51)
    # battery-half
    set icon ""
  else if test ($level -ge 11) -a ($level -lt 26)
    # battery-quarter
    set icon ""
  else if test $level -le 10
    # battery-none
    set icon ""
  end

  if test $charging = true
    printf "$icon$level%%"
  else
    printf "$icon$level%%"
  end
end
