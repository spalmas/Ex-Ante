#Scripts to simulate  TZA using the yield response model

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source("R/buildraster.R")
source('R/fertilizer_prof_measures.R')

#### +++++++ PACKAGES +++++++ ####
library(terra)
library(tidyverse)

#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('Data/BAU_BK_inputs.csv')

#### +++++++ SIMULATION +++++++ ####
for (COUNTRY in c('TZA')){
  #COUNTRY <- 'TZA'  #to test
  
  #Getting the matrix of soil data
  rasters_input <- read.csv(file=paste0("data/", COUNTRY, "_soilprice_table.csv"))
  
  #### \\ Tables for scenario pixel results
  ZERO <- BK <- rasters_input %>% dplyr::select(index, gadm36_TZA_1, N_price, maize_farmgate_price)
  
  ########## +++++++ SCENARIOS +++++++ ###############
  ########## \\ ZERO Scenario ###############
  #Running yield model
  ZERO$yield <- mapply(FUN = yield_response,
                       N = 0,   #nitrogen application kg/ha
                       lograin = rasters_input$lograin,
                       loggridorc = rasters_input$loggridorc,
                       gridacid = rasters_input$gridacid,
                       acc = rasters_input$acc,
                       slope = rasters_input$slope)
  
  ########## \\ Blanket Scenario ###############
  BK$N_kgha <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, "N"]
  
  #Running yield model
  BK$yield <- mapply(FUN = yield_response,
                     N = BK$N_kgha,   #nitrogen application kg/ha
                     lograin = rasters_input$lograin,
                     loggridorc = rasters_input$loggridorc,
                     gridacid = rasters_input$gridacid,
                     acc = rasters_input$acc,
                     slope = rasters_input$slope)
  
  #### \\ Calculating Yield0 for mvcr  ####
  #Getting amount of fertilizer with one unit less
  N_kgha0 <- BK$N_kgha-1
  N_kgha0[N_kgha0<0] <- 0  #just in case some OPyield$N_kgha were negative
  
  #Yield0
  yield0 <- mapply(FUN = yield_response,
                   N = N_kgha0,   #nitrogen application kg/ha
                   lograin = rasters_input$lograin,
                   loggridorc = rasters_input$loggridorc,
                   gridacid = rasters_input$gridacid,
                   acc = rasters_input$acc,
                   slope = rasters_input$slope)
  
  #### \\ Remove -Inf values  ####
  ZERO$yield[is.infinite(ZERO$yield)] <- NA
  BK$yield[is.infinite(BK$yield)] <- NA
  yield0[is.infinite(yield0)] <- NA
  
  #### \\ Calculating totfertcost netrevenue for ZERO ####
  ZERO <- ZERO %>% 
    mutate(totfertcost = 0,
           netrev = yield * maize_farmgate_price
    )
  
  #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for BK ####
  BK <- BK %>% 
    mutate(totfertcost=N_price*N_kgha,
           netrev = yield*maize_farmgate_price-totfertcost,
           yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
           totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
           netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
           ap=ap(yield1=yield, N_kgha1=N_kgha),
           mp=mp(yield1=yield, yield0=yield0, N_kgha1=N_kgha, N_kgha0=N_kgha0),
           avcr=avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
           mvcr=mvcr(output_price=maize_farmgate_price, mp, input_price=N_price)
    )
  
  #### \\ Writing table ####
  data.table::fwrite(ZERO, paste0('results/tables/',COUNTRY, "_ZERO.csv"))
  data.table::fwrite(BK, paste0('results/tables/',COUNTRY, "_BK.csv"))
  
  #### \\ Writing rasters ####
  template <- rast(paste0('data/soil/', COUNTRY,'_ORCDRC_T__M_sd1_1000m.tif'))
  writeRaster(buildraster(ZERO$yield, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_ZERO_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$totfertcost, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_ZERO_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$netrev, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_ZERO_netrev.tif"), overwrite=TRUE)
  
  writeRaster(buildraster(BK$yield, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$N_kgha, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$yield_gain_perc, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_yield_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost_gain_perc, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_totfertcost_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev_gain_perc, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_netrev_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$mvcr, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_mvcr.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$avcr, rasters_input, template), filename=paste0('results/tif/',COUNTRY, "_BK_avcr.tif"), overwrite=TRUE)
}