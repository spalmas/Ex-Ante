#SCRIPT TO SIMULATE THE ZERO AND BK SCENARIO USING RANDOM FOREST MODEL

#### +++++++ CLEAN MEMORY +++++++ ####
rm(list=ls())
gc()

#### +++++++ PACKAGES +++++++ ####
library(randomForest)
library(terra)
library(tidyverse)

#### +++++++ SCRIPTS +++++++ ####
source("code/buildraster.R")
source("code/fertilizer_prof_measures.R")
source("code/yield_response.R")
load("data/models/yield.rf2.rda")  #loading random forest model. `load` has less problems than `readRDS` that I think changes the file somehow

#### +++++++ TABLE OF PIXEL VALUES +++++++ ####
rasters_input <- read.table("data/TZA_soilprice_table.txt", header=TRUE, sep=" ")

########## +++++++ SIMULATION +++++++ ###############
########## \\ Getting the names of rainfall seasons to use for results table  ###############
seasons <- rasters_input %>% dplyr::select(contains("05.v3_sum_TZA")) %>% colnames()

#Table for scenario pixel results
ZERO <- BK <- rasters_input

########## \\ ZERO Scenario ###############
#Table for scenario pixel results
ZERO <- rasters_input
ZERO$N_kgha <- 0  #Nitrogen application
ZERO$totfertcost <- ZERO$N_kgha * ZERO$N_price   #this is 0, I have add it for code consistency

#Running yield model for all seasons of rainfall
for(season in seasons){
  ZERO$seas_rainfall <- ZERO[[season]]  #seasonal rainfall to simulate
  ZERO[paste0("yield_", season)] <- predict(yield.rf2, ZERO)
  ZERO[paste0("netrev_", season)] <- ZERO[paste0("yield_", season)]*ZERO$maize_farmgate_price
  print (paste0("ZERO: Finished: ", season))
}

#Calculating mean, sd and cv using the season results
ZERO$yield_mean <- ZERO[,paste0("yield_", seasons)] %>% rowMeans(na.rm = TRUE)
ZERO$netrev_mean <- ZERO[,paste0("netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
ZERO$netrev_sd <- apply(ZERO[,paste0("netrev_", seasons)], 1, sd, na.rm=TRUE)
ZERO$netrev_cv <- 100*ZERO$netrev_sd/ZERO$netrev_mean


########## \\ BK Blanket Scenario ###############
#Table for scenario pixel results
BK <- rasters_input
BK$N_kgha <- 100  #Nitrogen application
BK$totfertcost <- BK$N_kgha * BK$N_price #total fertilizer cost

#Running yield model for all seasons of rainfall
for(season in seasons){
  BK$seas_rainfall <- BK[[season]]  #seasonal rainfall to simulate
  BK[paste0("yield_", season)] <-  predict(yield.rf2, BK)
  BK[paste0("netrev_", season)] <- BK[paste0("yield_", season)]*BK$maize_farmgate_price - BK$totfertcost
  print (paste0("BK: Finished: ", season))
}

#Calculating mean, sd and cv using the season results
BK$yield_mean <- BK[,paste0("yield_", seasons)] %>% rowMeans(na.rm = TRUE)
BK$netrev_mean <- BK[,paste0("netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
BK$netrev_sd <- apply(BK[,paste0("netrev_", seasons)], 1, sd, na.rm=TRUE)
BK$netrev_cv <- 100*BK$netrev_sd/BK$netrev_mean

#### \\ Calculating Yield0 for mvcr  ####
#Getting amount of fertilizer with one unit less using the mean optimized N_kgha
#we are using a different table to avoid erasing values in original table that will later be exported
BK0 <- BK %>% mutate(N_kgha = N_kgha - 1)
BK0$N_kgha[BK0$N_kgha<0] <- 0  #just in case some OPyield$N_kgha were negative

#Yield0
BK0$yield <- predict(yield.rf2, BK0)

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for BK using the mean results####
BK <- BK %>% 
  mutate(yield_mean_gainPerc = 100*(yield_mean-ZERO$yield_mean)/ZERO$yield_mean,
         totfertcost_gainPerc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_mean_gainPerc = 100*(netrev_mean-ZERO$netrev_mean)/ZERO$netrev_mean,
         ap = ap(yield1=yield_mean, N_kgha1=N_kgha),
         nue = nue(yield1=yield_mean, yield0=ZERO$yield_mean, N_kgha1=N_kgha),
         mp = mp(yield1=yield_mean, yield0=BK0$yield, N_kgha1=N_kgha, N_kgha0=BK0$N_kgha),
         avcr = avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
         mvcr = mvcr(output_price=maize_farmgate_price, mp, input_price=N_price)
  )

########## +++++++ EXPORTING RESULTS +++++++ ###############
#### \\ Keeping only useful columns to reduce size ####
ZERO <- ZERO %>% select(index, gadm36_TZA_1, spam2010V1r1_global_A_MAIZ_A_TZA,
                        N_kgha,
                        yield_mean, totfertcost, netrev_mean, netrev_sd, netrev_cv)
BK <- BK %>% select(index, gadm36_TZA_1, spam2010V1r1_global_A_MAIZ_A_TZA,
                    N_kgha,
                    yield_mean, totfertcost, netrev_mean, netrev_sd, netrev_cv,
                    yield_mean_gainPerc, totfertcost_gainPerc, netrev_mean_gainPerc, ap, nue, mp, avcr, mvcr)


#### \\ Writing rasters with no SPAM mask ####
template <- rast("data/CGIAR-SRTM/srtm_TZA.tif")
writeRaster(buildraster(ZERO$yield_mean, ZERO, template), filename="results/tif/TZA_ZERO_yield_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$totfertcost, ZERO, template), filename="results/tif/TZA_ZERO_totfertcost_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_mean, ZERO, template), filename="results/tif/TZA_ZERO_netrev_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_sd, ZERO, template), filename="results/tif/TZA_ZERO_netrev_sd_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_cv, ZERO, template), filename="results/tif/TZA_ZERO_netrev_mean_noMask.tif", overwrite=TRUE)

writeRaster(buildraster(BK$N_kgha, BK, template), filename="results/tif/TZA_BK_N_kgha_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$yield_mean, BK, template), filename="results/tif/TZA_BK_yield_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost, BK, template), filename="results/tif/TZA_BK_totfertcost_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_mean, BK, template), filename="results/tif/TZA_BK_netrev_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_sd, BK, template), filename="results/tif/TZA_BK_netrev_sd_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_cv, BK, template), filename="results/tif/TZA_BK_netrev_cv_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$yield_mean_gainPerc, BK, template), filename="results/tif/TZA_BK_yield_mean_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost_gainPerc, BK, template), filename="results/tif/TZA_BK_totfertcost_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_mean_gainPerc, BK, template), filename="results/tif/TZA_BK_netrev_mean_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$nue, BK, template), filename="results/tif/TZA_BK_nue_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$mvcr, BK, template), filename="results/tif/TZA_BK_mvcr_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(BK$avcr, BK, template), filename="results/tif/TZA_BK_avcr_noMask.tif", overwrite=TRUE)


#### \\ Writing tables and rasters for analysis and visualization ####
#This means removing non SPAM pixels from the table and rasters
data.table::fwrite(ZERO, "results/tables/TZA_ZERO_noMask.csv")
data.table::fwrite(BK, "results/tables/TZA_BK_noMask.csv")

ZERO <- ZERO[!is.na(ZERO$spam2010V1r1_global_A_MAIZ_A_TZA),]
BK <- BK[!is.na(BK$spam2010V1r1_global_A_MAIZ_A_TZA),]

data.table::fwrite(ZERO, "results/tables/TZA_ZERO.csv")
data.table::fwrite(BK, "results/tables/TZA_BK.csv")

writeRaster(buildraster(ZERO$yield_mean, ZERO, template), filename="results/tif/TZA_ZERO_yield_mean.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$totfertcost, ZERO, template), filename="results/tif/TZA_ZERO_totfertcost.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_mean, ZERO, template), filename="results/tif/TZA_ZERO_netrev_mean.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_sd, ZERO, template), filename="results/tif/TZA_ZERO_netrev_sd.tif", overwrite=TRUE)
writeRaster(buildraster(ZERO$netrev_cv, ZERO, template), filename="results/tif/TZA_ZERO_netrev_mean.tif", overwrite=TRUE)

writeRaster(buildraster(BK$N_kgha, BK, template), filename="results/tif/TZA_BK_N_kgha.tif", overwrite=TRUE)
writeRaster(buildraster(BK$yield_mean, BK, template), filename="results/tif/TZA_BK_yield_mean.tif", overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost, BK, template), filename="results/tif/TZA_BK_totfertcost.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_mean, BK, template), filename="results/tif/TZA_BK_netrev_mean.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_sd, BK, template), filename="results/tif/TZA_BK_netrev_sd.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_cv, BK, template), filename="results/tif/TZA_BK_netrev_cv.tif", overwrite=TRUE)
writeRaster(buildraster(BK$yield_mean_gainPerc, BK, template), filename="results/tif/TZA_BK_yield_mean_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(BK$totfertcost_gainPerc, BK, template), filename="results/tif/TZA_BK_totfertcost_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(BK$netrev_mean_gainPerc, BK, template), filename="results/tif/TZA_BK_netrev_mean_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(BK$nue, BK, template), filename="results/tif/TZA_BK_nue.tif", overwrite=TRUE)
writeRaster(buildraster(BK$mvcr, BK, template), filename="results/tif/TZA_BK_mvcr.tif", overwrite=TRUE)
writeRaster(buildraster(BK$avcr, BK, template), filename="results/tif/TZA_BK_avcr.tif", overwrite=TRUE)
