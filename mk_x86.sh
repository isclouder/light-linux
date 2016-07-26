#!/bin/bash

PATH_CRT=`pwd`
PATH_SOURCE="${PATH_CRT}/source"
PATH_BROOT="${PATH_CRT}/buildroot-2015.11.1"
PATH_OUT="${PATH_CRT}/out"
VERSION=`cat ${PATH_CRT}/VERSION`
DATE=`date -d today +"%Y%m%d%H%M"`

build_rootfs(){
    cd ${PATH_BROOT}
    cp ${PATH_CRT}/config/buildroot_config_x86 .config
    make
    [ $? -ne 0 ] && exit 1
}

edit_installer_rootfs(){
    cat >> ${PATH_BROOT}/output/images/rootfs/etc/network/interfaces << EOF
auto enp1s0
iface enp1s0 inet dhcp
EOF
    echo ${VERSION}-${DATE} > ${PATH_BROOT}/output/images/rootfs/etc/os-release
    cp -dpR ${PATH_SOURCE}/rootfs_installer/* ${PATH_BROOT}/output/images/rootfs/
}

edit_target_rootfs(){
    cat >> ${PATH_BROOT}/output/images/rootfs/etc/network/interfaces << EOF
auto enp1s0
iface enp1s0 inet dhcp
EOF
    sed -i "/pulse-access/ s/$/,root/" ${PATH_BROOT}/output/images/rootfs/etc/group
    sed -i  "/#PermitRootLogin/ c\PermitRootLogin yes" ${PATH_BROOT}/output/images/rootfs/etc/ssh/sshd_config
    echo ${VERSION}-${DATE} > ${PATH_BROOT}/output/images/rootfs/etc/os-release
    cp -dpR ${PATH_SOURCE}/rootfs_target/* ${PATH_BROOT}/output/images/rootfs/
}

edit_rootfs(){
    cd ${PATH_BROOT}
    rm -rf output/images/rootfs; mkdir output/images/rootfs
    cp output/images/rootfs.cpio output/images/rootfs
    [ $? -ne 0 ] && exit 1
    mv output/images/rootfs.cpio output/images/rootfs.bak.cpio
    cd output/images/rootfs
    cpio -idmv < rootfs.cpio; rm rootfs.cpio
    #now do yourself
    if [ "$1" = "0" ];then
      edit_installer_rootfs
    else
      edit_target_rootfs
    fi
    #
    cd ${PATH_BROOT}/output/images/rootfs
    find . | cpio --quiet -o -H newc > ../rootfs.cpio
}

build_kernel(){
    cd ${PATH_BROOT}
    BR_BINARIES_DIR=${PATH_BROOT}/output/images /usr/bin/make -j4 HOSTCC="/usr/bin/gcc" HOSTCFLAGS="" ARCH=x86_64 INSTALL_MOD_PATH=${PATH_BROOT}/output/target CROSS_COMPILE="${PATH_BROOT}/output/host/usr/bin/x86_64-buildroot-linux-gnu-" DEPMOD=${PATH_BROOT}/output/host/sbin/depmod -C ${PATH_BROOT}/output/build/linux-4.3 bzImage
    [ $? -ne 0 ] && exit 1
}

create_iso(){
    cd ${PATH_CRT}
    cp -R ${PATH_BROOT}/output/images/efi-part/EFI/ ${PATH_OUT} 
    cp -dpR ${PATH_SOURCE}/bootloader/EFI/* ${PATH_OUT}/EFI/ 
    mkisofs -V "light-linux" -l -J -L -r -o mcos-client-${VERSION}-${DATE}.iso ${PATH_OUT} 
}

copy_app(){
    cp -R ${PATH_SOURCE}/app ${PATH_OUT}
}

rm -rf *.iso
rm -rf ${PATH_OUT}; mkdir ${PATH_OUT}
build_rootfs
edit_rootfs 0
build_kernel
mv ${PATH_BROOT}/output/images/rootfs.cpio output/images/rootfs.installer.cpio
mv ${PATH_BROOT}/output/images/rootfs.bak.cpio output/images/rootfs.cpio
mv ${PATH_BROOT}/output/build/linux-4.3/arch/x86/boot/bzImage ${PATH_OUT}/
edit_rootfs 1
build_kernel
mv ${PATH_BROOT}/output/images/rootfs.cpio output/images/rootfs.target.cpio
mv ${PATH_BROOT}/output/images/rootfs.bak.cpio output/images/rootfs.cpio
mv ${PATH_BROOT}/output/build/linux-4.3/arch/x86/boot/bzImage ${PATH_OUT}/bzImage_target
copy_app
create_iso
cd ${PATH_CRT}
