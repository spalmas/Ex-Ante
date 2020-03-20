#ESTIMATING CV OF RAINFALL SEASONS USED IN THE SIMULATIONS

#### +++++++ CLEAN MEMORY +++++++ ####
rm(list=ls())
gc()

#### +++++++ PACKAGES +++++++ ####
library(terra)

#### +++++++ LIST OF RAINFALL VALUES FROM 1981-2019 FROM CHIRPS OR CHIRPS +++++++ ####
#rainfall_rasters <- list.files("data/rainfall/", pattern = "^chirps.*\\.tif$", full.names = TRUE)
rainfall_rasters <- list.files("data/rainfall/", pattern = "^rfe.*05.*\\.tif$", full.names = TRUE)  #only those that have a 05 in the filaname (may include those that have 2005 in the name)
rainfall_rasters <- rainfall_rasters[grep(pattern = "12.*", rainfall_rasters)]  #keeping only those that have 12 in the filename 

#### +++++++ CREATING RASTER STACK +++++++ ####
rainfall <- rast(rainfall_rasters)

#### +++++++ SD AND CV +++++++ ####
rainfall_sd <- sqrt(sum((rainfall - mean(rainfall))^2)/(nlyr(rainfall) - 1))
rainfall_cv <- 100*rainfall_sd / mean(rainfall)

#### +++++++ EXPORTING RASTER +++++++ ####
writeRaster(rainfall_cv, filename = 'data/rainfall/rfeDEC-MAY.v3_CV_TZA.tif', overwrite=TRUE)

#### +++++++ PLOTTING RASTER +++++++ ####
plot(rainfall_cv, main="Rainfall CV")
