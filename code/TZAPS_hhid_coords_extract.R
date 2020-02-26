#### File to extract predicting variables from many rasters from the hhid coorinates
gc()
rm(list=ls())

#Packages
library(terra)
library(magrittr)

#### PROJECTION ####
#This will be the crs template for everything
projectcrs <- crs(rast("F:/Work/Ex-Ante/data/CGIAR-srtm/srtm_TZA.tif"))

#### TZAPS COORDINATES AND VARIABLES ####
TZAPS <- readr::read_csv("F:/Work/TAMASA/APS/tzaps_yield_obs.csv")

#convert to SpatVector for extraction
TZAPS_vect <- vect(TZAPS[,c("longitude", "latitude")], type="points", crs="+proj=longlat +datum=WGS84 +no_defs")  %>% 
  terra::project(crs = projectcrs)

#### ELEVATION AND SLOPE ####
srtm_TZA <- rast("F:/Work/Ex-Ante/data/CGIAR-srtm/srtm_TZA.tif")
srtm_slope_TZA <- rast("F:/Work/Ex-Ante/data/CGIAR-srtm/srtm_slope_TZA.tif")

TZAPS$srtm_TZA <- as.vector(terra::extract(srtm_TZA, TZAPS_vect, drop=TRUE))
TZAPS$srtm_slope_TZA <- as.vector(terra::extract(srtm_slope_TZA, TZAPS_vect, drop=TRUE))


#### MARKUS STACK ####
#files <- list.files(path="F:/Work/Ex-Ante/data/MarkusStacks/", pattern = ".tif$", full.names=TRUE)
#to choose which ones go in the model
files <- c("F:/Work/Ex-Ante/data/MarkusStacks/BIO1.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/BIO12.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/BIO15.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/BIO7.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/BPP15.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/BPP17.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/CEC.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/CPP15.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/CPP17.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/DCELL.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DFRES.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DGRES.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DGRID.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DHRSL.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DNLT.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DOR1.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DOR2.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DOWS.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DPARK.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DPOP1.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/DPOP2.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/EVI.tif",  
           "F:/Work/Ex-Ante/data/MarkusStacks/FIRE.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/GBD.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/GCCP.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/GFPL.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/lat.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/LCB.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/LCC.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/LCS.tif",  
           "F:/Work/Ex-Ante/data/MarkusStacks/LCT.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/LCU.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/long.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/LSTD.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/LSTN.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/MB1.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/MB2.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/MB3.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/MB7.tif", 
           #"F:/Work/Ex-Ante/data/MarkusStacks/MDEM.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/NPPA.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/NPPS.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/PARA.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/PARV.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/PH.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/S1B12.tif",
           "F:/Work/Ex-Ante/data/MarkusStacks/S1VV.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/S2B11.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/SLOPE.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/SND.tif",
           #"F:/Work/Ex-Ante/data/MarkusStacks/SOC.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/TIM.tif", 
           #"F:/Work/Ex-Ante/data/MarkusStacks/WPOP.tif", 
           "F:/Work/Ex-Ante/data/MarkusStacks/WPP17.tif")
for(file in files){
  markus_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(markus_raster, TZAPS_vect, drop=TRUE))
}

#### AFRICASOILS ####
#files <- list.files(path="F:/Work/Ex-Ante/data/files.isric.org/", pattern = ".tif$", full.names=TRUE)
#to choose which ones go in the model
files <- c("F:/Work/Ex-Ante/data/files.isric.org/af_ALUM3S_T__M_xd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_ALUM3S_T__M_xd2_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_BLD_T__M_sd1_1000m_TZA.tif", 
           "F:/Work/Ex-Ante/data/files.isric.org/af_CEC_T__M_sd1_1000m_TZA.tif",  
           "F:/Work/Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd2_1000m_TZA.tif",
           #"F:/Work/Ex-Ante/data/files.isric.org/af_CLYPPT_T__M_sd3_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_CRFVOL_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_DRAINFAO_T__M_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_EXKX_T__M_xd1_1000m_TZA.tif", 
           "F:/Work/Ex-Ante/data/files.isric.org/af_NTO_T__M_xd1_1000m_TZA.tif",  
           "F:/Work/Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd2_1000m_TZA.tif",
           #"F:/Work/Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd3_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_PHIHOX_T__M_sd1_1000m_TZA.tif",
           #"F:/Work/Ex-Ante/data/files.isric.org/af_PHIHOX_T__M_sd4_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd2_1000m_TZA.tif",
           #"F:/Work/Ex-Ante/data/files.isric.org/af_SLTPPT_T__M_sd3_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd2_1000m_TZA.tif",
           #"F:/Work/Ex-Ante/data/files.isric.org/af_SNDPPT_T__M_sd3_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_TEXMHT_T__M_sd1_1000m_TZA.tif",
           "F:/Work/Ex-Ante/data/files.isric.org/af_TEXMHT_T__M_sd2_1000m_TZA.tif")
for(file in files){
  #file <- files[4] #to test
  afsis_raster <- rast(file)
  TZAPS <- cbind(TZAPS, terra::extract(afsis_raster, TZAPS_vect, drop=TRUE))
}


#### CHIRPS SEASONAL RAINFALL ####
#Getting files
chirps_seas_2016 <- rast("F:/Work/Ex-Ante/data/rainfall/chirps-v2_201512-201605_sum_TZA.tif")
chirps_seas_2017 <- rast("F:/Work/Ex-Ante/data/rainfall/chirps-v2_201612-201705_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(chirps_seas_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(chirps_seas_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$CHIRPS_seas_rainfall <- NA
TZAPS$CHIRPS_seas_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$CHIRPS_seas_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]



#### TAMSAT SEASONAL RAINFALL ####
#Getting files
tamsat_seas_2016 <- rast("F:/Work/Ex-Ante/data/rainfall/rfe2015_12-2016_05.v3_sum_TZA.tif")
tamsat_seas_2017 <- rast("F:/Work/Ex-Ante/data/rainfall/rfe2016_12-2017_05.v3_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(tamsat_seas_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(tamsat_seas_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$TAMSAT_seas_rainfall <- NA
TZAPS$TAMSAT_seas_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$TAMSAT_seas_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]


#### TAMSAT ANNUAL RAINFALL SEP-AUG ####
#Getting files
tamsat_annual_2016 <- rast("F:/Work/Ex-Ante/data/rainfall/rfe2015_09-2016_08.v3_sum_TZA.tif")
tamsat_annual_2017 <- rast("F:/Work/Ex-Ante/data/rainfall/rfe2016_09-2017_08.v3_sum_TZA.tif")
#Extractinvg values for points
rainfall2016 <- terra::extract(tamsat_annual_2016, TZAPS_vect, drop=TRUE)
rainfall2017 <- terra::extract(tamsat_annual_2017, TZAPS_vect, drop=TRUE)
#keeping only values for that season
TZAPS$TAMSAT_annual_rainfall <- NA
TZAPS$TAMSAT_annual_rainfall[TZAPS$year == 2016] <- rainfall2016[TZAPS$year == 2016]
TZAPS$TAMSAT_annual_rainfall[TZAPS$year == 2017] <- rainfall2017[TZAPS$year == 2017]

#### ERA5 RAINFALL SEP-AUG ####
#era5 <- rast("F:/Work/ERA5/adaptor.mars.internal-1580814495.8604398-5954-1-14307c32-6cbb-4119-9c6e-69483d424689.grib")


#### POPULATION ####
pop2020 <- rast("F:/Work/Ex-Ante/data/WorldPop/AFR_PPP_2020_adj_v2_TZA.tif")
TZAPS$pop2020 <- as.vector(terra::extract(pop2020, TZAPS_vect, drop=TRUE))

#### MARKET DISTANCE ####
acc100k <- rast("F:/Work/Ex-Ante/data/mktacc/acc100k.tif")
acc50k <- rast("F:/Work/Ex-Ante/data/mktacc/acc50k.tif")
accdar <- rast("F:/Work/Ex-Ante/data/mktacc/accdar.tif")
accprd <- rast("F:/Work/Ex-Ante/data/mktacc/accprd.tif")

#Extracting values to the table
# TZAPS$acc100k <- as.vector(terra::extract(acc100k, TZAPS_vect, drop=TRUE))
# TZAPS$acc50k <- as.vector(terra::extract(acc50k, TZAPS_vect, drop=TRUE))
# TZAPS$accdar <- as.vector(terra::extract(accdar, TZAPS_vect, drop=TRUE))
# TZAPS$accprd <- as.vector(terra::extract(accprd, TZAPS_vect, drop=TRUE))


#writing the final table
str(TZAPS)
write.csv(TZAPS, "F:/Work/TAMASA/APS/TZAPS_hhid_coords_stacks.csv", row.names = FALSE)
