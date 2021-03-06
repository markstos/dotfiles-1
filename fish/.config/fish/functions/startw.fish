function startw --description 'startx equivalent for starting sway'
    # Encourage programs to use Wayland
    # see: https://github.com/swaywm/sway/wiki/Running-programs-natively-under-wayland
    set --export BEMENU_BACKEND wayland
    set --export CLUTTER_BACKEND wayland

    # GTK3+ will default to Wayland, so do not set otherwise it will break some apps.
    #set --export GDK_BACKEND wayland

    set --export ECORE_EVAS_ENGINE wayland_egl
    set --export ELM_ENGINE wayland_egl
    set --export _JAVA_AWT_WM_NONREPARENTING 1
    set --export MOZ_ENABLE_WAYLAND 1
    set --export MOZ_WAYLAND_USE_VAAPI 1
    set --export QT_QPA_PLATFORM wayland-egl
    set --export QT_WAYLAND_DISABLE_WINDOWDECORATION 1

    # Setting this was preventing Stardew Valley from running
    #set --export SDL_VIDEODRIVER wayland

    # Some programs might (wrongly?) look for this var
    # https://github.com/swaywm/sway/pull/4876
    # However Unity might be better for some apps with tray icons?
    # https://www.reddit.com/r/swaywm/comments/gekpeq/waybar_for_a_functional_tray_install/fpv3i1y/
    if status is-interactive
        and string length --quiet SWAYSOCK
        set --export XDG_CURRENT_DESKTOP sway
    end

    # Enabling this might make systemd-login IdleHints to work
    # (see https://www.reddit.com/r/swaywm/comments/eeavlo/sway_on_arch_does_not_change_session_type)
    # However, it breaks IBus' default canditate window so need to disable it
    # (see https://github.com/google/mozc/issues/431)
    # set --export XDG_SESSION_TYPE wayland

    sway $argv
end