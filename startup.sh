#!/bin/bash
ssh-keygen -A
/usr/sbin/sshd -D -o "ListenAddress 127.0.0.1" -o "PasswordAuthentication no"  &
su - $1 sh -c "/usr/bin/tmux new-session -d -s sshnpd && tmux send-keys -t sshnpd /home/ubuntu/.local/bin/sshnpd.sh C-m" 
su - $1
su - $1 sh -c "sleep infinity"
