#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

create_deb_packages() {
  mkdir -v /tmp/overlay/debs
  for package_script in /tmp/overlay/packages/*; do
    source $package_script
  done
}

create_brcm_symlinks() {
  ln -vs brcmfmac43455-sdio.txt /usr/lib/firmware/brcm/brcmfmac43455-sdio.amlogic,s400.txt
  ln -vs ../BCM4345C0.hcd /usr/lib/firmware/brcm/BCM4345C0.hcd

  ls -lhA /usr/lib/firmware/brcm/brcmfmac43455-sdio.amlogic,s400.txt
  ls -lhA /usr/lib/firmware/brcm/BCM4345C0.hcd
}

install_fw_env_config_generator() {
  # insert fw_env.config generation code into rc.local just before "exit 0"

  local RC_LOCAL=/etc/rc.local
  local RC_LOCAL_NEW=${RC_LOCAL}.new

  while IFS= read -r line; do
    if [[ "$line" =~ ^exit\ 0$ ]]; then
      cat /tmp/overlay/etc/fw_env_generator >> $RC_LOCAL_NEW
      echo >> $RC_LOCAL_NEW
    fi
    echo "$line" >> $RC_LOCAL_NEW
  done < $RC_LOCAL

  chmod -v +x $RC_LOCAL_NEW
  mv -fv $RC_LOCAL_NEW $RC_LOCAL

}

Main() {
  case $RELEASE in
    focal)
      if [[ "$LINUXFAMILY" = "arm-64" ]]; then
        if [[ "$BOARD" = "arm-64" ]]; then
          create_deb_packages
          create_brcm_symlinks
          install_fw_env_config_generator
        fi
      fi
      ;;
  esac
} # Main

Main "$@"
