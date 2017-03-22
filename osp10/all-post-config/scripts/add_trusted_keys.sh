#!/bin/bash
# Add SSH trusted keys to the root account

#
set -x ; VLOG=/var/log/ospd/post_deploy-add_trusted_keys.log ; exec &> >(tee -a "${VLOG}")

# Payload
SSH_KEY="ssh-dss AAAAB3NzaC1kc3MAAACBANBRLVpEMvN+WhOqoi8agNIrHUXvHHEtbgnVld6mfUy+PQur8RWqKOPZlixU5cHC5jhKpnQxeSiesjln17/zT0qHrf6Swt86yICq2GQ8NViCotQvCyrX3f4/V3L2HEdkisDWdt1gqONjukgf0h3L3pEIqoxaBrdK/DEgq5+br3gZAAAAFQC7UP2p8H1MMcrAX1TWNW0QJEoHUwAAAIA2kjoZA2P2Gbjx+UXwqQUSpdAGSEpL7VF15tlMHhtFocIhTmysy3TJQXVo4EcLmrrJZHgt9dshZcpQpgE0G78vYzLXRy9kXpORIheVrGKK6sfmvy0CFKm9YiQyhTT3D0/UsKbJ/exNOcxN2/IdZEshaSbk67mzMP4AJL5tSQ8dEgAAAIEAlrrl3u9DxOePN+CxK9p4/SHuYLZgb/Qh5PsamWKhqhqsEFF9Cu8/NDeAA9TtL7SS337z/VQbvLuJ+mSPtMD8Z+ZF0YfUwzu16u2FQqCqjoOzEX7/N799i7RLtKSXeSI4x2o6jLydRpi//Ll/hFl4yZhnW7pbSpTR8MeWYY7Qnec= root@lasthome.solace.krynn"

# Create /root/.ssh 
if [ ! -d /root/.ssh ]; then
	mkdir /root/.ssh
	chmod 700 /root/.ssh
fi

# Add publickey to /root/.ssh/authorized_keys
echo ${SSH_KEY} >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

#
sed -i -e 's@^#PermitRootLogin yes@PermitRootLogin yes@'  /etc/ssh/sshd_config
systemctl restart sshd
