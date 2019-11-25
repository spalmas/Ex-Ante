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
#price change values
N_price_changes <- seq(-1,1, 0.1)

#values of N_input to simulate
N_kg_has <- seq(0, 300, 5)

#We will simulate values for Arusha district (gadm36_TZA_1 == 0) and  Mbeya (gadm36_TZA_1 == 12)
for(region in c(0,12)){
  
  rasters_input_all <- read.csv('data/TZA_soilprice_table.csv') %>% filter(gadm36_TZA_1 == region)
  pop2020 <- sum(rasters_input_all$pop2020)
  
  #net revenue for comparisson
  ZERO <- read.csv('results/tables/TZA_ZERO.csv') %>% filter(gadm36_TZA_1 == region)
  ZERO$netrev[is.infinite(ZERO$netrev)] <- NA
  
  #Low and high netrev values will bebased on 10 and 90% percenties of the ZERO simulation
  low_netrev <- quantile(ZERO$netrev, 0.10, na.rm=TRUE) %>% round()  #10% percentile of the net revenue 
  high_netrev <- quantile(ZERO$netrev, 0.90, na.rm=TRUE) %>% round()  #90% percentile of the net revenue
  
  #maize area
  maize_area <- sum(!is.infinite(ZERO$netrev))
  
  #Table of results to be filled
  multipleN <- tibble(.rows=length(N_kg_has)*length(N_price_changes)) %>% 
    mutate(N_price_change = rep(N_price_changes, times=length(N_kg_has)) %>% sort(),
           N_kg_ha = rep(N_kg_has, times=length(N_price_changes)),
           netrev = NA,
           avcr = NA,
           mvcr = NA,
           area_low_netrev=NA,
           area_high_netrev=NA,
           ppop2020_low_netrev=NA,
           ppop2020_high_netrev=NA)
  
  #### +++++++ SIMULATION +++++++ #### 
  r <- 1 #to store values in table
  p_pos <- 1
  p_len <- length(N_price_changes)
  for (p in N_price_changes){
    #p <- 0 #to test
    rasters_input_all_changed <- rasters_input_all %>% mutate(N_price=N_price*(1+p))
    
    for (N_kg_ha in N_kg_has){
      #N_kg_ha <- 0 #to tet
      rasters_input_all_changed$yield <- mapply(FUN = yield_response,
                                                N = N_kg_ha,   #nitrogen application kg/ha
                                                lograin = rasters_input_all_changed$lograin,
                                                loggridorc = rasters_input_all_changed$loggridorc,
                                                gridacid = rasters_input_all_changed$gridacid,
                                                acc = rasters_input_all_changed$acc,
                                                slope = rasters_input_all_changed$slope)
      
      #remove Inf values
      rasters_input_all_changed$yield[is.infinite(rasters_input_all_changed$yield)] <- NA
      
      #calculating profitability values
      rasters_input_all_changed <- rasters_input_all_changed %>% 
        mutate(totfertcost = N_kg_ha * N_price,
               netrev = maize_price_farmgate*yield - totfertcost,
               ap=ap(yield=yield, N_kgha=N_kg_ha),
               mp=mp(yield_f=yield, yield_nf=ZERO$yield, N_kgha_f=N_kg_ha, N_kgha_nf=0),
               avcr=avcr(output_price=maize_price_farmgate, ap, input_price=N_price),
               mvcr=mvcr(output_price=maize_price_farmgate, mp, input_price=N_price)
               )
      
      #filling results summary table
      multipleN$netrev[r] <- mean(rasters_input_all_changed$netrev, na.rm=TRUE)
      multipleN$mvcr[r] <- mean(rasters_input_all_changed$mvcr, na.rm=TRUE)
      multipleN$avcr[r] <- mean(rasters_input_all_changed$avcr, na.rm=TRUE)
      
      #Low and high net revenue area percentage. Based on 10 and 90 percentile of the countrywide ZERO$netrev
      multipleN$area_low_netrev[r] <- sum(rasters_input_all_changed$netrev<=low_netrev, na.rm=TRUE)/maize_area
      multipleN$area_high_netrev[r] <- sum(rasters_input_all_changed$netrev>=high_netrev, na.rm=TRUE)/maize_area
      
      #Low and high net revenue population percentage. Based on 10 and 90 percentile ZERO$netrev
      multipleN$ppop2020_low_netrev[r] <- sum(rasters_input_all_changed$pop2020[rasters_input_all_changed$netrev<low_netrev], na.rm=TRUE)/pop2020
      multipleN$ppop2020_high_netrev[r] <- sum(rasters_input_all_changed$pop2020[rasters_input_all_changed$netrev>high_netrev], na.rm=TRUE)/pop2020
      
      r <- r + 1 
    } 
    print(paste0("Finished: ", p_pos, "/", p_len))
    p_pos <- p_pos + 1
  }
  
  #### EXPORTING TABLE TO A FILE  ####
  data.table::fwrite(multipleN, file = paste0("results/tables/TZA_multipleN_region", region, ".csv"))  
}