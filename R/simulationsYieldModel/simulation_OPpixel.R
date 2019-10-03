#Scripts to optimize fertilizer application pixel by pixel

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source('R/simulationsYieldModel/fGA_pixel.R')
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
  
  # \\ Table for scenario pixel results
  OPpixel <- rasters_input_all %>% dplyr::select(index, gadm36_TZA_1)

  ########## \\ OPpixel OPTIMIZATION ###############
  optim_fGA <- function(rasters_input, ...){
    solution <- optim(par = c(10), fn = fGA_pixel, method = 'L-BFGS-B',
                      rasters_input = rasters_input,
                      lower = c(0), upper = c(50),
                      control=list(fnscale=-1))  #-1 to make it a maximization problem
    return(floor(solution$par))
  }
  
  #### \\ Apply the optimization function to every pixel and store it ####
  #OPpixel$Namount <- parApply(cl = cl, X = rasters_input_all, FUN = optim_fGA, MARGIN = 1)
  OPpixel$N_amount <- apply(X = rasters_input_all, FUN = optim_fGA, MARGIN = 1)  #to test just a few pixels outside the parallel

  #### \\ Estimate totfertcost  ####
  OPpixel$totfertcost <- OPpixel$N_amount * rasters_input_all$N_price
  
  #### \\ Calculating Yield  ####
  OPpixel$yield <-  mapply(FUN = yield_response,
                           OPpixel$N_amount,   #nitrogen application
                           rasters_input_all$lograin,
                           rasters_input_all$loggridorc,
                           rasters_input_all$gridacid,
                           rasters_input_all$acc,
                           rasters_input_all$accsq,
                           rasters_input_all$slope)
  
  #### \\ Calculating net revenue  ####
  OPpixel['netrev'] <- OPpixel$yield * rasters_input_all$maize_price - OPpixel$totfertcost

  #### \\ Calculating Percentage change values from ZERO scenario ####
  ZERO <- read.csv('results/yield_response/TZA_ZERO.csv')
  OPpixel['yield_gain_perc'] <- 100 * (OPpixel$yield - ZERO$yield) / ZERO$yield 
  OPpixel['totfertcost_gain_perc'] <- 100 * (OPpixel$totfertcost - ZERO$totfertcost) / ZERO$totfertcost 
  OPpixel['netrev_gain_perc'] <- 100 * (OPpixel$netrev - ZERO$netrev) / ZERO$netrev
  
  #### +++++++ WRITING RESULTS FILES +++++++ ####
  #### \\ Writing table of pixel results
  data.table::fwrite(OPpixel, paste0('results/yield_response/',COUNTRY, "_OPpixel.csv"))

  #### \\ Writing rasters
  template <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
  writeRaster(buildraster(OPpixel$yield, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$N_amount, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_N_amount.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$totfertcost, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$netrev, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_netrev.tif"), overwrite=TRUE)
  
  #### +++++++ TIMING +++++++ ####
  print(paste0(COUNTRY, ': ', Sys.time() - t0))
}

#### +++++++ PARALLEL END +++++++ ####
#stopCluster(cl)

#Clean memory
gc()