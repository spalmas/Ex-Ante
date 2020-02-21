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
yield.rf <- readRDS("results/models/yield.rf2.rds") 

#### +++++++ TIMING +++++++ ####
t0 <- Sys.time()
print(t0)

#### +++++++ TABLE OF PIXEL VALUES +++++++ ####
OPyield <- read.table(paste0("data/TZA_soilprice_table.txt"), header=TRUE, sep=" ")

#### +++++++ SIMULATION +++++++ #### 
########## \\ Constants of household variables to use in the simulation ###############
OPyield <- OPyield %>% mutate(
  year           = 2.016310e+03,
  intercrop      = 5.643225e-01,
  rotat1         = 6.346484e-02,
  manure         = 1.972556e-01,
  cropres        = 9.262436e-02,
  weedings       = 1.826758e+00,
  impseed        = 1.355060e-01,
  disease        = 1.320755e-01,
  striga         = 3.430532e-02,
  fallow3yr      = 4.116638e-02,
  struct         = 2.521441e-01,
  terraced       = 3.430532e-02,
  logha          = -5.170819e-01,
  headage        = 4.777208e+01,
  femhead        = 1.360424e-01,
  hhsize         = 5.655232e+00,
  headeduc       = 7.051237e+00,
)

########## \\ Getting the names of rainfall seasons to use for results table  ###############
seasons <- OPyield %>% dplyr::select(starts_with("rfe")) %>% colnames()

########## \\ OPyield OPTIMIZATION ###############
#pixel <- OPnetrev[1021,] #to test
#Wrapper for the RF forest to be able to use it inside `optimize` function
rf_wrapper <- function(N_kgha, pixel){
  #N_kgha <- 4356  #to test
  pixel$N_kgha <- N_kgha
  yield <- predict(yield.rf, pixel)
  return(-yield)  #Negative because nloptr works by minimization
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
cl <- makeCluster(detectCores(), type = "FORK") #How many cores to use in the parallel processing

# Apply optimization for each row for all seasons of rainfall
for(season in seasons){
  #season <- seasons[1]
  OPyield$seas_rainfall <- OPyield[[season]]  #seasonal rainfall to simulate
  #optim_pixel(OPyield[9864,])  #to test
  
  #appplyting optimize function
  solutions <- parApply(cl = cl, X = OPyield, MARGIN = 1, FUN = optim_pixel)  #parallel version
  #solutions <- apply(X = OPyield[1:20,], MARGIN = 1, FUN = optim_pixel)  #not parallel version
   
  #storing results
  OPyield[, paste0("N_kgha_", season)] <- floor(solutions[1,])  #floor to just store integers
  OPyield[, paste0("yield_", season)] <- floor(-solutions[1,])  #floor to just store integers. Need to invert negative from rf_wrapper
  
  #Calculating netrev
  #netrev = yield*farmgate_price-N_kgha*N_price
  OPyield[paste0("netrev_", season)] <- OPyield[paste0("yield_", season)]*OPyield$maize_farmgate_price - OPyield[paste0("N_kgha_", season)]*OPyield$N_price 
  print(paste0("Finished: ", season))
}

#### End cluster  ####
stopCluster(cl)

#### \\ Calculating Yield0 for mvcr  ####
#Getting amount of fertilizer with one unit less using the mean optimized N_kgha
OPyield$N_kgha <- OPyield[,paste0("N_kgha_", seasons)] %>% rowMeans(na.rm = TRUE)
N_kgha0 <- OPyield$N_kgha - 1
N_kgha0[N_kgha0<0] <- 0  #just in case some OPyield$N_kgha were negative
OPyield["N_kgha",] <- N_kgha0  #swapping N_kgha to N_kgha0 result to use in RF model

#Yield0
yield0 <-  predict(yield.rf, OPyield)

#remove Inf values
OPyield$yield[is.infinite(OPyield$yield)] <- NA
yield0[is.infinite(yield0)] <- NA

#### \\ Reading ZERO results to calculate changes ####
ZERO <- read.csv(paste0("results/tables/TZA_ZERO.csv"))

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPyield ####
OPyield <- OPyield %>% 
  mutate(totfertcost = N_kgha * N_price,
         netrev = maize_farmgate_price*yield - totfertcost,
         yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
         totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
         ap=ap(yield1=yield, N_kgha1=N_kgha),
         mp=mp(yield1=yield, yield0=yield0, N_kgha1=N_kgha, N_kgha0=N_kgha0),
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
OPyield <- OPyield %>% select(index, gadm36_TZA_1,
                              N_kgha,
                              yield_mean,yield_sd, yield_cv, totfertcost, netrev_mean, netrev_sd, netrev_cv,
                              yield_gain_perc, totfertcost_gain_perc, netrev_gain_perc, ap, mp, avcr, mvcr)

#### \\ Writing table of pixel results
data.table::fwrite(OPyield, paste0("results/tables/TZA_OPyield.csv"))

#### \\ Writing rasters
template <- rast(paste0("data/CGIAR-SRTM/srtm_slope_TZA.tif"))
writeRaster(buildraster(OPyield$yield, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_yield.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$N_kgha, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_N_kgha.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_totfertcost.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_netrev.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$yield_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_yield_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_totfertcost_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_netrev_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$avcr, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_avcr.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$mvcr, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_mvcr.tif"), overwrite=TRUE)

#### +++++++ TIMING +++++++ ####
print(paste0("Finished : ", Sys.time() - t0))

#### +++++++ SUMMARY AND SHORT PRINT +++++++ ####
summary(OPyield[["netrev"]])
head(OPyield)
