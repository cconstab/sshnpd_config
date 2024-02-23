#!/bin/bash
# generate the sshd Keys
ssh-keygen -A
# Start sshd listening on localhost and with no password auth
/usr/sbin/sshd -D -o "ListenAddress 127.0.0.1" -o "PasswordAuthentication no"  &
# Start sshnpd
su - $1 sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 
#
# If docker is run interactively then start a shell
su - $1
# If the shell ends fine but Control C will stop the container.
echo "To shutdown container press Control C"
# If docker is run in the background just sleep
su - $1 sh -c "/usr/bin/sleep infinity"
