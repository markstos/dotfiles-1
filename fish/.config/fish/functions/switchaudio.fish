function switchaudio --description 'Switch between audio devices and move all current audio outputs to the new device.'
    # model name of the TV. Can find via `swaymsg -t get_outputs` or `pactl list cards`
    set TV_MODEL_NAME "LG TV"

    function print_help
        echo "Usage: switchaudio [options]"
        echo "Options:"
        echo (set_color green)"-d/--device"(set_color $fish_color_normal)": Switch to the specified device."
        echo (set_color green)"-k/--keep"(set_color $fish_color_normal)": Switch audio device but leave current sinks alone."
        echo (set_color green)"-m/--menu"(set_color $fish_color_normal)": Display menu to choose from."
    end

    argparse --name switchaudio h/help m/menu k/keep 'd/device=' -- $argv
    or return 1 #error

    if set -lq _flag_help
        print_help
        return
    end

    if set -lq _flag_device
        set device $_flag_device
    end

    if set -lq _flag_keep
        set keep_sinks 1
    end

    # use menu by default for now. Add in terminal menu later.
    set use_menu 1
    if set -lq _flag_menu
        set use_menu 1
    end

    function prettify_name --argument-names sink_raw_name
        if string match --quiet '*Pebbles*' $sink_raw_name
            echo speakers
        else if string match --quiet 'alsa_output.pci-0000_00_1b.0.analog-stereo' $sink_raw_name
            echo headphones
        else if string match --quiet '*PCH*' $sink_raw_name
            echo headphones
        else if string match --quiet 'bluez_sink*' $sink_raw_name
            echo bluetooth
        else if string match --quiet 'alsa_output.pci-0000_01_00.1.hdmi-stereo-extra*' $sink_raw_name
            echo TV
        else
            echo $sink_raw_name
        end
    end

    function get_icon --argument-names output_device
        switch $output_device
            case headphones
                echo "🎧"
            case speakers
                echo "🔈"
            case bluetooth
                echo BT
            case TV
                echo "📺"
            case '*'
                echo "??"
        end
    end

    function get_sink_volume --argument-names sink_id
        pacmd list-sinks | grep --after-context=15 "index: $sink_id\$" |
        grep 'volume:' | string match --regex '^((?!base volume:).)*$' |
        string replace --regex --filter ".* (\d+)%.*" '$1'
    end

    set sinks (pactl list short sinks 2> /dev/null)
    if test $status -ne 0
        echo "Error calling pulseaudio" >&2
        return 1
    end
    set default_sink_id (pacmd list-sinks | awk '/* index:/{print $3}')

    if not set --query device
        for sink in $sinks
            set sink_info (string split \t $sink)
            set sink_id $sink_info[1]
            set sink_name (prettify_name $sink_info[2])
            if test $sink_id = $default_sink_id
                set sink_name "$sink_name (current)"
            end
            set device_choices (string join "\n" $device_choices $sink_name)
        end
        set device (echo -e "$device_choices" | bemenu --ignorecase --wrap --prompt "Select new sound output:")
        set device (string split --fields 1 "(current)" -- $device | string trim)
        if not string length --quiet $device
            echo "no device selected"
            return 1
        end
    end

    for sink in $sinks
        set sink_info (string split \t $sink)
        set sink_id $sink_info[1]
        set sink_name (prettify_name $sink_info[2])
        set sink_state $sink_info[5]
        if string match --quiet "$sink_name" "$device"
            set new_default_sink_id $sink_id
            set new_default_sink_name $sink_name
            break
        end
    end

    # If the output we switch to is not set as default then the
    # system volume slider controls will not affect it.
    pactl set-default-sink $new_default_sink_id

    set new_sink_volume (get_sink_volume $default_sink_id)
    if test $new_sink_volume -gt 100
        set new_sink_volume 100
    end
    pactl set-sink-volume $new_default_sink_id "$new_sink_volume%"

    if not set --query keep_sinks
        set inputs (pactl list short sink-inputs)
        for input in $inputs
            set input_id (string split \t $input)[1]
            pactl move-sink-input $input_id $new_default_sink_id
        end
    end

    # For the TV, ensure the card profile is set to the correct HDMI port, otherwise we get no sound.
    if test $new_default_sink_name = TV
        # Get the first profile listed after "Part of profile(s):" for the HDMI port the TV is connected to.
        # Will probably be 'output:hdmi-stereo-extra*'. TODO: Will I ever want the non-stereo profiles?
        set TV_hdmi_port_profile (pactl list cards | \
      grep --after-context=100 "Name: alsa_card.pci-0000_01_00.1" | \
      sed '/Card/Q' | \
      grep --after-context=1 "$TV_MODEL_NAME" | \
      string match --regex '(output:hdmi-[^,]+)')[2]
        or return 1

        set active_profile (pactl list cards | \
                     grep --after-context=100 "Name: alsa_card.pci-0000_01_00.1" | \
                     sed '/Card/Q' | \
                     string match --regex 'Active Profile: (output:hdmi-.+)')[2]

        if test "$TV_hdmi_port_profile" != "$active_profile"
            pactl set-card-profile alsa_card.pci-0000_01_00.1 $TV_hdmi_port_profile
        end
    end

    string length --quiet $new_default_sink_name
    or return 1
end
