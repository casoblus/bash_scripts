#!/bin/bash
version=linux-$1
cd /usr/src
#rm $version.tar.xz*
if [ -d $version ]; 
then
   cp $version/.config $version-config
   rm -r $version
   if ! [ -e $version.tar.xz ];
   then
      wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$version.tar.xz
   fi
   tar -xJf $version.tar.xz 
   cp $version-config $version/.config
else
   if ! [ -e $version.tar.xz ];
   then
      wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$version.tar.xz
   fi
   tar -xJf $version.tar.xz 
fi

#
# INCLUDE AUFS SUPORT
#
if [ "$2" = "--with-aufs" ];
then
   echo "YOU MAY ACTIVATE AUFS-SUPPORT ON MENUCONFIG"
   aufs_version=$(echo $1 | awk -F. '{print $1,$2}' | tr ' ' '.')
   if [ -d aufs4-standalone ];
   then
      rm -r aufs4-standalone
   fi
   echo $aufs_version
   git clone -b aufs$aufs_version --single-branch https://github.com/sfjro/aufs4-standalone.git aufs4-standalone

   cd /usr/src/$version
   #patch -p1 < /usr/src/$version/0001-base-packaging.patch
   #patch -p1 < /usr/src/$version/0002-debian-changelog.patch
   #patch -p1 < /usr/src/$version/0003-configs-based-on-Ubuntu-4.0.2-1.1.patch

   patch -p1 < /usr/src/aufs4-standalone/aufs4-base.patch || exit
   patch -p1 < /usr/src/aufs4-standalone/aufs4-standalone.patch || exit
   patch -p1 < /usr/src/aufs4-standalone/aufs4-mmap.patch || exit
   patch -p1 < /usr/src/aufs4-standalone/aufs4-kbuild.patch || exit

   cp -R /usr/src/aufs4-standalone/Documentation /usr/src/$version || exit
   cp -R /usr/src/aufs4-standalone/fs /usr/src/$version || exit
   cp /usr/src/aufs4-standalone/include/uapi/linux/aufs_type.h /usr/src/$version/include/uapi/linux/. || exit
fi

#configureKernel {
if [ -e linux/.config ]; 
then
   cp linux/.config $version/.config 
   rm linux
   ln -s /usr/src/$version /usr/src/linux
   cd linux
   make oldconfig
   make menuconfig
else
   rm linux
   ln -s /usr/src/$version /usr/src/linux
   cd linux
   make menuconfig
fi

make-kpkg --initrd kernel_image kernel_headers modules -j9
cd ..

echo "Install new kernel now? [s|n]"
read confirm
if [ "$confirm" == "s" ]; then
   dpkg -i linux-*-$1*.deb
else
   echo "You must install package by yourself."
fi

echo "Para comenzar a usar el nuevo kernel deberá reiniciar ¿Reiniciar ahora? [s|n]"
read reb

if [ "$reb" == "s" ]; then
   reboot
else
   cd /home
   echo "¡Unha aperta! ;)"
fi
