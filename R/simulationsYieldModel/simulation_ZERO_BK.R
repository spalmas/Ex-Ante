#Scripts to simulate  TZA using the yield response model


#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('Data/BAU_BK_inputs.csv')

#### \\ Yield repsonse model
source("R/fert_response_model.R")

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
                  rasters_input$slope)  #Export only csv of results
  data.table::fwrite(data.frame(yield), paste0('Results/yield_response/', COUNTRY, '_BK_yield.csv'))
}


########## ++++ TO CALCULATE totfertcost AND netrev AND BUILD RASTERS ++++ ###############
rm(list=ls())

library(terra)
source("R/buildraster.R")

#### \\ Fertilizer amount table for BAU and BK ####
BAU_BK_inputs <- read.csv('data/BAU_BK_inputs.csv')

for (COUNTRY in c("TZA")){
  #COUNTRY <- 'TZA'
  
  #Getting the matrix of rasters data
  rasters_input <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'))
  
  #### \\ Input and output prices value. Mass fraction ####
  if(COUNTRY == 'ETH'){
    BK_inputs <-  c('Urea', 'NPS')
    rasters_input$in1price <- rasters_input$urea_price - (min(rasters_input$urea_price) - 0.3) #urea  #official price = 8.76 ETB/kg = 0.3 USD/kg (Boke et al., 2018)
    rasters_input$in2price <- rasters_input$urea_price - (min(rasters_input$urea_price) - 0.38) #NPS  #official price = 10.94 ETB/kg = 0.38 USD/ha  (Boke et al., 2018)
    } else if (COUNTRY == 'TZA'){
    BK_inputs <-  c('Urea', 'DAP')
    rasters_input$in1price <- rasters_input$urea_price * 1 #urea
    rasters_input$in2price <- rasters_input$urea_price * 1.3 #DAP
  }
  
  #### \\ Tables for scenario pixel results
  ZERO <- BK <- rasters_input %>% dplyr::select(index)
  
  #### \\ Getting kg/ha of fertilizers applied
  BK_inputs_kg.ha <- BAU_BK_inputs [BAU_BK_inputs$SCENARIO == 'BK' & BAU_BK_inputs$COUNTRY == COUNTRY, BK_inputs]
  
  #### \\ Read BAU and BK yield rasters  ####
  ZERO$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_ZERO_yield.csv')) %>% as.matrix()
  BK$yield <- read.csv(paste0('results/yield_response/', COUNTRY, '_BK_yield.csv')) %>% as.matrix()

  #### \\ Calculating totfertcost rasters ####
  ZERO$totfertcost <- 0
  BK$totfertcost <- rasters_input$in1price * BK_inputs_kg.ha[[1]] + rasters_input$in2price * BK_inputs_kg.ha[[2]]
  
  #### \\ Calculating Namount raster ####
  BK$Namount <- BAU_BK_inputs %>% filter(SCENARIO == 'BK' & COUNTRY == 'ETH') %>% select(N) %>% as.numeric()
  
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
  template <- rast(paste0('data/soil/', COUNTRY,'_ORCDRC_T__M_sd1_250m.tif'))
  writeRaster(buildraster(ZERO$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$yield, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$Namount, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_Namount.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$totfertcost, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(ZERO$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_ZERO_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(BK$netrev, rasters_input, template), filename=paste0('results/yield_response/',COUNTRY, "_BK_netrev.tif"), overwrite=TRUE)
}