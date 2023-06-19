#!/bin/bash

###
# Adds a watermark and moves watermarked files from $source to $destination
# dependencies : exiftran, imagemagick, sed,  
# imagemagick works best with the appimage here https://imagemagick.org/archive/binaries/magick
# add magick to path
# $source, $destination, $watermark are in the same directory as this script


# parameters
suffix="_wm"
source="0_SOURCE-FOLDER" #name of source dir
destination="1_DESTINATION-FOLDER" #name of destination dir
watermark="sample-watermark.png"

# find all JPG files to be watermarked and store them
# add `-o -name "*ext"` to find other files
find ./$source -type f \
	-name "*.JPG" \
	-o -name "*.JPEG" \
	-o -name "*.PNG" \
	| xargs -I '{}' echo "{}" \
	> pre-moulinette.tmp

# find all files already watermarked using suffix
find ./$destination -type f \
        -name "*$suffix*" \
        | xargs -I '{}' echo "{}" \
	> post-moulinette.tmp

# read the file list
while read file; do
	# various path clean-up
	basename=`echo $file | sed 's/.*\///'`
	basename_no_ext=`echo $basename | sed 's/\..*//'`
	destination_dir=`echo $file | sed "s/${basename}//" | sed "s/${source}/${destination}/"`
	
	# check if file exists
	if grep -Fq "$basename_no_ext" post-moulinette.tmp
       	then
		echo "file $basename_no_ext already exists in destination file structure"
	else
		echo "file $basename_no_ext does not exist in destination file structure => converting"

		# rotate all pictures based on metadata (so that vertical pictures work properly with imagemagick)
		exiftran -ai $file
	
		# create destination_dir
		mkdir -p $destination_dir

		# adds the watermark from $watermark
		# size of logo is defined in [fx:int(w*0.15)] as a percentage of total width.
		magick $file -sampling-factor 4:2:0 \
			-interlace JPEG \
			-quality 85 \
			-colorspace sRGB \
			-strip \
			-set option:logowidth "%[fx:int(w*0.15)]" \( $watermark -resize "%[logowidth]x" \) \
			-gravity SouthEast \
			-geometry +10+10 \
			-composite "${destination_dir}${basename_no_ext}${suffix}.jpg"
	fi
done < pre-moulinette.tmp

## clean up temp files
rm *.tmp
