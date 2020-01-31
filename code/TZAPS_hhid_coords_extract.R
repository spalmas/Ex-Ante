#### File to extract predicting variables from many rasters from the hhid coorinates

rm(list=ls())

#Packages
library(terra)

#reading TZAPS cooridnates/
TZAPS <- readr::read_csv("F:/Work/TAMASA/APS/TZAPS_hhid_coords.csv")
#convert to SpatVectotr
TZAPS_vect <- vect(TZAPS[,c("longitude", "latitude")], type="points", crs="+proj=longlat +datum=WGS84 +no_defs")  
plot(TZAPS_vect)
#projecting (if needed)
#NOT_vect <- NOT_vect %>% project(crs(rast_soilpH))

### #Creating stack of variables to extract
#### MARKET DISTANCE ####
acc100k <- rast("F:/Work/MarketAccessJordan/mktacc/acc100k.tif")
acc50k <- rast("F:/Work/MarketAccessJordan/mktacc/acc50k.tif")
accdar <- rast("F:/Work/MarketAccessJordan/mktacc/accdar.tif")
accprd <- rast("F:/Work/MarketAccessJordan/mktacc/accprd.tif")

#we project the vector layer of markets to the projection in the market layers. We will use this projected vector only here.
TZAPS_vect_mkt <- project(TZAPS_vect, crs=crs(acc100k))
TZAPS$acc100k <- as.vector(terra::extract(acc100k, TZAPS_vect_mkt, drop=TRUE))
TZAPS$acc50k <- as.vector(terra::extract(acc50k, TZAPS_vect_mkt, drop=TRUE))
TZAPS$accdar <- as.vector(terra::extract(accdar, TZAPS_vect_mkt, drop=TRUE))
TZAPS$accprd <- as.vector(terra::extract(accprd, TZAPS_vect_mkt, drop=TRUE))
#access100k <- rast("F:/Work/MarketAccessJordan/mktacc/acc100k.tif")
#TZAPS$acc100k <-  extract(access, TZAPS_vect_mkt, drop=TRUE)



#### MARKUS STACK ####\
BIO1 <- rast("F:/Work/Markus Stacks/TZ_250m_2019/BIO1.tif")
TZAPS_vect_markus <- project(TZAPS_vect, crs = crs(BIO1))   #need to reproject to crs of afsiss
files <- list.files(path="F:/Work/Markus Stacks/TZ_250m_2019/", pattern = ".tif$", full.names=TRUE)
for(file in files){
  #file <- files[4] #to test
  markus_raster <- rast(file)
  #plot(africa_raster) #to check
  #plot(TZAPS_vect_afsis, add=TRUE)
  TZAPS <- cbind(TZAPS, terra::extract(markus_raster, TZAPS_vect_markus, drop=TRUE))
}


#### AFRICASOILS ####\
soilC <- rast("F:/Work/files.isric.org/public/afsis250m/af_ORCDRC_T__M_sd1_250m.tif")
TZAPS_vect_afsis <- project(TZAPS_vect, crs = crs(soilC))   #need to re
files <- list.files(path="F:/Work/files.isric.org/public/afsis250m/", pattern = ".tif$", full.names=TRUE)
for(file in files){
  #file <- files[4] #to test
  africa_raster <- rast(file)
  #plot(africa_raster) #to check
  #plot(TZAPS_vect_afsis, add=TRUE)
  TZAPS <- cbind(TZAPS, terra::extract(africa_raster, TZAPS_vect_afsis, drop=TRUE))
}


#### RAINFALL. SUM AND CV ####\
#Getting files
files <- list.files(path="F:/Work/CHIRPS/ftp.chg.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_dekad/tifs/", pattern = ".tif$", full.names = TRUE)
files2016 <- files[1:18]
files2017 <- files[19:36]

#Creating stack for for two seasons
chirps2016 <- rast(files2016)
chirps2017 <- rast(files2017)

#Exatractinvg values for points
rainfall2016 <- terra::extract(chirps2016, TZAPS_vect, FUN=sum, drop=TRUE)
rainfall2017 <- terra::extract(chirps2017, TZAPS_vect, FUN=sum, drop=TRUE)

cv <- function(x){sd(x, na.rm=TRUE)/mean(x, na.rm=TRUE)*100}

#adding Summary solumns to TZAPS table
TZAPS$total_rainfall2016 <- apply(rainfall2016, MARGIN = 1, FUN = sum)
TZAPS$cv_rainfall2016 <- apply(rainfall2016, MARGIN = 1, FUN = cv)
TZAPS$total_rainfall2017 <- apply(rainfall2017, MARGIN = 1, FUN = sum)
TZAPS$cv_rainfall2017 <- apply(rainfall2017, MARGIN = 1, FUN = cv)

#keeping only values for that season
TZAPS$total_rainfall <- NA
TZAPS$cv_rainfall <- NA
TZAPS$total_rainfall[TZAPS$year == 2016] <- TZAPS$total_rainfall2016[TZAPS$year == 2016]
TZAPS$cv_rainfall[TZAPS$year == 2016] <- TZAPS$cv_rainfall2016[TZAPS$year == 2016]
TZAPS$total_rainfall[TZAPS$year == 2017] <- TZAPS$total_rainfall2017[TZAPS$year == 2017]
TZAPS$cv_rainfall[TZAPS$year == 2017] <- TZAPS$cv_rainfall2017[TZAPS$year == 2017]

TZAPS$total_rainfall2016 <- NULL
TZAPS$cv_rainfall2016 <- NULL
TZAPS$total_rainfall2017 <- NULL
TZAPS$cv_rainfall2017 <- NULL
head(TZAPS)

#### ELEVATION ####
#Only using rasters that cross the points.
srtm_43_14 <- rast("F:/Work/CGIAR-SRTM/srtm_43_14/srtm_43_14.tif")
srtm_44_13 <- rast("F:/Work/CGIAR-SRTM/srtm_44_13/srtm_44_13.tif")
srtm_44_14 <- rast("F:/Work/CGIAR-SRTM/srtm_44_14/srtm_44_14.tif")
srtm_44_15 <- rast("F:/Work/CGIAR-SRTM/srtm_44_15/srtm_44_15.tif")
srtm <- merge(srtm_43_14, srtm_44_13, srtm_44_14, srtm_44_15)

#plot(TZAPS_vect, add=TRUE)
TZAPS$elevation <- terra::extract(srtm, TZAPS_vect, drop=TRUE)

#### SLOPE ####
slope <- rast("D:/Google Drive/Ex-Ante/tanzania-slope2-0000000000-0000032768.tif")
TZAPS$slope <- terra::extract(slope, TZAPS_vect, drop=TRUE)

#### POPULATION ####
pop <- rast("F:/Work/WorldPop/Countries/Tanzania/TZA_popmap15_v2b.tif")
TZAPS$popkm2 <- terra::extract(pop, TZAPS_vect, drop=TRUE)

#writing the final table
head(TZAPS)
write.csv(TZAPS, "F:/Work/TAMASA/APS/TZAPS_hhid_coords_stacks.csv")
