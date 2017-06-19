#! /bin/bash

# Convert Landsat 8 GeoTIFF images into RGB pan-sharpened JPEGs.
#
# Requirements:
#              * gdal http://www.mapbox.com/tilemill/docs/guides/gdal/
#              * convert (image-magick)
#
#               sudo apt-get install dans-gdal-scripts
#               sudo apt install gdal-bin
#
#
#
# Reference info:
#                 http://www.mapbox.com/blog/putting-landsat-8-bands-to-work/
#                 http://www.mapbox.com/tilemill/docs/guides/gdal/
#                 http://www.mapbox.com/blog/processing-landsat-8/
#                 http://earthexplorer.usgs.gov/

# Converting from 16bit to 8bit
# gdal_translate -ot Byte -scale 0 65535 0 255 sixteen.tif eight.tif

# Converting from 8bit to 16bit
# gdal_translate -ot Uint16 -scale 0 255 0 65535 eight.tif sixteen.tif

# Params
GDAL_COOR=4326;


if [[ -z "$1" ]]; then
	echo "Landsat image processing"
	echo ""
	echo "Converts to 8-bit, merges RGB, pan-sharpens, colour corrects and converts to JPG"
	echo "Example: process_landsat LC82010242013198LGN00"
	echo ""
	exit 0
fi

if [ ! -f ./"$1"_B2.TIF ]; then
	echo "File not found!"
	exit 0
fi

if [ ! -d "$DIRECTORY" ]; then
	mkdir tmp
fi

# Convert 16-bit images into 8-bit and tweak levels
for BAND in {8,4,3,2}; do
	gdalwarp -t_srs EPSG:"$GDAL_COOR" "$1"_B"$BAND".TIF ./tmp/b"$BAND"-projected.tif;

	# Only Output-Stretch ist 8Bit
	gdal_contrast_stretch -ndv 0 -linear-stretch 70 30 ./tmp/b"$BAND"-projected.tif ./tmp/b"$BAND"-8bit.tif;
done

# Merge RGB bands into one image
gdal_merge_simple -in ./tmp/b4-8bit.tif -in ./tmp/b3-8bit.tif -in ./tmp/b2-8bit.tif -out ./tmp/rgb.tif

# Pan-sharpen RGB image
gdal_landsat_pansharp -rgb ./tmp/rgb.tif -lum ./tmp/rgb.tif 0.25 0.23 0.52 -pan ./tmp/b3-8bit.tif -ndv 0 -o ./tmp/pan.tif

# Colour correct and convert to TIF without compression
convert -verbose -channel B -gamma 0.8 ./tmp/pan.tif final-pan-rgb-corrected-8Bit.tif

# Create Wordfile with GeoCoordinates
listgeo -tfw tmp/rgb.tif

mv tmp/rgb.tfw final-pan-rgb-corrected-8Bit.tfw

# Converting from 8bit to 8Bit
#gdal_translate -ot Byte -scale 0 65535 0 255 final-pan-rgb-corrected-8Bit.tif final-pan-rgb-corrected-8Bit.tif


# Translate to EPSG
gdal_edit.py -a_srs EPSG:"$GDAL_COOR" final-pan-rgb-corrected-8Bit.tif

# Rename the Final-Pic with EPSG
mv final-pan-rgb-corrected-8Bit.tif final-pan-rgb-corrected-"$GDAL_COOR".tif

# delete tfw-file
rm final-pan-rgb-corrected-8Bit.tfw

echo "Finished."
