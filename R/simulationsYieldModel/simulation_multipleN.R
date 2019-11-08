#simulating the change of profitability depending on input_price changes and N input

#### +++++++ SCRIPTS +++++++ ####
source('R/startup.R')
source('R/simulationsYieldModel/N_to_netrev.R')
source("R/buildraster.R")
source("R/fertilizer_prof_measures.R")

#### +++++++ PACKAGES +++++++ ####
library(dplyr)
library(magrittr)
library(terra)

#### +++++++ VALUES TO SIMULATE +++++++ #### 

#We will only simulate values of Arusha district (GADM == 0)
rasters_input_all <- read.csv('data/TZA_soilprice_table.csv') %>% filter(gadm36_TZA_1 == '0')

#### \\ Reading ZERO results to calculate changes ####
ZERO <- read.csv('results/tif/TZA_ZERO.csv') %>% filter(gadm36_TZA_1 == '0')

#price change values
N_price_changes <- seq(-1,1, 0.05)

#values of N_input to simulate
N_kg_has <- seq(0, 200, 1)

#Table of results to be filled
multipleN <- tibble(.rows=length(N_kg_has)*length(N_price_changes)) %>% 
  mutate(N_price_change = rep(N_price_changes, times=length(N_kg_has)) %>% sort(),
         N_kg_ha = rep(N_kg_has, times=length(N_price_changes)),
         netrev = NA,
         acvr = NA,
         mcvr = NA)
         
#### +++++++ SIMULATION +++++++ #### 
r <- 1 #to store values in table
p_pos <- 1
p_len <- length(N_price_changes)
for (p in N_price_changes){
  #p <- 0 #to test
  rasters_input_all_changed <- rasters_input_all %>% mutate(N_price=N_price*(1+p))
  
  for (N_kg_ha in N_kg_has){
    #N_kg_ha <- 0 #to tet
    yield <- mapply(FUN = yield_response,
                    N = N_kg_ha,   #nitrogen application kg/ha
                    lograin = rasters_input_all_changed$lograin,
                    loggridorc = rasters_input_all_changed$loggridorc,
                    gridacid = rasters_input_all_changed$gridacid,
                    acc = rasters_input_all_changed$acc,
                    slope = rasters_input_all_changed$slope)

    rasters_input_all_changed <- rasters_input_all_changed %>% 
      mutate(totfertcost = N_kg_ha * N_price,
             netrev = maize_price_farmgate*yield - totfertcost,
             mp=mp(yield_f=yield, yield_nf=ZERO$yield, N_kgha_f=N_kg_ha, N_kgha_nf=0),
             ap=ap(yield_f=yield, yield_nf=ZERO$yield, output_price=maize_price_farmgate, N_kgha=N_kg_ha, input_price=N_price),
             mcvr=mcvr(output_price=maize_price_farmgate, mp, input_price=N_price),
             acvr=acvr(output_price=maize_price_farmgate, ap, input_price=N_price))
    
    multipleN$netrev[r] <- mean(rasters_input_all_changed$netrev)
    multipleN$mcvr[r] <- mean(rasters_input_all_changed$mcvr)
    multipleN$acvr[r] <- mean(rasters_input_all_changed$acvr)
    
    r <- r + 1 
  } 
  print(paste0("Finished: ", p_pos, "/", p_len))
  p_pos <- p_pos + 1
}

