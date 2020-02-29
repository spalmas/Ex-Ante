#SCRIPT FOR THE SIMULATION OF FERTILZIER OPTIMIZATION TO MAZIMIZE YIELD

#### +++++++ CLEAN MEMORY +++++++ ####
rm(list=ls())
gc()

#### +++++++ PACKAGES +++++++ ####
library(dplyr)
library(magrittr)
library(nloptr)  #for optimization algorithm
library(parallel)
library(randomForest)
library(terra)

#### +++++++ SCRIPTS +++++++ ####
source("code/simulationsYieldModel/N_to_netrev.R")
source("code/buildraster.R")
source("code/fertilizer_prof_measures.R")
load("results/models/yield.rf2.rda")  #loading random forest model. `load` has less problems than `readRDS` that I think changes the file somehow

#### +++++++ TIMING +++++++ ####
t0 <- Sys.time()
print(t0)

#### +++++++ TABLE OF PIXEL VALUES +++++++ ####
OPyield <- read.table("data/TZA_soilprice_table.txt", header=TRUE, sep=" ")

#### +++++++ SIMULATION +++++++ #### 
########## \\ Getting the names of rainfall seasons to use for results table  ###############
seasons <- OPyield %>% dplyr::select(starts_with("rfe")) %>% colnames()

########## \\ OPyield OPTIMIZATION ###############
#pixel <- OPyield[1021,] #to test
#Wrapper for the RF forest to be able to use it inside optimizer function
rf_wrapper <- function(N_kgha, pixel){
  pixel$N_kgha <- N_kgha
  yield <- predict(yield.rf2, pixel)
  return(-yield)  #Negative because nloptr is a minimization algorithm
}

#optimizer function to use inside apply
optim_pixel <- function(pixel){
  solution <- nloptr(x0=300, eval_f = rf_wrapper, lb = 0, ub = 300,
                     opts =list("algorithm"="NLOPT_LN_BOBYQA",  #also available "NLOPT_LN_COBYLA" or "NLOPT_LN_NELDERMEAD". Probably not big difference. BOBYQA is the fastest and gives same result in this situation.
                                "xtol_rel"=1.0),  #enough tolerance for this objective
                     pixel=pixel)
  return(c(solution$solution, solution$objective))
}
#optim_pixel(pixel) #to test

#### Start cluster  ####
cl <- makeCluster(detectCores(), type = "FORK") #FORK only available in UNIX systems

# Apply optimization for each row for all seasons of rainfall
for(season in seasons){
  #season <- seasons[1]
  OPyield$seas_rainfall <- OPyield[[season]]  #seasonal rainfall to simulate
  
  #applying optimize function
  solutions <- parApply(cl = cl, X = OPyield, MARGIN = 1, FUN = optim_pixel)  #parallel version
  #solutions <- apply(X = OPyield[1:20,], MARGIN = 1, FUN = optim_pixel)  #not parallel version
  
  #storing results
  OPyield[, paste0("N_kgha_", season)] <- floor(solutions[1,])  #floor to just store integers
  OPyield[, paste0("yield_", season)] <- floor(-solutions[2,])  #floor to just store integers. Need to invert negative from rf_wrapper
  
  #Calculating netrev
  #netrev = yield*farmgate_price-N_kgha*N_price
  OPyield[paste0("netrev_", season)] <- OPyield[paste0("yield_", season)]*OPyield$maize_farmgate_price - OPyield[paste0("N_kgha_", season)]*OPyield$N_price 
  print(paste0("Finished: ", season, ". Time: ", Sys.time() - t0))
}

#### End cluster  ####
stopCluster(cl)

#### \\ Using the mean optimized N_kgha as the best possible value  ####
OPyield$N_kgha <- OPyield[,paste0("N_kgha_", seasons)] %>% rowMeans(na.rm = TRUE)
OPyield$totfertcost <- OPyield$N_kgha * OPyield$N_price


########## +++++++ VARIABILITY +++++++ ###############
# We will use this mean of optimized values as the N_kgha suggestion to calculate the variability of results
for(season in seasons){
  #season <- seasons[3] #to test
  OPyield$seas_rainfall <- OPyield[[season]]  #seasonal rainfall to simulate
  
  #predicting yield for that season
  OPyield[paste0("OPyield_yield_", season)] <- predict(yield.rf2, OPyield)
  
  #calculating net revenue from that 
  OPyield[paste0("OPyield_netrev_", season)] <- OPyield[paste0("OPyield_yield_", season)]*OPyield$maize_farmgate_price - OPyield$totfertcost
  
  print (paste0("Finished Variability: ", season))
}

OPyield$yield_mean <- OPyield[,paste0("OPyield_yield_", seasons)] %>% rowMeans(na.rm = TRUE)
OPyield$netrev_mean <- OPyield[,paste0("OPyield_netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
OPyield$netrev_sd <- apply(OPyield[,paste0("OPyield_netrev_", seasons)], 1, sd, na.rm=TRUE)
OPyield$netrev_cv <- 100*OPyield$netrev_sd / OPyield$netrev_mean

#### \\ Calculating Yield0 for mvcr  ####
#Getting amount of fertilizer with one unit less using the mean optimized N_kgha
#we are using a different table to avoid erasing values in original table that will later be exported
OPyield0 <- OPyield %>% mutate(N_kgha = N_kgha - 1)
OPyield0$N_kgha[OPyield$N_kgha<0] <- 0  #just in case any OPyield0$N_kgha is negative

#Yield0
OPyield0$yield <- predict(yield.rf2, OPyield0)

#### \\ Reading ZERO results to calculate changes ####
ZERO <- read.csv("results/tables/TZA_ZERO.csv")

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPyield ####
OPyield <- OPyield %>% 
  mutate(yield_gain_perc = 100*(yield_mean-ZERO$yield)/ZERO$yield,
         totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_gain_perc = 100*(netrev_mean-ZERO$netrev_mean)/ZERO$netrev_mean,
         ap=ap(yield1=yield_mean, N_kgha1=N_kgha),
         mp=mp(yield1=yield_mean, yield0=OPyield0$yield, N_kgha1=N_kgha, N_kgha0=OPyield$N_kgha),
         avcr=avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
         mvcr=mvcr(output_price=maize_farmgate_price, mp, input_price=N_price))

#### +++++++ REMOVING Inf VALUES +++++++ ####
#Because some optimization results return a zero N_kg_ha, avcr and mvcr are not properly estimated.
#Here we remove all these Inf values from the avcr and mvcr for better plotting
OPyield$ap[OPyield$N_kgha==0] <- NA
OPyield$mp[OPyield$N_kgha==0] <- NA
OPyield$avcr[OPyield$N_kgha==0] <- NA
OPyield$mvcr[OPyield$N_kgha==0] <- NA


########## +++++++ EXPORTING RESULTS +++++++ ###############
#### \\ Keeping only useful columns to reduce size ####
OPyield <- OPyield %>% dplyr::select(index, gadm36_TZA_1, spam2010V1r1_global_A_MAIZ_A_TZA,
                                     N_kgha,
                                     yield_mean, totfertcost, netrev_mean, netrev_sd, netrev_cv,
                                     yield_gain_perc, totfertcost_gain_perc, netrev_gain_perc, ap, mp, avcr, mvcr)


#### \\ Writing rasters with no SPAM mask ####
template <- rast("data/CGIAR-SRTM/srtm_slope_TZA.tif")
writeRaster(buildraster(OPyield$N_kgha, OPyield, template), filename="results/tif/TZA_OPyield_N_kgha_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$yield, OPyield, template), filename="results/tif/TZA_OPyield_yield_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost, OPyield, template), filename="results/tif/TZA_OPyield_totfertcost_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_mean, OPyield, template), filename="results/tif/TZA_OPyield_netrev_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_sd, OPyield, template), filename="results/tif/TZA_OPyield_netrev_sd_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_cv, OPyield, template), filename="results/tif/TZA_OPyield_netrev_cv_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$yield_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_yield_gain_perc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_totfertcost_gain_perc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_netrev_gain_perc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$avcr, OPyield, template), filename="results/tif/TZA_OPyield_avcr_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$mvcr, OPyield, template), filename="results/tif/TZA_OPyield_mvcr_noMask.tif", overwrite=TRUE)


#### \\ Writing tables and rasters for analysis and visualization ####
#This means removing SPAM values from the table and rasters
OPyield <- OPyield[complete.cases(OPyield),]

data.table::fwrite(OPyield, "results/tables/TZA_OPyield.csv")

writeRaster(buildraster(OPyield$N_kgha, OPyield, template), filename="results/tif/TZA_OPyield_N_kgha.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$yield, OPyield, template), filename="results/tif/TZA_OPyield_yield.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost, OPyield, template), filename="results/tif/TZA_OPyield_totfertcost.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_mean, OPyield, template), filename="results/tif/TZA_OPyield_netrev_mean.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_sd, OPyield, template), filename="results/tif/TZA_OPyield_netrev_sd.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_cv, OPyield, template), filename="results/tif/TZA_OPyield_netrev_cv.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$yield_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_yield_gain_perc.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_totfertcost_gain_perc.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_gain_perc, OPyield, template), filename="results/tif/TZA_OPyield_netrev_gain_perc.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$avcr, OPyield, template), filename="results/tif/TZA_OPyield_avcr.tif", overwrite=TRUE)
writeRaster(buildraster(OPyield$mvcr, OPyield, template), filename="results/tif/TZA_OPyield_mvcr.tif", overwrite=TRUE)


#### +++++++ TIMING +++++++ ####
print(paste0("Finished: ", Sys.time() - t0))

#### +++++++ SUMMARY AND SHORT PRINT +++++++ ####
summary(OPyield[["netrev_mean"]])
head(OPyield)
