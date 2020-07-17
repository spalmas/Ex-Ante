#SCRIPT FOR THE SIMULATION OF FERTILZIER OPTIMIZATION TO MAZIMIZE YIELD

#### +++++++ CLEAN MEMORY +++++++ ####
rm(list=ls())
gc()

#### +++++++ PACKAGES +++++++ ####
library(dplyr)
library(magrittr)
library(nloptr)  #for optimization algorithm
#library(parallel)
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

########## \\The simulations will use multiple AUE values to test sensitivity###############
AUES <- c(1, 1.25, 1.5)

for (AUE in AUES){
  #AUE <- 1.5  #to test
  print(paste0("AUE: ", AUE))
  
  #### +++++++ TABLE OF PIXEL VALUES +++++++ ####
  OPyield <- read.table("data/soilprice_table.txt", header=TRUE, sep=" ")
  
  #### +++++++ SIMULATION +++++++ #### 
  ########## \\ OPyield OPTIMIZATION ###############
  #pixel <- OPyield[1,] #to test
  #Wrapper for the RF forest to be able to use it inside optimizer function
  rf_wrapper <- function(N_kgha, pixel, AUE){
    pixel$N_kgha <- N_kgha
    yield <- predict(yield.rf2, pixel) * AUE
    return(-yield)  #Negative because nloptr is a minimization algorithm
  }
  
  #optimizer function to use inside apply
  optim_pixel <- function(pixel){
    solution <- nloptr(x0=100, eval_f = rf_wrapper, lb = 0, ub = 300,
                       opts =list("algorithm"="NLOPT_LN_NELDERMEAD",  #Methods available "NLOPT_LN_BOBYQA", "NLOPT_LN_COBYLA" or "NLOPT_LN_NELDERMEAD". "NLOPT_LN_BOBYQA" is sensitive to initial value. "NLOPT_LN_NELDERMEAD" gives consistent results
                                  "ftol_rel"=0.1),  #enough tolerance for this objective
                       pixel=pixel, AUE = AUE)
    return(c(solution$solution, solution$objective))
  }
  #optim_pixel(pixel) #to test
  
  #### Start cluster  ####
  #cl <- makeCluster(detectCores(), type = "FORK") #FORK only available in UNIX systems
  
  # Apply optimization for each row using the mean season of rainfall
  OPyield$seas_rainfall <- OPyield$rfeDEC.MAY.v3_MEAN_TZA  #mean seasonal rainfall to simulate
  
  #applying optimize function
  #solutions <- parApply(cl = cl, X = OPyield, MARGIN = 1, FUN = optim_pixel)  #parallel version
  solutions <- apply(X = OPyield, MARGIN = 1, FUN = optim_pixel)  #not parallel version
  
  #storing results
  OPyield$N_kgha<- floor(solutions[1,])  #floor to just store integers
  OPyield$totfertcost <- OPyield$N_kgha * OPyield$N_price #total fertilizer cost
  
  #### End cluster  ####
  #stopCluster(cl)
  
  ########## +++++++ VARIABILITY +++++++ ###############
  ########## \\ Getting the names of rainfall seasons to use for results table  ###############
  # we are not using the mean rainfall that is also in the table
  seasons <- OPyield %>% dplyr::select(contains("05.v3_sum_TZA")) %>% colnames()
  
  # We will use the optimized value of N_kgha for the mean season to calculate the variability of results
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
  
  #### \\ Reading ZERO results from that AUE to calculate changes ####
  ZERO <- read.csv(paste0("results/tables/ZERO_AUE", AUE, "_noMask.csv"))
  
  #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPyield ####
  OPyield <- OPyield %>% 
    mutate(yield_mean_gainPerc = 100*(yield_mean-ZERO$yield_mean)/ZERO$yield_mean,
           totfertcost_gainPerc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
           netrev_mean_gainPerc = 100*(netrev_mean-ZERO$netrev_mean)/ZERO$netrev_mean,
           ap=ap(yield1=yield_mean, N_kgha1=N_kgha),
           nue = nue(yield1=yield_mean, yield0=ZERO$yield_mean, N_kgha1=N_kgha),
           mp=mp(yield1=yield_mean, yield0=OPyield0$yield, N_kgha1=N_kgha, N_kgha0=OPyield0$N_kgha),
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
                                       yield_mean_gainPerc, totfertcost_gainPerc, netrev_mean_gainPerc, ap, nue, mp, avcr, mvcr)
  
  #### \\ Writing rasters with no SPAM mask ####
  template <- rast("data/CGIAR-SRTM/srtm_slope_TZA.tif")
  writeRaster(buildraster(OPyield$N_kgha, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_N_kgha_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$yield_mean, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_yield_mean_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$totfertcost, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_totfertcost_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_mean, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_mean_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_sd, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_sd_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_cv, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_cv_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$yield_mean_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_yield_mean_gainPerc_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$totfertcost_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_totfertcost_gainPerc_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_mean_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_mean_gainPerc_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$nue, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_nue_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$avcr, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_avcr_noMask.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$mvcr, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_mvcr_noMask.tif"), overwrite=TRUE)
  
  
  #### \\ Writing tables and rasters for analysis and visualization ####
  #This means removing non SPAM pixels from the table and rasters
  data.table::fwrite(OPyield, paste0("results/tables/OPyield_AUE", AUE, "_noMask.csv"))
  OPyield <- OPyield[!is.na(OPyield$spam2010V1r1_global_A_MAIZ_A_TZA),]
  data.table::fwrite(OPyield, paste0("results/tables/OPyield_AUE", AUE, ".csv"))
  
  writeRaster(buildraster(OPyield$N_kgha, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$yield_mean, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_yield_mean.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$totfertcost, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_mean, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_mean.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_sd, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_sd.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_cv, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_cv.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$yield_mean_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_yield_mean_gainPerc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$totfertcost_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_totfertcost_gainPerc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$netrev_mean_gainPerc, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_netrev_mean_gainPerc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$nue, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_nue.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$avcr, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_avcr.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPyield$mvcr, OPyield, template), filename=paste0("results/tif/OPyield_AUE", AUE, "_mvcr.tif"), overwrite=TRUE)
  
  
  #### +++++++ TIMING +++++++ ####
  print(paste0("Finished: ", Sys.time() - t0))
  
  #### +++++++ SUMMARY AND SHORT PRINT +++++++ ####
  summary(OPyield[["netrev_mean"]])
  head(OPyield)
}