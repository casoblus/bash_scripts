#!/bin/bash

directory=$1

set -euxo pipefail

if [ $2 ]; 
then
	max_dimension=$2
else
	max_dimension=1920
fi

cd $directory

if [ ! -d ../optimizedImages ]; 
then
	mkdir optimizedImages
fi

for i in $(ls);
do 
	w=$(identify -format "%w");
	h=$(identify -format "%h");
	mime1=$(mimetype $i | awk -F"/" '{print $1}')
	mime2=$(mimetype $i | awk -F"/" '{print $2}')
	if [ "$mime1" == "image" ]; 
	then
		if [ "$w" -gt "$max_dimension" ] || [ "$h" -gt "$max_dimension"]; 
		then

			convert $i -resize ${max_dimension}x${max_dimension} $i

		fi
		
		case "$mime2" in
			"png")
				$(file $i | grep RGBA)
				if [ $? -ne 0 ];
				then
				# No tiene transparencia
					convertirjpeg $i
				fi
				optipng -nc -nb -o7 -full -out $i $i
				;;
			"jpeg")
				jpegoptim --max=80 --all-progressive --strip-all --preserve --totals $i
				;;
		esac
	fi
done


function convertirjpeg () {
	if [ ! -d jpegAlternatives ];
	then
		mkdir jpegAlternatives
	fi

	# Convierte a jpeg en la carpeta alternativa.
	convert $1 jpegAlternatives/$(identify -format "%t" $1).jpeg
}