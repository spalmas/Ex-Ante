#!/bin/bash
#cd /media/sp/SPHD/Work
cd /mnt/f/Work

######################################
#### ORGANIC CARBON AND PH LAYERS ####
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite files.isric.org/public/afsis250m/af_ORCDRC_T__M_sd1_250m.tif Ex-Ante/data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif
gdalinfo Ex-Ante/data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif

#get info of the organic carbon to match all other layers
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite files.isric.org/public/afsis250m/af_PHIHOX_T__M_sd1_250m.tif Ex-Ante/data/soil/TZA_PHIHOX_T__M_sd1_1000m.tif

######################################
#### SPAM ####
#crop the merged raster to boundaries of Tanzania and change resolution to match 
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite SPAM/spam2010v1r0/spam2010v1r0_global_phys_area.geotiff/spam2010v1r0_global_physical-area_maiz_a.tif Ex-Ante/data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif

######################################
#### ELEVATION AND SLOPE ####
gdal_merge.py -o CGIAR-SRTM/srtm_TZA_merged.tif -of GTiff CGIAR-SRTM/srtm_42_13/srtm_42_13.tif CGIAR-SRTM/srtm_42_14/srtm_42_14.tif CGIAR-SRTM/srtm_43_13/srtm_43_13.tif CGIAR-SRTM/srtm_43_14/srtm_43_14.tif CGIAR-SRTM/srtm_43_15/srtm_43_15.tif CGIAR-SRTM/srtm_44_13/srtm_44_13.tif CGIAR-SRTM/srtm_44_14/srtm_44_14.tif CGIAR-SRTM/srtm_44_15/srtm_44_15.tif

#crop the merged raster to boundaries of Tanzania and change resolution to match 
gdalwarp  -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite CGIAR-SRTM/srtm_TZA_merged.tif Ex-Ante/data/soil/srtm_TZA.tif
#Create slope
gdaldem slope Ex-Ante/data/soil/srtm_TZA.tif Ex-Ante/data/soil/srtm_slope_TZA.tif -of GTiff -co compress=lzw


######################################
#### RAINFALL ####
#2015-2016 season sum
gdal_calc.py --calc "A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+R" --format GTiff --type Float32 -A CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.1.tif -B CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.2.tif -C CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2015.12.3.tif -D CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.1.tif -E CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.2.tif -F CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.01.3.tif -G CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.1.tif -H CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.2.tif -I CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.02.3.tif -J CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.1.tif -K CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.2.tif -L CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.03.3.tif -M CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.1.tif -N CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.2.tif -O CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.04.3.tif -P CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.1.tif -Q CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.2.tif -R CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.05.3.tif --outfile CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum.tif
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201512-201605_sum.tif Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum_TZA.tif

#2016-2017 season sum
gdal_calc.py --calc "A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+R" --format GTiff --type Float32 -A CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.1.tif -B CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.2.tif -C CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2016.12.3.tif -D CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.1.tif -E CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.2.tif -F CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.01.3.tif -G CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.1.tif -H CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.2.tif -I CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.02.3.tif -J CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.1.tif -K CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.2.tif -L CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.03.3.tif -M CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.1.tif -N CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.2.tif -O CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.04.3.tif -P CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.1.tif -Q CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.2.tif -R CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2.0.2017.05.3.tif --outfile CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum.tif
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/chirps-v2_201612-201705_sum.tif Ex-Ante/data/rainfall/chirps-v2_201612-201705_sum_TZA.tif  

######################################
#### MARKET ACCESS ####
#crop the merged raster to boundaries of Tanzania
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite MarketAccessJordan/mktacc/acc.tif Ex-Ante/data/mktacc/acc.tif

######################################
#### RASTERIZE AEZ AND FERTILIZER RECOMMENDATIONS ####
#gdal_rasterize  -a ID Tanzania/tanzania_national_agro_ecological_zones/tanzania_national_agro_ecological_zones.shp Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones.tiff
#gdalwarp  -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite CGIAR-SRTM/srtm_TZA_merged.tif Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones.tiff
#dalinfo Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones.tiff
#gdal_rasterize  -a SenkoroREC -te  29.3271675 -11.7456951 40.4451370 -0.9857875 -ts 4615 4466 Tanzania/tanzania_national_agro_ecological_zones/tanzania_national_agro_ecological_zones.shp Ex-Ante/data/admin_and_AEZ/tanzania_national_agro_ecological_zones_SenkoroREC.tiff
  
######################################
#### RASTERIZE ADMIN1  ####
gdal_rasterize  -a ID -ts 4615 4466 GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_1.shp GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_1.tiff
gdalwarp -t_srs EPSG:102022 -tr 1000 1000 -cutline GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_0.shp -crop_to_cutline -of GTiff -co compress=lzw -overwrite GADM/gadm36_levels_shp/gadm36_TZA_shp/gadm36_TZA_1.tiff Ex-Ante/data/admin_and_AEZ/gadm36_TZA_1.tiff
gdalinfo Ex-Ante/data/admin_and_AEZ/gadm36_TZA_1.tiff

#copy all files to local folder
cp -r Ex-Ante/data /mnt/c/Users/S.PALMAS/source/repos/spalmas/Ex-Ante
