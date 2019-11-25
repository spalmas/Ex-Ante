#!/usr/bin/env Rscript

library(terra)
library(tidyverse)

########## SOIL RASTERS ############### 
#load allrasters and warp to match Organic Carbon layer. It is a 1km resolution
gridorc <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
names(gridorc) <- "gridorc"

gridpH <- rast("data/soil/TZA_PHIHOX_T__M_sd1_1000m.tif") 
gridacid <- gridpH < 65  #value true/false acidity
names(gridacid) <- "gridacid"

rain <- rast("data/rainfall/chirps-v2_201612-201705_sum_TZA.tif") 
names(rain) <- "rain"

acc <- rast("data/mktacc/acc.tif") 
acc <- warp(acc, gridorc)

slope <- rast("data/soil/srtm_slope_TZA.tif")
names(slope) <- "slope"

SPAM <- rast("data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif")
names(SPAM) <- "SPAM"

pop2020 <- rast("data/WorldPop/AFR_PPP_2020_adj_v2_TZA.tif")   #original SPATIAL RESOLUTION: 0.00833333 decimal degrees (approx 1km at the equator)
names(pop2020) <- "pop2020"

#### PRICE RASTERS ####
#urea_price <- rast("data/prices/TZA_urea_price.tif") #USD/kg#This is the price prediction from Camila. It is way to high. I don't know why
#N_price <- warp(urea_price/0.465, gridorc)

# I will use a constant N_price for now. $1 USD/kg of N
N_price <- warp(1+0*gridorc, gridorc)
names(N_price) <- "N_price"

maize_price_farmgate <- rast("data/prices/maize_price_farmgate.tif")   #USD/kg
maize_price_farmgate <- warp(maize_price_farmgate, gridorc)
names(maize_price_farmgate) <- "maize_price_farmgate"

#### \\ Admin  ####
gadm36_TZA_1  <- rast("data/admin_and_AEZ/gadm36_TZA_1.tiff")

#### COMBINING RASTERS TO A TABLE ####
rasters_input <- cbind(values(gadm36_TZA_1),
                       values(pop2020),
                       values(gridorc),
                       values(gridacid),
                       values(rain),
                       values(acc),
                       values(slope),
                       values(SPAM),
                       values(N_price),
                       values(maize_price_farmgate)) %>% 
  as_tibble()

#### FILTERING OUT VALUES, CALCULATING NEW ONES ####
rasters_input <- rasters_input %>% 
  mutate(index = 1:nrow(rasters_input)) %>% 
  filter(complete.cases(.)) %>% 
  mutate(loggridorc = log(gridorc),
         lograin = log(rain)) %>% 
  dplyr::select(index, gadm36_TZA_1, pop2020, lograin, loggridorc, gridacid, acc, slope, N_price, maize_price_farmgate)

head(rasters_input)

#### EXPORTING TABLE TO A FILE  ####
data.table::fwrite(rasters_input, file = paste0('Data/TZA_soilprice_table.csv'))