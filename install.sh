#!/bin/bash
# Configure these variable to your liking or pass in args
if [ $# -ne 8 ]
then
# USERNAME & PASSWORD created with sudo priviledges by install.sh
export USERNAME="ubuntu"
export PASSWORD="changeme"
# URL of the config/sshnpd.sh file contained in this repo (this will change if repo is cloned)
export CONFIG_URL="https://gist.githubusercontent.com/cconstab/142c942ce0c8caa3348d0976a60fbfd1/raw/d243d64573bf2b7de5e827ff9b7b7f2f2413901b/gistfile1.txt"
# Remember to encrypt your keys!!!!
# Encrypt with
# openssl enc -aes-256-cbc -pbkdf2 -iter 1000000 -salt -in ~/.atsign/keys/@ssh_1_key.atKeys -out @ssh_1_key.atKeys.aes
# Test decrypt with
# openssl aes-256-cbc -d -salt -pbkdf2 -iter 1000000 -in ./@ssh_1_key.atKeys.aes -out ./@ssh_1_key.atKeys
export ATKEYS_URL="https://filebin.net/cpme4bhrqolyrnts/_ssh_1_key.atKeys.aes"
# This is the AES password you used to encrypt the above file
export ATKEY_PASSWORD="helloworld12345!"
# Manager atSign either a Single atSign or comma delimited list from sshnpd v5.0.3
export MANAGER_ATSIGN="@cconstab"
export DEVICE_ATSIGN="@ssh_1"
export DEVICE_NAME="$(hostname)"
else 
export USERNAME=$1
export PASSWORD=$2
export CONFIG_URL=$3
export ATKEYS_URL=$4
export ATKEY_PASSWORD=$5
export MANAGER_ATSIGN=$6
export DEVICE_ATSIGN=$7
export DEVICE_NAME=$8
fi
####################################################################
# Get machine updated and with the needed packages                 #
####################################################################
apt update
apt install tmux openssh-server curl cron sudo -y 
# create USERNAME with sudo priviledges
useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G sudo ${USERNAME}
####################################################################
# start sshd listening on localhost only                           #
####################################################################
# Update the sshd config so it only runs on localhost
#sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 127.0.0.1/' /etc/ssh/sshd_config
# restart sshd if your OS starts it on install
# e.g on Ubuntu/Debian
#systemctl restart ssh.service
# or Redhat/Centos
#systemctl restart sshd.service
####################################################################
# Start sshd Only needed if sshd is not started by default         #
# for example a docker container                                   #
# Remove these lines if the OS you are using starts up sshd itself #
####################################################################
# File needed for sshd to run
mkdir /run/sshd
# generate the sshd Keys
ssh-keygen -A
# Start sshd listening on localhost and with no password auth 
/usr/sbin/sshd -D -o "ListenAddress 127.0.0.1" -o "PasswordAuthentication no"  &
####################################################################
# Install sshnpd as the selected USERNAME                          #
####################################################################
su --whitelist-environment="MANAGER_ATSIGN,DEVICE_ATSIGN,ATKEY_PASSWORD,ATKEYS_URL,DEVICE_NAME" -c ' \
set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) \
            SSHNPD_IMAGE="https://github.com/atsign-foundation/noports/releases/latest/download/sshnp-linux-x64.tgz" ;; \
        armhf) \
            SSHNPD_IMAGE="https://github.com/atsign-foundation/noports/releases/latest/download/sshnp-linux-arm.tgz" ;; \
        arm64) \
            SSHNPD_IMAGE="https://github.com/atsign-foundation/noports/releases/latest/download/sshnp-linux-arm64.tgz" ;; \
        riscv64) \
            SSHNPD_IMAGE="https://github.com/atsign-foundation/noports/releases/latest/download/sshnp-linux-riscv.tgz" ;; \
        *) \
            echo "Unsupported architecture" ; \
            exit 5;; \
    esac; \
cd ; \
mkdir -p ~/.local/bin ; \
mkdir -p ~/.atsign/keys ; \
curl -fSL ${ATKEYS_URL} -o atKeys.aes ; \
openssl aes-256-cbc -d -salt -pbkdf2 -iter 1000000 -in ./atKeys.aes -out ~/.atsign/keys/${DEVICE_ATSIGN}_key.atKeys --pass env:ATKEY_PASSWORD ; \
chmod 600 ~/.atsign/keys/${DEVICE_ATSIGN}_key.atKeys ; \
curl -fSL $SSHNPD_IMAGE -o sshnp.tgz ; \
tar zxvf sshnp.tgz ;\
sshnp/install.sh tmux sshnpd ;\
curl --output ~/.local/bin/sshnpd.sh ${CONFIG_URL} ; \
sed -i "s/MANAGER_ATSIGN/$MANAGER_ATSIGN/" ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_ATSIGN/$DEVICE_ATSIGN/" ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_NAME/$DEVICE_NAME/"  ~/.local/bin/sshnpd.sh ; \
# Uncomment this if you _want_ to use '-u' for sshnpd ; \
#sed -i "s/# u=\"-u\"/u=\"-u\"/" ~/.local/bin/sshnpd.sh ; \
# Uncomment this if you do _not_ want `-s` enabled (you would need to send ssh keys)
#sed -i "s/s=\"-s\"/# s=\"-s\"/"  ~/.local/bin/sshnpd.sh ; \
rm -r sshnp ; \
rm sshnp.tgz atKeys.aes' $USERNAME
####################################################################
# Start sshnpd, the crontab entry will do this on reboots          #
####################################################################
su - $USERNAME sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 
# Helpful to sleep if using Docker so container stays alive.
# sleep infinity
