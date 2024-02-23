FROM ubuntu
# Configure these variable to your liking
ENV USERNAME=ubuntu
ENV HOMEDIR=/root
ENV REPO="https://raw.githubusercontent.com/cconstab/sshnpd_config/main"
ENV SSHNPD_IMAGE="https://github.com/atsign-foundation/noports/releases/latest/download/sshnp-linux-x64.tgz"
# Setup enviroment
RUN \
apt update ; \
apt install tmux openssh-server curl -y ;\
mkdir /run/sshd ; \
adduser --disabled-password --gecos "" $USERNAME
USER $USERNAME
RUN \
echo $USERNAME ;\
cd ; \
pwd ; \
curl -fSL ${SSHNPD_IMAGE} -o sshnp.tgz ; \
tar zxvf sshnp.tgz ;\
sshnp/install.sh tmux sshnpd ;\
curl --output ~/.local/bin/sshnpd.sh ${REPO}/config/sshnpd.sh ; \
rm -r sshnp ; \
rm sshnp.tgz
USER root
RUN \
cd ;\
curl --output ~/startup.sh ${REPO}/startup.sh ; \
chmod 755 startup.sh
WORKDIR ${HOMEDIR}
# Started sshd/sshnpd and have a shell if interactive 
# container or sleep forever if backgrounded 
ENTRYPOINT "./startup.sh" ${USERNAME} 