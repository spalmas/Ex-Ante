#Scripts to simulate  TZA using the yield response model

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')

#### +++++++ PACKAGES +++++++ ####
library(magrittr)

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
                  0,   #nitrogen application
                  rasters_input$lograin,
                  rasters_input$loggridorc,
                  rasters_input$gridacid,
                  rasters_input$acc,
                  rasters_input$accsq,
                  rasters_input$slope)
  
  #Export only csv of results
  data.table::fwrite(data.frame(yield), paste0('results/yield_response/', COUNTRY, '_ZERO_yield.csv'))
  
  ########## \\ Blanket Scenario ###############
  N_input <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, "N"]
  #Running yield model
  yield <- mapply(FUN = yield_response,
                  N_input,   #nitrogen application
                  rasters_input$lograin,
                  rasters_input$loggridorc,
                  rasters_input$gridacid,
                  rasters_input$acc,
                  rasters_input$accsq,
                  rasters_input$slope)
  data.table::fwrite(data.frame(yield), paste0('results/yield_response/', COUNTRY, '_BK_yield.csv'))
}


########## ++++ TO CALCULATE totfertcost AND netrev AND BUILD RASTERS ++++ ###############
rm(list=ls())

library(terra)
library(tidyverse)
source("R/buildraster.R")

#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('data/BAU_BK_inputs.csv')

for (COUNTRY in c("TZA")){
  #COUNTRY <- 'TZA'
  
  #Getting the matrix of rasters data
  rasters_input <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'))

  #### \\ Tables for scenario pixel results
  ZERO <- BK <- rasters_input %>% dplyr::select(index)
  
  #### \\ Getting kg/ha of fertilizers applied in BK scenario
  BK$N_amount <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, "N"]
  
  #### \\ Read BAU and BK yield rasters  ####
  ZERO$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_ZERO_yield.csv')) %>% as.matrix()
  BK$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_BK_yield.csv')) %>% as.matrix()

  #### \\ Calculating totfertcost rasters ####
  ZERO$totfertcost <- 0
  BK$totfertcost <- rasters_input$N_price * BK$N_amount
  
  #### \\ Calculating netrev rasters ####
  ZERO['netrev'] <- ZERO$yield * rasters_input$maize_price
  BK['netrev'] <- BK$yield * rasters_input$maize_price - BK$totfertcost
  
  #### \\ Calculating Percentage change values from ZERO scenario ####
  BK['yield_gain_perc'] <- 100 * (BK$yield - ZERO$yield) / ZERO$yield 
  BK['totfertcost_gain_perc'] <- 100 * (BK$totfertcost - ZERO$totfertcost) / ZERO$totfertcost 
  BK['netrev_gain_perc'] <- 100 * (BK$netrev - ZERO$netrev) / ZERO$netrev
  
  #### \\ Writing table ####
  data.table::fwrite(ZERO, paste0('results/yield_response/',COUNTRY, "_ZERO.csv"))
  data.table::fwrite(BK, paste0('results/yield_response/',COUNTRY, "_BK.csv"))

    #### \\ Writing rasters ####
  template <- rast(paste0('data/soil/', COUNTRY,'_ORCDRC_T__M_sd1_1000m.tif'))
  writeRaster(buildraster(ZERO$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$N_amount, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_N_amount.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_netrev.tif"), overwrite=TRUE)
}