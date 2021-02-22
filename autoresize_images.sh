#!/bin/bash

set -euxo pipefail


function convertirjpeg () {
	if [ ! -d jpegAlternatives ];
	then
		mkdir jpegAlternatives
	fi

	# Convierte a jpeg en la carpeta alternativa.
	convert $1 jpegAlternatives/$(identify -format "%t" $1).jpeg
}

# Comprueba instalación de ImageMagick
which magick > /dev/null 2>&1
if [ $? -ne 0 ];
then
	echo It requires ImageMagick package installed.
	exit 1
fi

if [[ $# > 2 ]]; then
	echo Demasiados argumentos
	exit 2
fi

case $# in
	1)
		directory=$1
		max_dimension=1920
		;;
	2)
		directory=$1
		max_dimension=$2
		;;
	*)
		directory=pwd
		max_dimension=1920
		;;
esac

cd $directory

if [ ! -d "optimizedImages" ]; 
then
	mkdir optimizedImages
fi

for i in $(ls);
do 
	mime1=$(mimetype $i | awk '{print $2}' | awk -F"/" '{print $1}')
	mime2=$(mimetype $i | awk -F"/" '{print $2}')
	if [ "$mime1" == "image" ]; 
	then
		w=$(identify -format "%w" $i);
		h=$(identify -format "%h" $i);
		if [ "$w" -gt "$max_dimension" ] || [ "$h" -gt "$max_dimension" ]; 
		then

			convert $i -resize ${max_dimension}x${max_dimension} $i

		fi
		
		case "$mime2" in
			"png")
				t=$(file $i | awk '{print $9}')
				if [ "$t" == "RGB," ];
				then
					echo $?
					# No tiene transparencia
					convertirjpeg $i
				fi
				optipng -nc -nb -o7 -full -out optimizedImages/$i $i
				;;
			"jpeg")
				jpegoptim --max=80 --all-progressive --strip-all --strip-exif --preserve --totals --dest=optimizedImages $i
				;;
		esac
	fi
done