#!/usr/bin/bash
# Xbox Controller fix script
#
# So, my controller at the moment I write this is a cheapo Xbox 360 type,
# but for some fucking reason it gets listed on Linux as a PS3 controller.
# Bizarre.
#
# So I elaborated this script to automate things a bit, though the fact that
# it messes with dbus means it requires a reboot to take effect.
#
# Also, this is not idempotent (yet), so it resets all affected files:
# - systemd service unit
# - dbus override config
# - start script file
# If you modified any of these, make sure to back this up beforehand!
#
# Run as root!

start_script_path=/opt/xboxctl-fix

check_xboxdrv() {
    local result=$(apt list --installed 2>/dev/null | grep -q xboxdrv)
    return $result
}

if [ $UID -ne 0 ]; then
    printf "Run this as root, otherwise it will have no effect!\nAborting.\n"
    exit 1
fi

init_prompt=$(cat <<- EOF
== Xbox controller fix utility ==
- This utility will do the following tasks:
  - Install the package 'xboxdrv' if missing;
  - Add a dbus override config file (reboot needed);
  - Install a systemd service to run the utility on boot.
> Proceed? [y/N]: 
EOF
)
printf -- "$init_prompt"
read -n1 confirm

if ! [[ "$confirm" =~ "[yY]" ]]; then
    printf "\nAborting.\n"
    exit 0
fi

printf -- "- Checking if 'xboxdrv' package is present... "
if check_xboxdrv; then
    printf "pass.\n"
else
    printf "fail. Installing... "
    if apt-get update -qq && apt-get install -qq -y xboxdrv && check_xboxdrv;
    then
        printf "done.\n"
    else
        printf "Failed! Aborting.\n"
        exit 1
    fi
fi

printf -- "- Adding dbus override to xboxdrv daemon... "
cat > /etc/dbus-1/system.d/org.seul.Xboxdrv.conf <<- EOF
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus
Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy context="default">
    <allow own="org.seul.Xboxdrv"/>
  </policy>
</busconfig>
EOF
printf "done.\n"

printf -- "- Writing start script to '${start_script_path}'... "
mkdir -p "$start_script_path"
cat > "${start_script_path}/start.sh" <<- EOF
#!/usr/bin/bash
# Configuring xbox controller fix

if \$(lsmod | grep -q xpad); then
    rmmod xpad;
fi
xboxdrv --silent --detach-kernel-driver --daemon --detach --type xbox360
EOF
printf "done.\n"

printf -- "- Writing SystemD service file and enabling it... "
cat > /etc/systemd/system/xboxctl-fix.service <<- EOF
[Unit]
Description=XBox controller fix
After=network.target

[Service]
User=root
Group=root
Type=oneshot
ExecStart=${start_script_path}/start.sh
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --quiet xboxctl-fix
printf "done.\n"

printf -- "\n- All tasks have been complete. Reboot for them to take effect.\n"
