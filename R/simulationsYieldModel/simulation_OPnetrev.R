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
    dplyr::select(index, gadm36_TZA_1, N_price, maize_price)

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
  
  #### \\ Reading ZERO results to calculate changes ####
  ZERO <- read.csv(paste0('results/yield_response/',COUNTRY,'_ZERO.csv'))

    #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPnetrev ####
  OPnetrev <- OPnetrev %>% 
    mutate(totfertcost = N_kgha * N_price,
           netrev = maize_price*yield - totfertcost,
           yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
           totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
           netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
           mp=mp(yield_f=yield, yield_nf=ZERO$yield, N_kgha_f=N_kgha,N_kgha_nf=0),
           ap=ap(yield_f=yield, yield_nf=ZERO$yield, output_price=maize_price, N_kgha=N_kgha, input_price=N_price),
           mcvr=mcvr(output_price=maize_price, mp, input_price=N_price),
           acvr=acvr(output_price=maize_price, ap, input_price=N_price)
    )
  
  #### +++++++ WRITING RESULTS FILES +++++++ ####
  #### \\ Writing table of pixel results
  data.table::fwrite(OPnetrev, paste0('results/yield_response/', COUNTRY, "_OPnetrev.csv"))
  
  #### \\ Writing rasters
  template <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
  writeRaster(buildraster(OPnetrev$yield, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$N_kgha, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$totfertcost, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$netrev, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$yield_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_yield_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$totfertcost_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_totfertcost_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$netrev_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_netrev_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$mcvr, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_mcvr.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPnetrev$acvr, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPnetrev_acvr.tif"), overwrite=TRUE)
  #### +++++++ TIMING +++++++ ####
  print(paste0(COUNTRY, ': ', Sys.time() - t0))
}

#### +++++++ PARALLEL END +++++++ ####
#stopCluster(cl)
head(OPnetrev)
summary(OPnetrev$netrev)
