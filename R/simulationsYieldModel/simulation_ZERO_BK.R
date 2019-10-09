#Scripts to simulate  TZA using the yield response model

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source("R/fertilizer_prof_measures.R")

#### +++++++ PACKAGES +++++++ ####
library(magrittr)
library(dplyr)

#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('Data/BAU_BK_inputs.csv')

#### +++++++ SIMULATION +++++++ ####
for (COUNTRY in c('TZA')){
  #COUNTRY <- 'TZA'  #to test

  #Getting the matrix of soil data
  rasters_input <- read.csv(file=paste0("data/", COUNTRY, "_soilprice_table.csv"))

  ########## +++++++ SCENARIOS +++++++ ###############
  ########## \\ ZERO Scenario ###############
  #Running yield model
  yield <- mapply(FUN = yield_response,
                  N = 0,   #nitrogen application kg/ha
                  lograin = rasters_input$lograin,
                  loggridorc = rasters_input$loggridorc,
                  gridacid = rasters_input$gridacid,
                  acc = rasters_input$acc,
                  slope = rasters_input$slope)
  
  #Export only csv of results
  data.table::fwrite(data.frame(yield), paste0('results/yield_response/', COUNTRY, '_ZERO_yield.csv'))
  
  ########## \\ Blanket Scenario ###############
  N_kgha <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, "N"]
  #Running yield model
  yield <- mapply(FUN = yield_response,
                  N = N_kgha,   #nitrogen application kg/ha
                  lograin = rasters_input$lograin,
                  loggridorc = rasters_input$loggridorc,
                  gridacid = rasters_input$gridacid,
                  acc = rasters_input$acc,
                  slope = rasters_input$slope)
  data.table::fwrite(data.frame(yield), paste0('results/yield_response/', COUNTRY, '_BK_yield.csv'))
}


########## ++++ TO CALCULATE totfertcost AND netrev AND BUILD RASTERS ++++ ###############
rm(list=ls())

library(terra)
library(tidyverse)
source("R/buildraster.R")
source('R/fertilizer_prof_measures.R')


#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('data/BAU_BK_inputs.csv')

for (COUNTRY in c("TZA")){
  #COUNTRY <- 'TZA'
  
  #Getting the matrix of rasters data
  rasters_input <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'), header=TRUE)

  #### \\ Tables for scenario pixel results
  ZERO <- BK <- rasters_input %>% dplyr::select(index, gadm36_TZA_1, N_price, maize_price)
  
  #### \\ Getting kg/ha of fertilizers applied in BK scenario
  BK$N_kgha <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, "N"]
  
  #### \\ Read BAU and BK yield rasters  ####
  ZERO$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_ZERO_yield.csv'), header = TRUE)[,1]
  BK$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_BK_yield.csv'), header = TRUE)[,1]

  #### \\ Calculating totfertcost netrevenue for ZERO ####
  ZERO <- ZERO %>% 
    mutate(totfertcost = 0,
           netrev = yield * maize_price
    )
  
  #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for BK ####
  BK <- BK %>% 
    mutate(totfertcost=N_price*N_kgha,
           netrev = maize_price-totfertcost,
           yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
           totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
           netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
           mp=mp(yield_f=yield, yield_nf=ZERO$yield, N_kgha_f=N_kgha,N_kgha_nf=0),
           ap=ap(yield_f=yield, yield_nf=ZERO$yield, output_price=maize_price, N_kgha=N_kgha, input_price=N_price),
           mcvr=mcvr(output_price=maize_price, mp, input_price=N_price),
           acvr=acvr(output_price=maize_price, ap, input_price=N_price)
    )
  
  #### \\ Writing table ####
  data.table::fwrite(ZERO, paste0('results/yield_response/',COUNTRY, "_ZERO.csv"))
  data.table::fwrite(BK, paste0('results/yield_response/',COUNTRY, "_BK.csv"))

  #### \\ Writing rasters ####
  template <- rast(paste0('data/soil/', COUNTRY,'_ORCDRC_T__M_sd1_1000m.tif'))
  writeRaster(buildraster(ZERO$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_netrev.tif"), overwrite=TRUE)
  
  writeRaster(buildraster(BK$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$N_kgha, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$yield_gain_perc, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_yield_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost_gain_perc, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_totfertcost_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev_gain_perc, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_netrev_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$mcvr, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_mcvr.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$acvr, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_acvr.tif"), overwrite=TRUE)
}