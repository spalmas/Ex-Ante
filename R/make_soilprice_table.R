#!/usr/bin/env Rscript

library(terra)
library(tidyverse)

########## SOIL RASTERS ############### 
#load allrasters and warp to match Organic Carbon layer

gridorc <- rast("data/soil/TZA_ORCDRC_T__M_sd1_1000m.tif")
names(gridorc) <- "gridorc"

gridpH <- rast("data/soil/TZA_PHIHOX_T__M_sd1_1000m.tif") 
gridacid <- gridpH < 65
names(gridacid) <- "gridacid"

rain <- rast("data/rainfall/chirps-v2_201612-201705_sum_TZA.tif") 
names(rain) <- "rain"

acc <- rast("data/mktacc/acc.tif") 
acc <- warp(acc, gridorc, filename="Data/mktacc/acc_warped.tif", overwrite	= TRUE)

slope <- rast("data/soil/srtm_slope_TZA.tif")
names(slope) <- "slope"

SPAM <- rast("data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif")
names(SPAM) <- "SPAM"

#### PRICE RASTERS ####
urea_price <- rast("Data/prices/TZA_urea_price.tif") #USD/kg
#divide /0.465 to convert to price per kg of N
N_price <- warp(urea_price/0.465, gridorc, filename="Data/prices/TZA_urea_price_warped.tif", overwrite	= TRUE)
names(N_price) <- "N_price"

maize_price <- rast("Data/prices/pred_maize_price1.tif") / 2292 #/2292 to convert to USD/kg
maize_price <- warp(maize_price, gridorc, filename="Data/prices/pred_maize_price1_warped.tif", overwrite	= TRUE)
names(maize_price) <- "maize_price"

#### \\ Admin  ####
gadm36_TZA_1  <- rast("data/admin_and_AEZ/gadm36_TZA_1.tiff")

#### COMBINING RASTERS TO A TABLE ####
rasters_input <- cbind(values(gadm36_TZA_1),
                       values(gridorc),
                       values(gridacid),
                       values(rain),
                       values(acc),
                       values(slope),
                       values(SPAM),
                       values(N_price),
                       values(maize_price)) %>% 
  as_tibble()

#### FILTERING OUT VALUES, CALCULATING NEW ONES,  ####
rasters_input <- rasters_input %>% 
  mutate(index = 1:nrow(rasters_input)) %>% 
  filter(complete.cases(.)) %>% 
  mutate(loggridorc = log(gridorc),
         lograin = log(rain)) %>% 
  dplyr::select(index, gadm36_TZA_1, lograin, loggridorc, gridacid, acc, slope, N_price, maize_price)

head(rasters_input)

#### EXPORTING TABLE TO A FILE  ####
data.table::fwrite(rasters_input, file = paste0('Data/TZA_soilprice_table.csv'))