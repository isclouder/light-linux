#!/bin/bash

PATH_CRT=`pwd`
PATH_BROOT="${PATH_CRT}/buildroot-2015.11.1"
PATH_OUT="${PATH_CRT}/out"

build_rootfs(){
    cd ${PATH_BROOT}
    cp ${PATH_CRT}/config/buildroot_config_x86 .config
    make
    [ $? -ne 0 ] && exit 1
}

do_edit_rootfs(){
    echo "This is a test file" > ${PATH_BROOT}/output/images/rootfs/etc/mytestfile
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
    do_edit_rootfs
    #
    cd ${PATH_BROOT}/output/images/rootfs
    find . | cpio --quiet -o -H newc > ../rootfs.cpio
}

build_kernel(){
    cd ${PATH_BROOT}
    BR_BINARIES_DIR=${PATH_BROOT}/output/images /usr/bin/make -j4 HOSTCC="/usr/bin/gcc" HOSTCFLAGS="" ARCH=x86_64 INSTALL_MOD_PATH=${PATH_BROOT}/output/target CROSS_COMPILE="${PATH_BROOT}/output/host/usr/bin/x86_64-buildroot-linux-gnu-" DEPMOD=${PATH_BROOT}/output/host/sbin/depmod -C ${PATH_BROOT}/output/build/linux-4.3 bzImage
    [ $? -ne 0 ] && exit 1
    cp ${PATH_BROOT}/output/build/linux-4.3/arch/x86/boot/bzImage ${PATH_OUT}/
}

rm -rf ${PATH_OUT}; mkdir ${PATH_OUT}
build_rootfs
edit_rootfs
build_kernel
cd ${PATH_CRT}
