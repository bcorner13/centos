#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

<<<<<<< HEAD
if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
    echo "==> Installing VMware Tools"
    cat /etc/redhat-release
    if grep -q -i "release 6" /etc/redhat-release ; then
        # Uninstall fuse to fake out the vmware install so it won't try to
        # enable the VMware blocking filesystem
        yum erase -y fuse
    fi
    if rpm -qa | grep -q open-vm-tools; then
      echo "open-vm-tools already installed";
      exit 0;
    fi
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg
=======
function install_open_vm_tools {
    echo "==> Installing Open VM Tools"
    # Install open-vm-tools so we can mount shared folders
    yum install -y open-vm-tools
    # Add /mnt/hgfs so the mount works automatically with Vagrant
    mkdir /mnt/hgfs
}
>>>>>>> efb623d4eca7a3ba7f484faffd55e99b3abf67c2

function install_vmware_tools {
    echo "==> Installing VMware Tools"
    # Assuming the following packages are installed
    # apt-get install -y linux-headers-$(uname -r) build-essential perl

    cd /tmp
    mkdir -p /mnt/cdrom
    mount -o loop /home/${SSH_USERNAME}/linux.iso /mnt/cdrom

    VMWARE_TOOLS_PATH=$(ls /mnt/cdrom/VMwareTools-*.tar.gz)
    VMWARE_TOOLS_VERSION=$(echo "${VMWARE_TOOLS_PATH}" | cut -f2 -d'-')
    VMWARE_TOOLS_BUILD=$(echo "${VMWARE_TOOLS_PATH}" | cut -f3 -d'-')
    VMWARE_TOOLS_BUILD=$(basename ${VMWARE_TOOLS_BUILD} .tar.gz)
    echo "==> VMware Tools Path: ${VMWARE_TOOLS_PATH}"
    echo "==> VMWare Tools Version: ${VMWARE_TOOLS_VERSION}"
    echo "==> VMware Tools Build: ${VMWARE_TOOLS_BUILD}"

    tar zxf /mnt/cdrom/VMwareTools-*.tar.gz -C /tmp/
    VMWARE_TOOLS_MAJOR_VERSION=$(echo ${VMWARE_TOOLS_VERSION} | cut -d '.' -f 1)
    if [ "${VMWARE_TOOLS_MAJOR_VERSION}" -lt "10" ]; then
        /tmp/vmware-tools-distrib/vmware-install.pl -d
    else
        /tmp/vmware-tools-distrib/vmware-install.pl -f
    fi

    rm /home/${SSH_USERNAME}/linux.iso
    umount /mnt/cdrom
    rmdir /mnt/cdrom
    rm -rf /tmp/VMwareTools-*

    VMWARE_TOOLBOX_CMD_VERSION=$(vmware-toolbox-cmd -v)
    echo "==> Installed VMware Tools ${VMWARE_TOOLBOX_CMD_VERSION}"
}

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
    echo "==> Installing VMware Tools"
    cat /etc/redhat-release
    if grep -q -i "release 6" /etc/redhat-release ; then
        # Uninstall fuse to fake out the vmware install so it won't try to
        # enable the VMware blocking filesystem
        yum erase -y fuse
    fi
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    # On RHEL 5, add /sbin to PATH because vagrant does a probe for
    # vmhgfs with lsmod sans PATH
    if grep -q -i "release 5" /etc/redhat-release ; then
        echo "export PATH=$PATH:/usr/sbin:/sbin" >> $SSH_USER_HOME/.bashrc
    fi

    if [ "${MAJOR_VERSION}" -ge "4" ] && [ "${MINOR_VERSION}" -ge "1" ]; then
      install_open_vm_tools
    else
      install_vmware_tools
    fi

    echo "==> Removing packages needed for building guest tools"
    yum -y remove gcc cpp libmpc mpfr kernel-devel kernel-headers
fi
