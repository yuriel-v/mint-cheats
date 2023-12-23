#!/usr/bin/bash
#
# Wacom tablet fixing script
#
# This just maps the drawing pad to the first monitor and rotates it 180 deg.
# My pad in particular is rotated due to physical positioning on my desk and
# I don't exactly use it on the second monitor either.
#
# No need to run as root, but depends on xserver-xorg-input-wacom package.

# Which monitor to output to (default 'HEAD-0')
output="HEAD-0"

# Which orientation to rotate it to (default 'half')
orientation="half"

if ! $(which xsetwacom >/dev/null); then
    printf "[!] Command 'xsetwacom' not found.\n"
    printf -- "- Please install it with 'sudo apt install xserver-xorg-input-wacom'.\n"
    exit 1
fi

init_prompt=$(cat <<- EOF
== Wacom tablet setup utility ==
- Current settings:
  - Map to output: '$output'
  - Rotation orientation: '$orientation'
> Proceed? [y/N]: 
EOF
)
printf -- "$init_prompt"
read -n1 confirm

if ! [[ "$confirm" =~ "[yY]" ]]; then
    printf "\nAborting.\n"
    exit 0
fi

# This part could do with some work. What if I have multiple devices?
# For now, the first one will do, as I only own one pad.
printf -- "\n- Getting device ID... "
dev_id=$(xsetwacom --list devices | grep -i stylus | egrep -o "id: [0-9]+" | egrep -o "[0-9]+$")
if [ -z "$dev_id" ]; then
    printf "failed. Please plug the pad in and try again.\n"
    exit 2
else
    printf "done.\n"
fi

printf -- "- Checking rotation... "
if [ $(xsetwacom get $dev_id Rotate) = "$orientation" ]; then
    printf "OK.\n"
else
    printf "done. Rotating to '$orientation'... "
    if $(xsetwacom set $dev_id Rotate $orientation); then
        printf "done.\n"
    else
        printf "error. Aborting.\n"
        exit 3
    fi
fi

printf -- "- Mapping to output '$output'... "
if $(xsetwacom set $dev_id MapToOutput "$output"); then
    printf "done.\n"
else
    printf "error. Aborting.\n"
    exit 4
fi

printf -- "- All tasks done.\n"

