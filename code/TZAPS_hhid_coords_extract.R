#### File to extract predicting variables from many rasters from the hhid coorinates

rm(list=ls())

#Packages
library(terra)
library(magrittr)

#### PROJECTION ####
#This will be the crs template for everything
projectcrs <- crs(rast("F:/Work/Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd1_1000m.tif"))

#### TZAPS COORDINATES AND VARIABLES ####
TZAPS <- readr::read_csv("F:/Work/TAMASA/APS/tzaps_yield_obs.csv")
#convert to SpatVector for extraction
TZAPS_vect <- vect(TZAPS[,c("longitude", "latitude")], type="points", crs="+proj=longlat +datum=WGS84 +no_defs")  %>% 
  project(projectcrs)

#### MARKET DISTANCE ####
acc100k <- rast("F:/Work/Ex-Ante/data/mktacc/acc100k.tif")
acc50k <- rast("F:/Work/Ex-Ante/data/mktacc/acc50k.tif")
accdar <- rast("F:/Work/Ex-Ante/data/mktacc/accdar.tif")
accprd <- rast("F:/Work/Ex-Ante/data/mktacc/accprd.tif")

#Extracting values to the table
TZAPS$acc100k <- as.vector(terra::extract(acc100k, TZAPS_vect, drop=TRUE))
TZAPS$acc50k <- as.vector(terra::extract(acc50k, TZAPS_vect, drop=TRUE))
TZAPS$accdar <- as.vector(terra::extract(accdar, TZAPS_vect, drop=TRUE))
TZAPS$accprd <- as.vector(terra::extract(accprd, TZAPS_vect, drop=TRUE))

#### MARKUS STACK ####
files <- list.files(path="F:/Work/Ex-Ante/data/MarkusStacks/", pattern = ".tif$", full.names=TRUE)
for(file in files){
  markus_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(markus_raster, TZAPS_vect, drop=TRUE))
}

#### AFRICASOILS ####
files <- list.files(path="F:/Work/Ex-Ante/data/files.isric.org/", pattern = ".tif$", full.names=TRUE)
for(file in files){
  #file <- files[4] #to test
  afsis_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(afsis_raster, TZAPS_vect, drop=TRUE))
}


#### RAINFALL. SUM AND CV ####\
#Getting files
chirps2016 <- rast("F:/Work/Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum_TZA.tif")
chirps2017 <- rast("F:/Work/Ex-Ante/data/rainfall/chirps-v2_201612-201705_sum_TZA.tif")

#Exatractinvg values for points
rainfall2016 <- terra::extract(chirps2016, TZAPS_vect, FUN=sum, drop=TRUE)
rainfall2017 <- terra::extract(chirps2017, TZAPS_vect, FUN=sum, drop=TRUE)

cv <- function(x){sd(x, na.rm=TRUE)/mean(x, na.rm=TRUE)*100}

#adding Summary solumns to TZAPS table
TZAPS$total_rainfall2016 <- apply(rainfall2016, MARGIN = 1, FUN = sum)
#TZAPS$cv_rainfall2016 <- apply(rainfall2016, MARGIN = 1, FUN = cv)
TZAPS$total_rainfall2017 <- apply(rainfall2017, MARGIN = 1, FUN = sum)
#TZAPS$cv_rainfall2017 <- apply(rainfall2017, MARGIN = 1, FUN = cv)

#keeping only values for that season
TZAPS$total_rainfall <- NA
#TZAPS$cv_rainfall <- NA
TZAPS$total_rainfall[TZAPS$year == 2016] <- TZAPS$total_rainfall2016[TZAPS$year == 2016]
#TZAPS$cv_rainfall[TZAPS$year == 2016] <- TZAPS$cv_rainfall2016[TZAPS$year == 2016]
TZAPS$total_rainfall[TZAPS$year == 2017] <- TZAPS$total_rainfall2017[TZAPS$year == 2017]
#TZAPS$cv_rainfall[TZAPS$year == 2017] <- TZAPS$cv_rainfall2017[TZAPS$year == 2017]

TZAPS$total_rainfall2016 <- NULL
#TZAPS$cv_rainfall2016 <- NULL
TZAPS$total_rainfall2017 <- NULL
#TZAPS$cv_rainfall2017 <- NULL
head(TZAPS)

#### ELEVATION AND SLOPE ####
srtm <- rast("F:/Work/Ex-Ante/data/CGIAR-SRTM/srtm_TZA.tif")
srtm_slope <- rast("F:/Work/Ex-Ante/data/CGIAR-SRTM/srtm_slope_TZA.tif")

TZAPS$elevation <- terra::extract(srtm, TZAPS_vect, drop=TRUE)
TZAPS$slope <- terra::extract(srtm_slope, TZAPS_vect, drop=TRUE)

#### POPULATION ####
pop2020 <- rast("F:/Work/Ex-Ante/data/WorldPop/AFR_PPP_2020_adj_v2_TZA.tif")
TZAPS$pop2020 <- terra::extract(pop2020, TZAPS_vect, drop=TRUE)

#writing the final table
head(TZAPS)
write.csv(TZAPS, "F:/Work/TAMASA/APS/TZAPS_hhid_coords_stacks.csv", row.names = FALSE)
