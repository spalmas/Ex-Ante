#Scripts to optimize fertilizer application pixel by pixel

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source('R/simulationsYieldModel/N_to_netrev.R')
source("R/buildraster.R")

#### +++++++ PACKAGES +++++++ ####
library(magrittr)
library(terra)

#### +++++++ PARALLEL START +++++++ ####
#no_cores <- detectCores()     #number of cores to use in process
#cl <- makeCluster(no_cores, type = 'FORK', outfile = 'cluster_debug_file.txt')  #FORK with only work in unix-based systems

#### +++++++ SIMULATION +++++++ #### 
i <- 1
for (COUNTRY in c('TZA')){
  #COUNTRY <- 'TZA'  #to test
  t0 <- Sys.time()
  print(t0)
  
  #Getting the matrix of rasters data
  rasters_input_all <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'))
  
  ########## \\ OPpixel table start ###############
  OPpixel <- rasters_input_all %>% 
    dplyr::select(index, N_price, maize_price)

  ########## \\ OPpixel OPTIMIZATION ###############
  #Maximum investment in Nitrogen
  investment_max <- 300   #Max investment (USD/ha)
  
  optim_pixel <- function(pixel, ...){
    solution <- optimize(f=N_to_netrev, interval=c(0,200), pixel = pixel, maximum=TRUE)
    return(list(N_kgha = floor(solution$maximum), netrev = solution$objective))
  }
  
  # Apply optimization to each row
  OPpixel_list <- apply(X = rasters_input_all, FUN = optim_pixel, MARGIN = 1)  #not returning maximum (using other rows?)
  #optim_pixel(rasters_input_all[1,])
  #Convert list to table
  OPpixel <- purrr::map_df(OPpixel_list, ~as.data.frame(t(.)))
  #unlist columns
  OPpixel$N_kgha <- OPpixel$N_kgha %>% unlist()
  OPpixel$netrev <- OPpixel$netrev %>% unlist()
  
  #### \\ Appending columns  ####
  OPpixel$index <- rasters_input_all$index
  OPpixel$N_price <- rasters_input_all$N_price
  OPpixel$maize_price <- rasters_input_all$maize_price

  #### \\ Estimate totfertcost  ####
  OPpixel$totfertcost <- OPpixel$N_kgha * OPpixel$N_price
  
  #### \\ Calculating Yield  ####
  OPpixel$yield <- mapply(FUN = yield_response,
                          N = OPpixel$N_kgha,   #nitrogen application kg/ha
                          lograin = rasters_input_all$lograin,
                          loggridorc = rasters_input_all$loggridorc,
                          gridacid = rasters_input_all$gridacid,
                          acc = rasters_input_all$acc,
                          slope = rasters_input_all$slope)
  
  #### \\ Calculating Percentage change values from ZERO scenario ####
  ZERO <- read.csv(paste0('results/yield_response/',COUNTRY,'_ZERO.csv'))
  OPpixel['yield_gain_perc'] <- 100 * (OPpixel$yield - ZERO$yield) / ZERO$yield 
  OPpixel['totfertcost_gain_perc'] <- 100 * (OPpixel$totfertcost - ZERO$totfertcost) / ZERO$totfertcost 
  OPpixel['netrev_gain_perc'] <- 100 * (OPpixel$netrev - ZERO$netrev) / ZERO$netrev
  
  #### +++++++ WRITING RESULTS FILES +++++++ ####
  #### \\ Writing table of pixel results
  data.table::fwrite(OPpixel, paste0('results/yield_response/', COUNTRY, "_OPpixel.csv"))
  
  #### \\ Writing rasters
  template <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
  writeRaster(buildraster(OPpixel$yield, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$N_kgha, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_N_kgha.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$totfertcost, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$netrev, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_netrev.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$yield_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_yield_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$totfertcost_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_totfertcost_gain_perc.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$netrev_gain_perc, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_netrev_gain_perc.tif"), overwrite=TRUE)
  
  #### +++++++ TIMING +++++++ ####
  print(paste0(COUNTRY, ': ', Sys.time() - t0))
}

#### +++++++ PARALLEL END +++++++ ####
#stopCluster(cl)
head(OPpixel)