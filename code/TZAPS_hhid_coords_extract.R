#### File to extract predicting variables from many rasters from the hhid coorinates
gc()
rm(list=ls())

#Packages
library(terra)
library(magrittr)

#### WORKING DIRECTORY ####
setwd("/media/sp/SPHD/Work/")

#### PROJECTION ####
#This will be the crs template for everything
projectcrs <- crs(rast("Ex-Ante/data/CGIAR-srtm/srtm_TZA.tif"))

#### TZAPS COORDINATES AND VARIABLES ####
TZAPS <- readr::read_csv("TAMASA/APS/tzaps_yield_obs.csv")

#convert to SpatVector for extraction
TZAPS_vect <- vect(TZAPS[,c("longitude", "latitude")], type="points", crs="+proj=longlat +datum=WGS84 +no_defs")  %>% 
  terra::project(crs = projectcrs)

#### ELEVATION AND SLOPE ####
srtm_TZA <- rast("Ex-Ante/data/CGIAR-srtm/srtm_TZA.tif")
srtm_slope_TZA <- rast("Ex-Ante/data/CGIAR-srtm/srtm_slope_TZA.tif")

TZAPS$srtm_TZA <- as.vector(terra::extract(srtm_TZA, TZAPS_vect, drop=TRUE))
TZAPS$srtm_slope_TZA <- as.vector(terra::extract(srtm_slope_TZA, TZAPS_vect, drop=TRUE))


#### MARKUS STACK ####
#files <- list.files(path="Ex-Ante/data/MarkusStacks/", pattern = ".tif$", full.names=TRUE)
#to choose which ones go in the model
files <- c("Ex-Ante/data/MarkusStacks/BIO1.tif",
           "Ex-Ante/data/MarkusStacks/BIO12.tif",
           "Ex-Ante/data/MarkusStacks/BIO15.tif",
           "Ex-Ante/data/MarkusStacks/BIO7.tif",
           #"Ex-Ante/data/MarkusStacks/BPP15.tif",
           #"Ex-Ante/data/MarkusStacks/BPP17.tif",
           #"Ex-Ante/data/MarkusStacks/CEC.tif", 
           "Ex-Ante/data/MarkusStacks/CPP15.tif",
           "Ex-Ante/data/MarkusStacks/CPP17.tif",
           #"Ex-Ante/data/MarkusStacks/DCELL.tif",
           "Ex-Ante/data/MarkusStacks/DFRES.tif",
           "Ex-Ante/data/MarkusStacks/DGRES.tif",
           "Ex-Ante/data/MarkusStacks/DGRID.tif",
           "Ex-Ante/data/MarkusStacks/DHRSL.tif",
           "Ex-Ante/data/MarkusStacks/DNLT.tif",
           "Ex-Ante/data/MarkusStacks/DOR1.tif",
           "Ex-Ante/data/MarkusStacks/DOR2.tif",
           "Ex-Ante/data/MarkusStacks/DOWS.tif",
           "Ex-Ante/data/MarkusStacks/DPARK.tif",
           "Ex-Ante/data/MarkusStacks/DPOP1.tif",
           "Ex-Ante/data/MarkusStacks/DPOP2.tif",
           "Ex-Ante/data/MarkusStacks/EVI.tif",  
           "Ex-Ante/data/MarkusStacks/FIRE.tif",
           #"Ex-Ante/data/MarkusStacks/GBD.tif", 
           "Ex-Ante/data/MarkusStacks/GCCP.tif",
           "Ex-Ante/data/MarkusStacks/GFPL.tif", 
           "Ex-Ante/data/MarkusStacks/lat.tif", 
           "Ex-Ante/data/MarkusStacks/LCB.tif", 
           "Ex-Ante/data/MarkusStacks/LCC.tif", 
           "Ex-Ante/data/MarkusStacks/LCS.tif",  
           "Ex-Ante/data/MarkusStacks/LCT.tif", 
           "Ex-Ante/data/MarkusStacks/LCU.tif", 
           "Ex-Ante/data/MarkusStacks/long.tif",
           "Ex-Ante/data/MarkusStacks/LSTD.tif",
           "Ex-Ante/data/MarkusStacks/LSTN.tif", 
           "Ex-Ante/data/MarkusStacks/MB1.tif", 
           "Ex-Ante/data/MarkusStacks/MB2.tif",
           "Ex-Ante/data/MarkusStacks/MB3.tif", 
           "Ex-Ante/data/MarkusStacks/MB7.tif", 
           #"Ex-Ante/data/MarkusStacks/MDEM.tif",
           "Ex-Ante/data/MarkusStacks/NPPA.tif",
           "Ex-Ante/data/MarkusStacks/NPPS.tif",
           "Ex-Ante/data/MarkusStacks/PARA.tif",
           "Ex-Ante/data/MarkusStacks/PARV.tif",
           #"Ex-Ante/data/MarkusStacks/PH.tif", 
           "Ex-Ante/data/MarkusStacks/S1B12.tif",
           "Ex-Ante/data/MarkusStacks/S1VV.tif", 
           "Ex-Ante/data/MarkusStacks/S2B11.tif",
           #"Ex-Ante/data/MarkusStacks/SLOPE.tif",
           #"Ex-Ante/data/MarkusStacks/SND.tif",
           #"Ex-Ante/data/MarkusStacks/SOC.tif", 
           "Ex-Ante/data/MarkusStacks/TIM.tif", 
           #"Ex-Ante/data/MarkusStacks/WPOP.tif", 
           "Ex-Ante/data/MarkusStacks/WPP17.tif")
for(file in files){
  markus_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(markus_raster, TZAPS_vect, drop=TRUE))
}

#### AFRICASOILS ####
#files <- list.files(path="Ex-Ante/data/files.isric.org/", pattern = ".tif$", full.names=TRUE)
#to choose which ones go in the model
files <- c("Ex-Ante/data/files.isric.org/af_ALUM3S_T__M_xd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_ALUM3S_T__M_xd2_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_BLD_T__M_sd1_5000m_TZA.tif", 
           "Ex-Ante/data/files.isric.org/af_CEC_T__M_sd1_5000m_TZA.tif",  
           "Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd2_5000m_TZA.tif",
           #"Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd3_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_CRFVOL_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_DRAINFAO_T__M_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_EXKX_T__M_xd1_5000m_TZA.tif", 
           "Ex-Ante/data/files.isric.org/af_NTO_T__M_xd1_5000m_TZA.tif",  
           "Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd2_5000m_TZA.tif",
           #"Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd3_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_PHIHOX_T__M_sd1_5000m_TZA.tif",
           #"Ex-Ante/data/files.isric.org/af_PHIHOX_T__M_sd4_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd2_5000m_TZA.tif",
           #"Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd3_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd2_5000m_TZA.tif",
           #"Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd3_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_TEXMHT_T__M_sd1_5000m_TZA.tif",
           "Ex-Ante/data/files.isric.org/af_TEXMHT_T__M_sd2_5000m_TZA.tif")
for(file in files){
  #file <- files[4] #to test
  afsis_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(afsis_raster, TZAPS_vect, drop=TRUE))
}


#### CHIRPS SEASONAL RAINFALL ####
#Getting files
chirps_seas_2016 <- rast("Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum_TZA.tif")
chirps_seas_2017 <- rast("Ex-Ante/data/rainfall/chirps-v2_201612-201705_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(chirps_seas_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(chirps_seas_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$CHIRPS_seas_rainfall <- NA
TZAPS$CHIRPS_seas_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$CHIRPS_seas_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]



#### TAMSAT SEASONAL RAINFALL ####
#Getting files
tamsat_seas_2016 <- rast("Ex-Ante/data/rainfall/rfe2015_12-2016_05.v3_sum_TZA.tif")
tamsat_seas_2017 <- rast("Ex-Ante/data/rainfall/rfe2016_12-2017_05.v3_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(tamsat_seas_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(tamsat_seas_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$TAMSAT_seas_rainfall <- NA
TZAPS$TAMSAT_seas_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$TAMSAT_seas_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]


#### TAMSAT ANNUAL RAINFALL SEP-AUG ####
#Getting files
tamsat_annual_2016 <- rast("Ex-Ante/data/rainfall/rfe2015_09-2016_08.v3_sum_TZA.tif")
tamsat_annual_2017 <- rast("Ex-Ante/data/rainfall/rfe2016_09-2017_08.v3_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(tamsat_annual_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(tamsat_annual_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$TAMSAT_annual_rainfall <- NA
TZAPS$TAMSAT_annual_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$TAMSAT_annual_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]

#### ERA5 RAINFALL SEP-AUG ####
#era5 <- rast("ERA5/adaptor.mars.internal-1580814495.8604398-5954-1-14307c32-6cbb-4119-9c6e-69483d424689.grib")


#### POPULATION ####
pop2020 <- rast("Ex-Ante/data/WorldPop/AFR_PPP_2020_adj_v2_TZA.tif")
TZAPS$pop2020 <- as.vector(terra::extract(pop2020, TZAPS_vect, drop=TRUE))

#### MARKET DISTANCE ####
acc100k <- rast("Ex-Ante/data/mktacc/acc100k.tif")
acc50k <- rast("Ex-Ante/data/mktacc/acc50k.tif")
accdar <- rast("Ex-Ante/data/mktacc/accdar.tif")
accprd <- rast("Ex-Ante/data/mktacc/accprd.tif")

#Extracting values to the table
# TZAPS$acc100k <- as.vector(terra::extract(acc100k, TZAPS_vect, drop=TRUE))
# TZAPS$acc50k <- as.vector(terra::extract(acc50k, TZAPS_vect, drop=TRUE))
# TZAPS$accdar <- as.vector(terra::extract(accdar, TZAPS_vect, drop=TRUE))
# TZAPS$accprd <- as.vector(terra::extract(accprd, TZAPS_vect, drop=TRUE))


#writing the final table
str(TZAPS)
write.csv(TZAPS, "TAMASA/APS/TZAPS_hhid_coords_stacks.csv", row.names = FALSE)
