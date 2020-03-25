#SCRIPT FOR THE SIMULATION OF FERTILZIER OPTIMIZATION TO MAZIMIZE NETREV

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
load("data/models/yield.rf2.rda")  #loading random forest model. `load` has less problems than `readRDS` that I think changes the file somehow

#### +++++++ TIMING +++++++ ####
t0 <- Sys.time()
print(t0)

#### +++++++ TABLE OF PIXEL VALUES +++++++ ####
OPnetrev <- read.table("data/TZA_soilprice_table.txt", header=TRUE, sep=" ")

#### +++++++ SIMULATION +++++++ #### 
########## \\ OPnetrev OPTIMIZATION ###############
#pixel <- OPnetrev[1,] #to test
#Wrapper for the RF forest to be able to use it inside optimizer function
rf_wrapper <- function(N_kgha, pixel){
  pixel$N_kgha <- N_kgha
  yield <- predict(yield.rf2, pixel)
  netrev <- yield*pixel$maize_farmgate_price -  N_kgha*pixel$N_price
  return(-netrev)  #Negative because nloptr works by minimization
}

#optimizer function to use inside apply
optim_pixel <- function(pixel){
  solution <- nloptr(x=100, eval_f = rf_wrapper, lb = 0, ub = 300,
                     opts =list("algorithm"="NLOPT_LN_NELDERMEAD",  #Methods available "NLOPT_LN_BOBYQA", "NLOPT_LN_COBYLA" or "NLOPT_LN_NELDERMEAD". "NLOPT_LN_BOBYQA" is sensitive to initial value. "NLOPT_LN_NELDERMEAD" gives consistent results
                                "ftol_abs"=1.0),  #enough tolerance for this objective
                     pixel=pixel)
  
  return(c(solution$solution, solution$objective))
}
#optim_pixel(pixel) #to test

#### Start cluster  ####
cl <- makeCluster(detectCores(), type = "FORK") #FORK only available in UNIX systems

# Apply optimization for each row using the mean season of rainfall
OPnetrev$seas_rainfall <- OPnetrev$rfeDEC.MAY.v3_MEAN_TZA  #mena seasonal rainfall to simulate

#applying optimize function over all rows
solutions <- parApply(cl = cl, X = OPnetrev, MARGIN = 1, FUN = optim_pixel)  #parallel version
#solutions <- apply(X = OPnetrev, MARGIN = 1, FUN = optim_pixel)  #not parallel version

#storing results
OPnetrev$N_kgha <- floor(solutions[1,])  #floor to just store integers
OPnetrev$totfertcost <- OPnetrev$N_kgha * OPnetrev$N_price #total fertilizer cost

#### \\ End cluster  ####
stopCluster(cl)


########## +++++++ VARIABILITY +++++++ ###############
########## \\ Getting the names of rainfall seasons to use for results table  ###############
# we are not using the mean rainfall that is also in the table
seasons <- OPnetrev %>% dplyr::select(starts_with("rfe") & ends_with("sum_TZA")) %>% colnames()

# We will use the optimized value of N_kgha for the mean season to calculate the variability of results
for(season in seasons){
  #season <- seasons[3] #to test
  OPnetrev$seas_rainfall <- OPnetrev[[season]]  #seasonal rainfall to simulate
  
  #predicting yield for that season
  OPnetrev[paste0("OPnetrev_yield_", season)] <- predict(yield.rf2, OPnetrev)
  
  #calculating net revenue from that 
  OPnetrev[paste0("OPnetrev_netrev_", season)] <- OPnetrev[paste0("OPnetrev_yield_", season)]*OPnetrev$maize_farmgate_price - OPnetrev$totfertcost
  
  print (paste0("Finished Variability: ", season))
}

OPnetrev$yield_mean <- OPnetrev[,paste0("OPnetrev_yield_", seasons)] %>% rowMeans(na.rm = TRUE)
OPnetrev$netrev_mean <- OPnetrev[,paste0("OPnetrev_netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
OPnetrev$netrev_sd <- apply(OPnetrev[,paste0("OPnetrev_netrev_", seasons)], 1, sd, na.rm=TRUE)
OPnetrev$netrev_cv <- 100*OPnetrev$netrev_sd / OPnetrev$netrev_mean


#### \\ Calculating Yield0 for mvcr  ####
#Getting amount of fertilizer with one unit less using the mean optimized N_kgha
#we are using a different table to avoid erasing values in original table that will later be exported
OPnetrev0 <- OPnetrev %>% mutate(N_kgha = N_kgha - 1)
OPnetrev0$N_kgha[OPnetrev0$N_kgha<0] <- 0  #just in case any OPnetrev$N_kgha is negative

#Yield0
OPnetrev0$yield <- predict(yield.rf2, OPnetrev0)

#### \\ Reading ZERO results to calculate changes ####
ZERO <- read.csv("results/tables/TZA_ZERO_noMask.csv")

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPnetrev ####
OPnetrev <- OPnetrev %>% 
  mutate(yield_mean_gainPerc = 100*(yield_mean-ZERO$yield_mean)/ZERO$yield_mean,
         totfertcost_gainPerc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_mean_gainPerc = 100*(netrev_mean-ZERO$netrev_mean)/ZERO$netrev_mean,
         ap=ap(yield1=yield_mean, N_kgha1=N_kgha),
         nue = nue(yield1=yield_mean, yield0=ZERO$yield_mean, N_kgha1=N_kgha),
         mp=mp(yield1=yield_mean, yield0=OPnetrev0$yield, N_kgha1=N_kgha, N_kgha0=OPnetrev0$N_kgha),
         avcr=avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
         mvcr=mvcr(output_price=maize_farmgate_price, mp, input_price=N_price))

#### +++++++ REMOVING Inf VALUES +++++++ ####
#Because some optimization results return a zero N_kg_ha, avcr and mvcr are not properly estimated.
#Here we remove all these Inf values from the avcr and mvcr for better plotting
OPnetrev$ap[OPnetrev$N_kgha==0] <- NA
OPnetrev$mp[OPnetrev$N_kgha==0] <- NA
OPnetrev$avcr[OPnetrev$N_kgha==0] <- NA
OPnetrev$mvcr[OPnetrev$N_kgha==0] <- NA


########## +++++++ EXPORTING RESULTS +++++++ ###############
#### \\ Keeping only useful columns to reduce size ####
OPnetrev <- OPnetrev %>% dplyr::select(index, gadm36_TZA_1, spam2010V1r1_global_A_MAIZ_A_TZA,
                                       N_kgha,
                                       yield_mean, totfertcost, netrev_mean, netrev_sd, netrev_cv,
                                       yield_mean_gainPerc, totfertcost_gainPerc, netrev_mean_gainPerc, ap, nue, mp, avcr, mvcr)


#### \\ Writing rasters with no SPAM mask ####
template <- rast("data/CGIAR-SRTM/srtm_slope_TZA.tif")
writeRaster(buildraster(OPnetrev$N_kgha, OPnetrev, template), filename="results/tif/TZA_OPnetrev_N_kgha_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$yield_mean, OPnetrev, template), filename="results/tif/TZA_OPnetrev_yield_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$totfertcost, OPnetrev, template), filename="results/tif/TZA_OPnetrev_totfertcost_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_mean, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_mean_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_sd, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_sd_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_cv, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_cv_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$yield_mean_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_yield_mean_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$totfertcost_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_totfertcost_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_mean_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_mean_gainPerc_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$nue, OPnetrev, template), filename="results/tif/TZA_OPnetrev_nue_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$avcr, OPnetrev, template), filename="results/tif/TZA_OPnetrev_avcr_noMask.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$mvcr, OPnetrev, template), filename="results/tif/TZA_OPnetrev_mvcr_noMask.tif", overwrite=TRUE)


#### \\ Writing tables and rasters for analysis and visualization ####
#This means removing non SPAM pixels from the table and rasters
data.table::fwrite(OPnetrev, "results/tables/TZA_OPnetrev_noMask.csv")
OPnetrev <- OPnetrev[!is.na(OPnetrev$spam2010V1r1_global_A_MAIZ_A_TZA),]
data.table::fwrite(OPnetrev, "results/tables/TZA_OPnetrev.csv")

writeRaster(buildraster(OPnetrev$N_kgha, OPnetrev, template), filename="results/tif/TZA_OPnetrev_N_kgha.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$yield_mean, OPnetrev, template), filename="results/tif/TZA_OPnetrev_yield_mean.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$totfertcost, OPnetrev, template), filename="results/tif/TZA_OPnetrev_totfertcost.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_mean, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_mean.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_sd, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_sd.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_cv, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_cv.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$yield_mean_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_yield_mean_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$totfertcost_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_totfertcost_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$netrev_mean_gainPerc, OPnetrev, template), filename="results/tif/TZA_OPnetrev_netrev_mean_gainPerc.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$nue, OPnetrev, template), filename="results/tif/TZA_OPnetrev_nue.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$avcr, OPnetrev, template), filename="results/tif/TZA_OPnetrev_avcr.tif", overwrite=TRUE)
writeRaster(buildraster(OPnetrev$mvcr, OPnetrev, template), filename="results/tif/TZA_OPnetrev_mvcr.tif", overwrite=TRUE)


#### +++++++ TIMING +++++++ ####
print(paste0("Finished: ", Sys.time() - t0))

#### +++++++ SUMMARY AND SHORT PRINT +++++++ ####
summary(OPnetrev[["netrev_mean"]])
head(OPnetrev)
