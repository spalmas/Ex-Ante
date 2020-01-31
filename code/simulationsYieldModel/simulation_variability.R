#Scripts to simulate mean yields and netrevenues using all CHIRPS seasons and get variability

#### +++++++ SCRIPTS +++++++ ####
source('R/yield_response.R')
source('R/fertilizer_prof_measures.R')

#### +++++++ PACKAGES +++++++ ####
library(tidyverse)

#### +++++++ MATRIX OF SOIL DATA +++++++ ####
rasters_input <- read.csv(file="data/TZA_soilprice_table.csv")

#getting the names of rainfall seasons to use for results table 
seasons <- rasters_input %>% dplyr::select(starts_with("rainfall")) %>% colnames()

#### \\ Tables for scenario pixel results
VAR <- rasters_input %>% dplyr::select(index, gadm36_TZA_1, N_price, maize_farmgate_price)

#We will use the recommended Nitrogen level from the OPnetrev scenario
VAR$N_kgha <- read_csv("results/tables/TZA_OPnetrev.csv")$N_kgha  

########## +++++++ VARIABILITY +++++++ ###############
for(season in seasons){
  #season <- seasons[3] #to test
  lograin <- log(rasters_input[season])[,1]   #log rain for that season
  
  yield <- mapply(FUN = yield_response,
                  N = VAR$N_kgha,   #nitrogen application kg/ha
                  lograin = lograin,
                  loggridorc = rasters_input$loggridorc,
                  gridacid = rasters_input$gridacid,
                  acc = rasters_input$acc,
                  slope = rasters_input$slope)
  
  #### \\ Remove -Inf values  ####
  yield[is.infinite(yield)] <- NA
  
  #### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for VAR ####
  totfertcost <- VAR$N_price*VAR$N_kgha
  
  VAR[paste0("netrev_", season)] <- yield*VAR$maize_farmgate_price-totfertcost
  
  print (paste0("Finished: ", season))
}

VAR$netrev_mean <- VAR[,paste0("netrev_", seasons)] %>% rowMeans(na.rm = TRUE)
VAR$netrev_sd <- apply(VAR[,paste0("netrev_", seasons)], 1, sd, na.rm=TRUE)
VAR$netrev_cv <- 100*VAR$netrev_sd/VAR$netrev_mean

#deleting extreme values
#VAR$netrev_mean[VAR$netrev_mean <200 ] <- NA
#VAR$netrev_sd[VAR$netrev_mean <200 ] <- NA
#VAR$netrev_cv[VAR$netrev_mean < 85 ] <- NA


#### \\ Writing rasters ####
library(terra)
source("R/buildraster.R")
template <- rast(paste0('data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif'))
writeRaster(buildraster(VAR$netrev_mean, VAR, template), filename="results/tif/TZA_OPnetrev_netrev_mean.tif", overwrite=TRUE)
writeRaster(buildraster(VAR$netrev_sd, VAR, template), filename="results/tif/TZA_OPnetrev_netrev_sd.tif", overwrite=TRUE)
writeRaster(buildraster(VAR$netrev_cv, VAR, template), filename="results/tif/TZA_OPnetrev_netrev_cv.tif", overwrite=TRUE)
