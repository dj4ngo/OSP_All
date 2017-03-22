#!/bin/bash
if [ ! -f ~/stackrc ]; then
    echo "No stackrc file found"
    exit 1
else
    source ~/stackrc
fi

# Cleanup
sudo sed -i -e '/10\.20\.0\..*localdomain/d' /etc/hosts

# Add hosts
nova list | \
	awk '/ACTIVE/ {split($12,x,"="); split($4,y,"-"); printf("%-15s %s.localdomain %s %s%s %s\n", x[2], $4, $4, y[4], y[5], $4)}' | \
	sort -t- -k 4,4r -k5,5n | \
	sed -e 's/krynn.//3' -e 's/-\([0-9]\)$/\1/' |\
	sudo tee -a /etc/hosts

if [ -f $HOME/.ssh/config ]; then
	/bin/mv -fv $HOME/.ssh/config $HOME/.ssh/config.orig
fi
cat > $HOME/.ssh/config << EOF
Host *
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
        LogLevel quiet
        User heat-admin
EOF
