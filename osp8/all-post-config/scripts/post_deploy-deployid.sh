#!/bin/bash
#
set -x ; VLOG=/var/log/ospd/post_deploy-deployid.log ; exec &> >(tee -a "${VLOG}")

echo "extra_update $deploy_identifier" >> /var/log/ospd/extra_update
echo "$(date)" >> /var/log/ospd/extra_update
