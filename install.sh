#!/bin/bash
# Configure these variable to your liking
export USERNAME=ubuntu
export PASSWORD="changeme"
export CONFIG_URL="https://raw.githubusercontent.com/cconstab/sshnpd_config/main/config/sshnpd.sh"
export ATKEYS_URL=""
# Single atSign or comma delimited list
export MANAGER_ATSIGN="@cconstab"
export DEVICE_ATSIGN="@ssh_1"
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
su -c ' \
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
echo $USERNAME ;\
cd ; \
mkdir -p ~/.local/bin ; \
mkdir -p ~/.atsign/keys ; \
curl -fSL $SSHNPD_IMAGE -o sshnp.tgz ; \
tar zxvf sshnp.tgz ;\
sshnp/install.sh tmux sshnpd ;\
curl --output ~/.local/bin/sshnpd.sh ${CONFIG_URL} ; \
rm -r sshnp ; \
rm sshnp.tgz' $USERNAME
####################################################################
# Start sshnpd, the crontab entry will do this on rebot            #
####################################################################
su - $USERNAME sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 

