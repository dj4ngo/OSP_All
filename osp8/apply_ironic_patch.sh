#!/bin/bash
# git diff -U2 248a4ac4273809db094e9c1ef748c7f9bb260cdd drivers/modules/ssh.py> ./../../OSP/ssh.py.patch 

sudo patch -p0 < ssh.py.patch   /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py
sudo python -m compileall /usr/lib/python2.7/site-packages/ironic/drivers/modules/ssh.py
