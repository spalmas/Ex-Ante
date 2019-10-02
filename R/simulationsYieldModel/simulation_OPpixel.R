#Scripts to optimize fertilizer application pixel by pixel

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source('R/simulationsYieldModel/fGA_pixel.R')

#### +++++++ PACKAGES +++++++ ####
library(magrittr)
library(terra)


#### +++++++ PARALLEL START +++++++ ####
no_cores <- detectCores()     #number of cores to use in process
cl <- makeCluster(no_cores, type = 'FORK', outfile = 'cluster_debug_file.txt')  #FORK with only work in unix-based systems

#### +++++++ SIMULATION +++++++ #### 
i <- 1
for (COUNTRY in c('TZA')){
  #COUNTRY <- 'TZA'  #to test
  t0 <- Sys.time()
  print(t0)
  
  #Getting the matrix of rasters data
  rasters_input_all <- read.csv(file = paste0('data/', COUNTRY , '_soilprice_table.csv'))
  
  #### \\ Input and output prices value ####
  if(COUNTRY == 'ETH'){
    BK_inputs <-  c('Urea', 'NPS')
    fert_massfrac <- all_fert_massfrac[c(1,2),]      #N,P,K Mass fraction for Urea and NPS
    
    rasters_input_all$in1price <- rasters_input_all$urea_price - (min(rasters_input_all$urea_price) - 0.3) #urea  #official price = 8.76 ETB/kg = 0.3 USD/kg (Boke et al., 2018)
    rasters_input_all$in2price <- rasters_input_all$urea_price - (min(rasters_input_all$urea_price) - 0.38) #NPS  #official price = 10.94 ETB/kg = 0.38 USD/ha  (Boke et al., 2018)
    
  } else if (COUNTRY == 'TZA'){
    BK_inputs <-  c('Urea', 'DAP')
    fert_massfrac <- all_fert_massfrac[1,]      #N,P,K Mass fraction for Urea and DAP
    
    rasters_input_all$Nprice <- rasters_input_all$urea_price / 0.46  #0.46 in each kg of urea. This returns the price of a kg of Nitrogen using urea
  }

  # \\ Table for scenario pixel results
  OPpixel <- rasters_input_all %>% dplyr::select(index, gadm36_TZA_1, AEZ)

  ########## \\ OPpixel OPTIMIZATION ###############
  optim_fGA <- function(rasters_input, ...){
    solution <- optim(par = c(10), fn = fGA_pixel, method = 'L-BFGS-B',
                      rasters_input = rasters_input,
                      lower = c(0), upper = c(50),
                      control=list(fnscale=-1))  #-1 to make it a maximization problem
    return(floor(solution$par))
  }
  
  #### \\ Apply the optimization function to every pixel and store it ####
  OPpixel$Namount <- parApply(cl = cl, X = rasters_input_all, FUN = optim_fGA, MARGIN = 1)
  #apply(X = rasters_input_all[1:5,], FUN = optim_fGA, MARGIN = 1)  #to test just a few pixels outside the parallel

  #### \\ Estimate totfertcost  ####
  OPpixel$totfertcost <- OPpixel$Namount * rasters_input_all$Nprice
  
  #### \\ Calculating Yield  ####
  OPpixel$yield <-  mapply(FUN = yield_response,
                           OPpixel$Namount,   #nitrogen application
                           rasters_input_all$lograin,
                           rasters_input_all$loggridorc,
                           rasters_input_all$gridacid,
                           rasters_input_all$acc,
                           rasters_input_all$accsq,
                           rasters_input_all$slope)
  
  #### \\ Calculating net revenue  ####
  OPpixel['netrev'] <- OPpixel$yield * rasters_input_all$maize_price - OPpixel$totfertcost

  #### \\ Calculating Percentage change values from ZERO scenario ####
  ZERO <- read.csv('results/yield_response/ETH_ZERO.csv')
  OPpixel['yield_gain_perc'] <- 100 * (OPpixel$yield - ZERO$yield) / ZERO$yield 
  OPpixel['totfertcost_gain_perc'] <- 100 * (OPpixel$totfertcost - ZERO$totfertcost) / ZERO$totfertcost 
  OPpixel['netrev_gain_perc'] <- 100 * (OPpixel$netrev - ZERO$netrev) / ZERO$netrev
  
  #### +++++++ WRITING RESULTS FILES +++++++ ####
  #### \\ Writing table of pixel results
  data.table::fwrite(OPpixel, paste0('results/yield_response/',COUNTRY, "_OPpixel.csv"))

  #### \\ Writing rasters
  template <- rast(paste0('data/soil/', COUNTRY,'_ORCDRC.tif'))
  writeRaster(buildraster(OPpixel$yield, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_yield.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$Namount, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_Namount.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$totfertcost, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_totfertcost.tif"), overwrite=TRUE)
  writeRaster(buildraster(OPpixel$netrev, rasters_input_all, template), filename=paste0('results/yield_response/',COUNTRY, "_OPpixel_netrev.tif"), overwrite=TRUE)
  
  #### +++++++ TIMING +++++++ ####
  print(paste0(COUNTRY, ': ', Sys.time() - t0))
}

#### +++++++ PARALLEL END +++++++ ####
stopCluster(cl)

#Clean memory
gc()