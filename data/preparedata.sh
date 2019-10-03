#!/bin/bash
cd /media/sp/SPHD/Work

gdalwarp -t_srs EPSG:4326 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite files.isric.org/public/afsis250m/af_ORCDRC_T__M_sd1_250m.tif Ex-Ante/data/soil/TZA_ORCDRC_T__M_sd1_250m.tif
gdalwarp -t_srs EPSG:4326 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite files.isric.org/public/afsis250m/af_PHIHOX_T__M_sd1_250m.tif Ex-Ante/data/soil/TZA_PHIHOX_T__M_sd1_250m.tif

#get info of the organic carbon to match all other layers
gdalinfo Ex-Ante/data/soil/TZA_ORCDRC_T__M_sd1_250m.tif
# Driver: GTiff/GeoTIFF
# Files: Ex-Ante/data/soil/TZA_ORCDRC_T__M_sd1_250m.tif
# Size is 4615, 4466
# Coordinate System is:
# GEOGCS["WGS 84",
#     DATUM["WGS_1984",
#         SPHEROID["WGS 84",6378137,298.257223563,
#             AUTHORITY["EPSG","7030"]],
#         AUTHORITY["EPSG","6326"]],
#     PRIMEM["Greenwich",0],
#     UNIT["degree",0.0174532925199433],
#     AUTHORITY["EPSG","4326"]]
# Origin = (29.327167509999999,-0.985787508898987)
# Pixel Size = (0.002409094151679,-0.002409294131182)
# Metadata:
#   AREA_OR_POINT=Area
# Image Structure Metadata:
#   COMPRESSION=LZW
#   INTERLEAVE=BAND
# Corner Coordinates:
# Upper Left  (  29.3271675,  -0.9857875) ( 29d19'37.80"E,  0d59' 8.84"S)
# Lower Left  (  29.3271675, -11.7456951) ( 29d19'37.80"E, 11d44'44.50"S)
# Upper Right (  40.4451370,  -0.9857875) ( 40d26'42.49"E,  0d59' 8.84"S)
# Lower Right (  40.4451370, -11.7456951) ( 40d26'42.49"E, 11d44'44.50"S)
# Center      (  34.8861523,  -6.3657413) ( 34d53'10.15"E,  6d21'56.67"S)
# Band 1 Block=4615x1 Type=Int16, ColorInterp=Gray
#   NoData Value=-9999
#Create an elevation layer for Tanzania using cgiar srtm

######################################
#### ADMIN ####
#change resolution to match organic carbon layer


######################################
#### SPAM ####
#change resolution to match organic carbon layer
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  SPAM/SPAM2010/spam2010v1r0_global_phys_area/spam2010v1r0_global_physical-area_maiz_a.tif \
  SPAM/SPAM2010/spam2010v1r0_global_phys_area/spam2010v1r0_global_physical-area_maiz_a_TZA.tif 

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 \
 -ts 4615 4466 \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  SPAM/SPAM2010/spam2010v1r0_global_phys_area/spam2010v1r0_global_physical-area_maiz_a_TZA.tif \
  Ex-Ante/data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif

gdalinfo Ex-Ante/data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif

######################################
#### ELEVATION AND SLOPE ####
gdal_merge.py -o CGIAR-SRTM/srtm_TZA_merged.tif \
  -of GTiff \
  CGIAR-SRTM/srtm_42_13/srtm_42_13.tif \
  CGIAR-SRTM/srtm_42_14/srtm_42_14.tif \
  CGIAR-SRTM/srtm_43_13/srtm_43_13.tif \
  CGIAR-SRTM/srtm_43_14/srtm_43_14.tif \
  CGIAR-SRTM/srtm_43_15/srtm_43_15.tif \
  CGIAR-SRTM/srtm_44_13/srtm_44_13.tif \
  CGIAR-SRTM/srtm_44_14/srtm_44_14.tif \
  CGIAR-SRTM/srtm_44_15/srtm_44_15.tif

#crop the merged raster to boundaries of Tanzania
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CGIAR-SRTM/srtm_TZA_merged.tif \
  CGIAR-SRTM/srtm_TZA_clipped.tif

gdalinfo CGIAR-SRTM/srtm_TZA_clipped.tif 

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 \
 -ts 4615 4466 \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CGIAR-SRTM/srtm_TZA_clipped.tif \
  Ex-Ante/data/soil/srtm_TZA.tif

gdalinfo Ex-Ante/data/soil/srtm_TZA.tif

#Create slope
#-s 111120 is the scale to convert 1 deg to meters. It is approximately correct since it is close to the equator. Later to change original elevation model to a meter projection
gdaldem slope Ex-Ante/data/soil/srtm_TZA.tif \
  Ex-Ante/data/soil/srtm_slope_TZA.tif \
  -s 111120.0 \
  -of GTiff \
  -co compress=lzw
gdalinfo Ex-Ante/data/soil/srtm_slope_TZA.tif


#### RAINFALL ####
gdal_calc.py --calc "A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+R" \
  --format GTiff --type Float32 \
  -A CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.1.tif \
  -B CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.2.tif \
  -C CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.3.tif \
  -D CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.1.tif \
  -E CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.2.tif \
  -F CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.3.tif \
  -G CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.1.tif \
  -H CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.2.tif \
  -I CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.3.tif \
  -J CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.1.tif \
  -K CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.2.tif \
  -L CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.3.tif \
  -M CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.1.tif \
  -N CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.2.tif \
  -O CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.3.tif \
  -P CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.1.tif \
  -Q CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.2.tif \
  -R CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.3.tif \
  --outfile CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum.tif

#crop the merged raster to boundaries of Tanzania
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum.tif \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum-TZA.tif

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 \
 -ts 4615 4466 \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum-TZA.tif \
  Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum.tif 
  
gdalinfo Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum.tif 

#2016-2017 season sum
gdal_calc.py --calc "A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+R" \
  --format GTiff --type Float32 \
  -A CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.1.tif \
  -B CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.2.tif \
  -C CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.3.tif \
  -D CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.1.tif \
  -E CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.2.tif \
  -F CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.3.tif \
  -G CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.1.tif \
  -H CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.2.tif \
  -I CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.3.tif \
  -J CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.1.tif \
  -K CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.2.tif \
  -L CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.3.tif \
  -M CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.1.tif \
  -N CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.2.tif \
  -O CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.3.tif \
  -P CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.1.tif \
  -Q CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.2.tif \
  -R CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.3.tif \
  --outfile CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum.tif

#crop the merged raster to boundaries of Tanzania
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum.tif \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum-TZA.tif
  

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 \
 -ts 4615 4466 \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum-TZA.tif \
  Ex-Ante/data/rainfall/chirps-v2_201612-201705_sum-TZA.tif  
  

#### MARKET ACCESS ####
#crop the merged raster to boundaries of Tanzania
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  MarketAccessJordan/mktacc/acc.tif \
  MarketAccessJordan/mktacc/acc_clipped.tif \

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466  -of GTiff  -co compress=lzw  -overwrite  MarketAccessJordan/mktacc/acc_clipped.tif Ex-Ante/data/mktacc/acc.tif
gdalinfo Ex-Ante/data/mktacc/acc.tif

#### MARKET ACCESS ####
#crop the merged raster to boundaries of Tanzania
gdalwarp -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp \
  -crop_to_cutline \
  -of GTiff \
  -co compress=lzw \
  -overwrite \
  MarketAccessJordan/mktacc/acc.tif \
  MarketAccessJordan/mktacc/acc_clipped.tif \

#change resolution to match organic carbon layer
gdalwarp  -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466  -of GTiff  -co compress=lzw  -overwrite  MarketAccessJordan/mktacc/acc_clipped.tif Ex-Ante/data/mktacc/acc.tif
gdalinfo Ex-Ante/data/mktacc/acc.tif

#### RASTERIZE AEZ AND FERTILIZER RECOMMENDATIONS ####
gdal_rasterize  -a ID -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466 Tanzania/tanzania_national_agro_ecological_zones/tanzania_national_agro_ecological_zones.shp Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones.tiff
gdal_rasterize  -a SenkoroREC -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466 Tanzania/tanzania_national_agro_ecological_zones/tanzania_national_agro_ecological_zones.shp Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones_SenkoroREC.tiff
  
#### RASTERIZE ADMIN1  ####
gdal_rasterize  -a ID -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466 GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_1.shp Ex-Ante/data/admin_and_AEZ/gadm36_TZA_1.tiff

#copy all files to local folder
cp -r Ex-Ante/data /mnt/c/Users/S.PALMAS/source/repos/spalmas/Ex-Ante
