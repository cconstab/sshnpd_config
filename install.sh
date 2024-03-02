#!/bin/bash
# Configure these variable to your liking
export USERNAME=ubuntu
export PASSWORD="changeme"
export HOMEDIR="/root"
export REPO="https://raw.githubusercontent.com/cconstab/sshnpd_config/main"
####################################################################
# Get machine updated and with the needed packages                 #
####################################################################
apt update
apt install tmux openssh-server curl cron sudo -y 
mkdir /run/sshd
useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G sudo ${USERNAME}
#sudo usermod -a -G sudo $USERNAME"
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
curl --output ~/.local/bin/sshnpd.sh ${REPO}/config/sshnpd.sh ; \
rm -r sshnp ; \
rm sshnp.tgz' $USERNAME
####################################################################
# Start sshd Only needed if sshd is not started by default         #
####################################################################
# generate the sshd Keys
ssh-keygen -A
# Start sshd listening on localhost and with no password auth
/usr/sbin/sshd -D -o "ListenAddress 127.0.0.1" -o "PasswordAuthentication no"  &
####################################################################
# Start sshnpd                                                     #
####################################################################
su - $USERNAME sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 

