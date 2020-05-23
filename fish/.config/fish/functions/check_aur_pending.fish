function check_aur_pending --description="Return number of pending AUR updates"
    argparse --name check_aur_pending h/help b-barmode -- $argv
    or return 1 # error

    function print_help
        echo "Usage: check_aur_pending [options]"
        echo "Options:"
        echo (set_color green)"--barmode"(set_color $fish_color_normal)": Output text for i3status-rs bar"
    end

    if set -lq _flag_help
        print help
        return
    end

    set MODE std
    if set -lq _flag_barmode
        set MODE bar
    end

    set val (pikaur --query --sysupgrade --aur 2>/dev/null | wc --lines)
    if test $MODE = bar
        if test val -eq 0
            echo "{\"state\": \"Idle\", \"text\": \"$val\"}"
        else
            echo "{\"state\": \"Warning\", \"text\": \"$val\"}"
        end
    else
        echo $val
    end
end
