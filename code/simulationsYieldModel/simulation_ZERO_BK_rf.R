#SCRIPT TO SIMULATE THE ZERO AND BK SCENARIO USING RANDOM FOREST MODEL

#### +++++++ CLEAN MEMORY +++++++ ####
gc()
rm(list=ls())

#### +++++++ PACKAGES +++++++ ####
library(terra)
library(tidyverse)

#### +++++++ SCRIPTS +++++++ ####
source("code/buildraster.R")
source("code/fertilizer_prof_measures.R")
source("code/yield_response.R")
yield.rf <- readRDS("results/models/yield.rf2.rds")

#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv("data/BAU_BK_inputs.csv")


#### +++++++ TABLE OF PIXEL VALUES +++++++ ####
#Getting the table of pixel valuess
rasters_input <- read.table(paste0("data/TZA_soilprice_table.txt"), header=TRUE, sep=" ")

########## +++++++ SIMULATION +++++++ ###############
#### \\ Constants of household variables to use in the prediction ####
rasters_input <- rasters_input %>% mutate(
  year           = 2.016310e+03,
  intercrop      = 5.643225e-01,
  rotat1         = 6.346484e-02,
  manure         = 1.972556e-01,
  cropres        = 9.262436e-02,
  weedings       = 1.826758e+00,
  pesticide_bin  = 1.715266e-03,
  impseed        = 1.355060e-01,
  disease        = 1.320755e-01,
  striga         = 3.430532e-02,
  fallow3yr      = 4.116638e-02,
  struct         = 2.521441e-01,
  terraced       = 3.430532e-02,
  logha         = -5.170819e-01,
  headage        = 4.777208e+01,
  femhead        = 1.360424e-01,
  hhsize         = 5.655232e+00,
  headeduc       = 7.051237e+00)

#getting the names of rainfall seasons to use for results table 
seasons <- rasters_input %>% dplyr::select(starts_with("rfe")) %>% colnames()

#### \\ Tables for scenario pixel results
ZERO <- BK <- rasters_input

########## \\ ZERO Scenario ###############
#Nitrogen application
ZERO$N_kgha <- 0

#Running yield model for all seasons of rainfall
for(season in seasons){
  ZERO$seas_rainfall <- ZERO[[season]]  #seasonal rainfall to simulate
  ZERO[paste0("yield_", season)] <- predict(yield.rf, ZERO)
  ZERO[paste0("netrev_", season)] <- ZERO[paste0("yield_", season)]*ZERO$maize_farmgate_price
  print (paste0("ZERO: Finished: ", season))
}

#Calculating mean, sd and cv using the season results
ZERO$yield_mean <- ZERO[,paste0("yield_", seasons)] %>% rowMeans(na.rm = TRUE)
ZERO$yield_sd <- apply(ZERO[,paste0("yield_", seasons)], 1, sd, na.rm=TRUE)
ZERO$yield_cv <- 100*ZERO$yield_sd/ZERO$yield_mean
ZERO$totfertcost <- 0
ZERO$netrev_mean <- ZERO[,paste0("netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
ZERO$netrev_sd <- apply(ZERO[,paste0("netrev_", seasons)], 1, sd, na.rm=TRUE)
ZERO$netrev_cv <- 100*ZERO$netrev_sd/ZERO$netrev_mean


########## \\ BK Blanket Scenario ###############
#Nitrogen application
BK$N_kgha <- 100

#Running yield model for all seasons of rainfall
for(season in seasons){
  BK$seas_rainfall <- BK[[season]]  #seasonal rainfall to simulate
  BK[paste0("yield_", season)] <-  predict(yield.rf, BK)
  BK[paste0("netrev_", season)] <- BK[paste0("yield_", season)]*BK$maize_farmgate_price
  print (paste0("BK: Finished: ", season))
}

#Calculating mean, sd and cv using the season results
BK$yield_mean <- BK[,paste0("yield_", seasons)] %>% rowMeans(na.rm = TRUE)
BK$yield_sd <- apply(BK[,paste0("yield_", seasons)], 1, sd, na.rm=TRUE)
BK$yield_cv <- 100*BK$yield_sd/BK$yield_mean
BK$totfertcost <- BK$N_kgha * BK$maize_farmgate_price
BK$netrev_mean <- BK[,paste0("netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
BK$netrev_sd <- apply(BK[,paste0("netrev_", seasons)], 1, sd, na.rm=TRUE)
BK$netrev_cv <- 100*BK$netrev_sd/BK$netrev_mean


#### \\ Calculating Yield0 for mvcr  ####
BK0 <- BK
#Getting amount of fertilizer with one unit less
BK0$N_kgha <- BK$N_kgha-1
BK0$N_kgha[BK0$N_kgha<0] <- 0  #just in case some OPyield$N_kgha were negative

#Yield0
yield0 <- predict(yield.rf, BK0)

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for BK using the mean results####
BK <- BK %>% 
  mutate(yield_gain_perc = 100*(yield_mean-ZERO$yield_mean)/ZERO$yield_mean,
         totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_gain_perc = 100*(netrev_mean-ZERO$netrev_mean)/ZERO$netrev_mean,
         ap = ap(yield1=yield_mean, N_kgha1=N_kgha),
         mp = mp(yield1=yield_mean, yield0=yield0, N_kgha1=N_kgha, N_kgha0=BK0$N_kgha),
         avcr = avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
         mvcr = mvcr(output_price=maize_farmgate_price, mp, input_price=N_price)
  )

#### \\ Writing table ####
data.table::fwrite(ZERO, paste0("results/tables/TZA_ZERO.csv"))
data.table::fwrite(BK, paste0("results/tables/TZA_BK.csv"))

#### \\ Writing rasters ####
template <- rast(paste0("data/CGIAR-SRTM/srtm_TZA.tif"))
writeRaster(buildraster(ZERO$yield_mean, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_yield_mean.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$yield_sd, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_yield_sd.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$yield_cv, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_yield_cv.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$totfertcost, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_totfertcost.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_mean, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_netrev_mean.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_sd, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_netrev_sd.tif"), overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_cv, rasters_input, template), filename=paste0("results/tif/TZA_ZERO_netrev_mean.tif"), overwrite=TRUE)

writeRaster(buildraster(BK$yield_mean, rasters_input, template), filename=paste0("results/tif/TZA_BK_yield_mean.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$yield_sd, rasters_input, template), filename=paste0("results/tif/TZA_BK_yield_sd.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$yield_cv, rasters_input, template), filename=paste0("results/tif/TZA_BK_yield_cv.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$N_kgha, rasters_input, template), filename=paste0("results/tif/TZA_BK_N_kgha.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost, rasters_input, template), filename=paste0("results/tif/TZA_BK_totfertcost.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$netrev_mean, rasters_input, template), filename=paste0("results/tif/TZA_BK_netrev_mean.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$netrev_sd, rasters_input, template), filename=paste0("results/tif/TZA_BK_netrev_sd.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$netrev_cv, rasters_input, template), filename=paste0("results/tif/TZA_BK_netrev_cv.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$yield_gain_perc, rasters_input, template), filename=paste0("results/tif/TZA_BK_yield_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost_gain_perc, rasters_input, template), filename=paste0("results/tif/TZA_BK_totfertcost_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$netrev_gain_perc, rasters_input, template), filename=paste0("results/tif/TZA_BK_netrev_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$mvcr, rasters_input, template), filename=paste0("results/tif/TZA_BK_mvcr.tif"), overwrite=TRUE)
writeRaster(buildraster(BK$avcr, rasters_input, template), filename=paste0("results/tif/TZA_BK_avcr.tif"), overwrite=TRUE)
