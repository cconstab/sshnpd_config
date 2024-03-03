#!/bin/bash
# Configure these variable to your liking
export USERNAME=ubuntu
export PASSWORD="changeme"
export CONFIG_URL="https://raw.githubusercontent.com/cconstab/sshnpd_config/main/config/sshnpd.sh"
# Remember to encrypt your keys!!!!
# Encrypt with
# openssl enc -aes-256-cbc -pbkdf2 -iter 1000000 -salt -in ~/.atsign/keys/@ssh_1_key.atKeys -out @ssh_1_key.atKeys.aes
# Test decrypt with
# openssl aes-256-cbc -d -salt -pbkdf2 -iter 1000000 -in ./@ssh_1_key.atKeys.enc -out ./@ssh_1_key.atKeys
export ATKEYS_URL="http://192.168.1.61:8080/@ssh_1_key.atKeys.aes"
# This is the AES password you used to encrypt the above file
export ATKEY_PASSWORD="helloworld"
# Single atSign or comma delimited list
export MANAGER_ATSIGN="@cconstab"
export DEVICE_ATSIGN="@ssh_1"
export DEVICE_NAME="$(hostname)"
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
curl -fSL $SSHNPD_IMAGE -o sshnp.tgz ; \
tar zxvf sshnp.tgz ;\
sshnp/install.sh tmux sshnpd ;\
curl --output ~/.local/bin/sshnpd.sh ${CONFIG_URL} ; \
sed -i "s/MANAGER_ATSIGN/$MANAGER_ATSIGN/" ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_ATSIGN/$DEVICE_ATSIGN/" ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_NAME/$DEVICE_NAME/"  ~/.local/bin/sshnpd.sh ; \
rm -r sshnp ; \
rm sshnp.tgz atKeys.aes' $USERNAME
####################################################################
# Start sshnpd, the crontab entry will do this on rebot            #
####################################################################
su - $USERNAME sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 

