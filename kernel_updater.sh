#!/bin/bash

version=linux-$1

cd /usr/src

wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$version.tar.xz

tar -xJf $version.tar.xz 

if [ test -x linux/.config ]; then
   cp linux/.config $version/.config 
   rm linux
   ln -s /usr/src/$version /usr/src/linux
   cd linux
   make oldconfig
else
   rm linux
   ln -s /usr/src/$version /usr/src/linux
   cd linux
   make menuconfig
fi

make-kpkg --initrd kernel_image kernel_headers modules -j9

cd ..

echo "¿Instalar ahora el nuevo kernel? [s|n]"
read confirm
if [ "$confirm" == "s" ]; then
   dpkg -i linux-*-$1*.deb
else
   echo "Deberá instalar el paquete a mano."
fi

echo "Para comenzar a usar el nuevo kernel deberá reiniciar ¿Reiniciar ahora? [s|n]"
read reb

if [ "$reb" == "s" ]; then
   reboot
else
   cd /home
   echo "¡Unha aperta! ;)"
fi
