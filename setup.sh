#!/bin/bash

if [ ! -d "dgamelaunch" ]
    then
    git clone https://github.com/paxed/dgamelaunch.git
fi
sudo apt install -y build-essential automake autogen autoconf make libncurses5 libncurses5-dev bison flex libsqlite3-0 libsqlite3-dev libncursesw5 libncursesw5-dev sqlite3

cd dgamelaunch
./autogen.sh "--with-config-file=/opt/mzorpg/etc/dgamelaunch.conf" --enable-shmem --enable-sqlite
make
sudo ../dgl/dgl-create-chroot

