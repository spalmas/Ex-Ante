#Scripts to optimize fertilizer application pixel by pixel

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source('R/simulationsYieldModel/N_to_netrev.R')
source("R/buildraster.R")
source("R/fertilizer_prof_measures.R")

#### +++++++ PACKAGES +++++++ ####
library(dplyr)
library(magrittr)
library(terra)


#### +++++++ SIMULATION +++++++ #### 
i <- 1
for (COUNTRY in c('TZA')){
  #COUNTRY <- 'TZA'  #to test
  t0 <- Sys.time()
  print(t0)
  
  #Getting the matrix of rasters data
  rasters_input_all <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'))
  
  ########## \\ OPnetrev table start ###############
  OPnetrev <- rasters_input_all %>% 
    dplyr::select(index, gadm36_TZA_1, N_price, maize_price_farmgate)
  
  ########## \\ OPnetrev OPTIMIZATION ###############
  #pixel <- rasters_input_all[23918,]
  optim_pixel <- function(pixel, ...){
    solution <- optimize(f=N_to_netrev, interval=c(0,200), pixel = pixel, maximum=TRUE, tol=0.0000001)
    if (solution$maximum<0 | solution$objective < 0){solution$maximum <- 0}
    return(floor(solution$maximum))
  }
  #optim_pixel(pixel)
  
  # Apply optimization to each row
  OPnetrev$N_kgha <- apply(X = rasters_input_all, FUN = optim_pixel, MARGIN = 1)  #not returning maximum (using other rows?)
  
  #### \\ Calculating Yield  ####
  OPnetrev$yield <- mapply(FUN = yield_response,
                           N = OPnetrev$N_kgha,   #nitrogen application kg/ha
                           lograin = rasters_input_all$lograin,
                           loggridorc = rasters_input_all$loggridorc,
                           gridacid = rasters_input_all$gridacid,
                           acc = rasters_input_all$acc,
                           slope = rasters_input_all$slope)
  
  #### \\ Calculating Yield0 for mvcr  ####
  #Getting amount of fertilizer with one unit less
  N_kgha0 <- OPyield$N_kgha-1
  N_kgha0[N_kgha0<0] <- 0  #just in case some OPyield$N_kgha were negative
  
  yield0 <- mapply(FUN = yield_response,
                   N = N_kgha0,   #nitrogen application kg/ha
                   lograin = rasters_input_all$lograin,
                   loggridorc = rasters_input_all$loggridorc,
                   gridacid = rasters_input_all$gridacid,
                   acc = rasters_input_all$acc,
                   slope = rasters_input_all$slope)
  
  #remove Inf values
  OPnetrev$yield[is.infinite(OPnetrev$yield)] <- NA
  yield0[is.infinite(yield0)] <- NA
  
  #### \\ Reading ZERO results to calculate changes ####
  ZERO <- read.csv(paste0('results/tables/',COUNTRY,'_ZERO.csv'))
  
  #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPnetrev ####
  OPnetrev <- OPnetrev %>% 
    mutate(totfertcost = N_kgha * N_price,
           netrev = maize_price_farmgate*yield - totfertcost,
           yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
           totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
           netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
           ap=ap(yield1=yield, N_kgha1=N_kgha),
           mp=mp(yield1=yield, yield0=yield0, N_kgha1=N_kgha, N_kgha0=N_kgha0),
           avcr=avcr(output_price=maize_price_farmgate, ap, input_price=N_price),
           mvcr=mvcr(output_price=maize_price_farmgate, mp, input_price=N_price))
  
  #### +++++++ REMOVING Inf VALUES +++++++ ####
  #Because some optimization results return a zero N_kg_ha, avcr and mvcr are not properly estimated.
  #Here we remove all these Inf values from the avcr and mvcr for better plotting
  OPnetrev$ap[OPnetrev$N_kgha==0] <- NA
  OPnetrev$mp[OPnetrev$N_kgha==0] <- NA
  OPnetrev$avcr[OPnetrev$N_kgha==0] <- NA
  OPnetrev$mvcr[OPnetrev$N_kgha==0] <- NA
  
  #### +++++++ WRITING RESULTS FILES +++++++ ####
  #### \\ Writing table of pixel results
  data.table::fwrite(OPnetrev, paste0('results/tables/', COUNTRY, "_OPnetrev.csv"))
  
  #### \\ Writing rasters
  template <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
  writeRaster(buildraster(OPnetrev$yield, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$N_kgha, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$totfertcost, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$netrev, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$yield_gain_perc, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_yield_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$totfertcost_gain_perc, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_totfertcost_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$netrev_gain_perc, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_netrev_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$avcr, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_avcr.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$mvcr, rasters_input_all, template), filename=paste0('results/tif/',COUNTRY, "_OPnetrev_mvcr.tif"), overwrite=TRUE)
  #### +++++++ TIMING +++++++ ####
  print(paste0(COUNTRY, ': ', Sys.time() - t0))
}

#### +++++++ PARALLEL END +++++++ ####
#stopCluster(cl)
head(OPnetrev)
summary(OPnetrev$netrev)
