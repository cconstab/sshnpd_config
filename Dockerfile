FROM ubuntu
# Configure these variable to your liking
ENV USERNAME=ubuntu
ENV HOMEDIR=/root
ENV REPO="https://raw.githubusercontent.com/cconstab/sshnpd_config/main"
# Build image
RUN set -eux; \
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