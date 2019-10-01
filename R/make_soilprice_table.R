#!/usr/bin/env Rscript

library(terra)
library(tidyverse)

########## SOIL RASTERS ############### 
#load allrasters and warp to match Organic Carbon layer

gridorc <- rast("data/soil/TZA_ORCDRC_T__M_sd1_250m.tif")
names(gridorc) <- "gridorc"

rain <- rast("data/rainfall/chirps-v2_201512-201605_sum.tif") 
names(rain) <- "rain"

gridpH <- rast("data/soil/TZA_PHIHOX_T__M_sd1_250m.tif") 
gridacid <- gridpH < 65
names(gridacid) <- "gridacid"

acc <- rast("data/mktacc/acc.tif") 
acc <- warp(acc, gridorc, filename="Data/mktacc/acc_warped.tif", overwrite	= TRUE)

slope <- rast("data/soil/srtm_slope_TZA.tif")
names(slope) <- "slope"

SPAM <- rast("data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif")
names(SPAM) <- "SPAM"

#### PRICE RASTERS ####
urea_price <- rast("Data/input_price/TZA_urea_price.tif")/1000  #original units in USD/ton from Camila
urea_price <- warp(urea_price, gridorc, filename="Data/input_price/TZA_urea_price_warped.tif", overwrite	= TRUE)
names(urea_price) <- "urea_price"

maize_price <- rast("Data/output_price/TZA_maize_price.tif")
maize_price <- warp(maize_price, gridorc, filename="Data/input_price/TZA_maize_price_warped.tif", overwrite	= TRUE)
names(maize_price) <- "maize_price"

########  MAKE SURE THAT THE PRICES ARE IN CORRECT UNITS USD/KG ######

#### \\ Admin and AEZ ####
#level_1 <- raster("data/admin/gadm36_TZA_1.tif")

#### COMBINING RASTERS TO A TABLE ####
rasters_input <- cbind(values(gridorc),
                       values(gridacid),
                       values(rain),
                       values(acc),
                       values(slope),
                       values(SPAM),
                       values(urea_price),
                       values(maize_price)) %>% 
  as_tibble()

#### FILTERING OUT VALUES, CALCULATING NEW ONES,  ####
rasters_input <- rasters_input %>% 
  mutate(index = 1:nrow(rasters_input)) %>% 
  filter(complete.cases(.)) %>% 
  filter(SPAM>500) %>% 
  mutate(loggridorc = log(gridorc),
         lograin = log(rain),
         accsq = acc^2) %>% 
  select(index, lograin, loggridorc, gridacid, acc, accsq, slope, urea_price, maize_price)

head(rasters_input)


#### EXPORTING TABLE TO A FILE  ####
write.csv(rasters_input, file = paste0('Data/TZA_soilprice_table.csv'))
