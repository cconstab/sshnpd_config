FROM ubuntu
# Configure these variable to your liking
ENV USERNAME=ubuntu
ENV HOMEDIR=/root
ENV MANAGER_ATSIGN="@cconstab"
ENV DEVICE_ATSIGN="@ssh_1"
ENV DEVICE_NAME="$(hostname)"
# Build image
COPY startup.sh /root/startup.sh
COPY config/sshnpd.sh /home/${USERNAME}/.local/bin/sshnpd.sh
RUN \
apt update ; \
apt install tmux openssh-server curl -y ;\
mkdir /run/sshd ; \
adduser --disabled-password --gecos "" $USERNAME ;\
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
USER $USERNAME
RUN \
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
curl -fSL $SSHNPD_IMAGE -o sshnp.tgz ; \
tar zxvf sshnp.tgz ;\
sshnp/install.sh tmux sshnpd ;\
#curl --output ~/.local/bin/sshnpd.sh /config/sshnpd.sh ; \
sed -i "s/MANAGER_ATSIGN/${MANAGER_ATSIGN}/" ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_ATSIGN/${DEVICE_ATSIGN}/"   ~/.local/bin/sshnpd.sh ; \
sed -i "s/DEVICE_NAME/${DEVICE_NAME}/"       ~/.local/bin/sshnpd.sh ; \
chmod 755 ~/.local/bin/sshnpd.sh ; \
ls -l ~/.local/bin/sshnpd.sh ; \
cat ~/.local/bin/sshnpd.sh ; \
rm -r sshnp ; \
rm sshnp.tgz
USER root
RUN \
cd ;\
pwd ; \
chmod 755 startup.sh
WORKDIR ${HOMEDIR}
# Started sshd/sshnpd and have a shell if interactive 
# container or sleep forever if backgrounded 
ENTRYPOINT "./startup.sh" ${USERNAME} 