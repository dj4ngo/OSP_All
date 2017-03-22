#!/bin/bash
#
set -x ; l=firstboot-diskinit ; VLOG=/var/log/ospd/${l%\.sh}.log ; exec &> >(tee -a "${VLOG}")

#
case "$(hostname)" in
  *)
    #
    for i in {b,c,d,e,f,g,h,i,j,k,l,m,n}; do
      if [ -b /dev/sd${i} ]; then
        echo "(II) Wiping disk /dev/sd${i}..."
        sgdisk -Z /dev/sd${i}
        sgdisk -g /dev/sd${i}
      else
        echo "(II) not a block device: /dev/sd${i}"
      fi
    done
  ;;
esac
