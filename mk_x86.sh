#!/bin/bash

PATH_CRT=`pwd`
PATH_BROOT="${PATH_CRT}/buildroot-2015.11.1"

build_rootfs(){
    cd ${PATH_BROOT}
    cp ${PATH_CRT}/config/mcos_config_x86 .config
    make
    [ $? -ne 0 ] && exit 1
}

build_rootfs
cd ${PATH_CRT}
