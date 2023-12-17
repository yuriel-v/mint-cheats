#!/usr/bin/bash
#
# Essentials
#
# Basically just a list of packages and stuff to help set up gaming related
# dependencies and others, nothing much
#
# As usual, run as root.
#
# Some packages need to be ran in user mode (e.g. spicetify, proton), these
# will be covered in another script.

packages=$(apt list --installed 2>/dev/null)

has_package() {
    result=$(grep -q "$1" <<< ${packages})
    return result
}

yeet() {  # BEHEHE
    printf "fail. Aborting.\n"
    exit $1
}

if [ $UID -ne 0 ]; then
    printf "Please run this as root. Aborting.\n"
    exit 1
fi

# Wine + Winetricks
ubuntu_version=$(grep "UBUNTU_CODENAME" /etc/os-release | grep -o [^=]*$)
printf "> Installing Wine (stable) and Winetricks... "

if has_package 'winehq-stable'; then
    printf "pass.\n"
else
    printf "fail. Installing... "
    dpkg --add-architecture i386
    mkdir -pm755 /etc/apt/keyrings
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${ubuntu_version}/winehq-jammy.sources"
    if apt-get update -qq && \
    apt-get install -y -qq --install-recommends winehq-stable && \
    apt-get install -y -qq --install-recommends winetricks; then
        printf "done.\n"
    else
        yeet 1
    fi
fi

# Steam and Discord
printf "> Installing Steam... "
apt-get update -qq  # in case cache wasn't updated in previous step
if has_package 'steam'; then
    printf "pass.\n"
else
    if apt-get install -y -qq steam; then
        printf "done.\n"
    else
        yeet 2
    fi
fi

printf "> Installing Discord... "
if has_package 'discord'; then
    printf "pass.\n"
else
    wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
    if apt-get install -y -qq /tmp/discord.deb; then
        printf "done.\n"
    else
        yeet 3
    fi
fi

# Spotify
printf "> Installing Spotify... "
if has_package 'spotify-client'; then
    printf "pass.\n"
else
    if apt-get install -y -qq spotify-client; then
        printf "done.\n"
    else
        yeet 4
    fi
fi

# Other (non-)CLI essentials
printf "> Ensuring other essentials are installed... "
essentials=( '7zip' 'tar' 'zip' 'unzip' 'git' 'gpg' 'gcc' 'g++' 'make' )
if apt-get install -y -qq "${essentials[@]}"; then
    printf "done.\n"
else
    yeet 5
fi

