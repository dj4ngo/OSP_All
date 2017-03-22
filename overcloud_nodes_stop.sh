#!/bin/bash

if [ ! -f ~/stackrc ]; then
    echo "No stackrc file found"
    exit 1
else
    source ~/stackrc
fi

nova list|grep krynn|awk '{print $4}'|xargs nova stop
