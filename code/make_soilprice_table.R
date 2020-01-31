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

acc <- rast("data/mktacc/acc.tif") 
acc <- warp(acc, gridorc)

slope <- rast("data/soil/srtm_slope_TZA.tif")
names(slope) <- "slope"

#SPAM <- rast("data/soil/spam2010v1r0_global_physical-area_maiz_a_TZA.tif")
SPAM <- gridorc/gridorc  #so the simulation is done in all TZA, not only in SPAM distribution
names(SPAM) <- "SPAM"

pop2020 <- rast("data/WorldPop/AFR_PPP_2020_adj_v2_TZA.tif")   #original SPATIAL RESOLUTION: 0.00833333 decimal degrees (approx 1km at the equator)
names(pop2020) <- "pop2020"

#### PRICE RASTERS ####
#urea_price <- rast("data/prices/TZA_urea_price.tif") #USD/kg#This is the price prediction from Camila. It is way to high. I don't know why
#N_price <- warp(urea_price/0.465, gridorc)

# I will use a constant N_price for now. $1 USD/kg of N
N_price <- gridorc/gridorc
names(N_price) <- "N_price"

maize_farmgate_price <- rast("data/prices/maize_farmgate_price/TZ_maipkghat_fgprice.tif") / 1598 #to convert from Tsh/kg to USD/kg 2013 prices
maize_farmgate_price <- warp(maize_farmgate_price, gridorc)
names(maize_farmgate_price) <- "maize_farmgate_price"

#### \\ Admin  ####
gadm36_TZA_1  <- rast("data/admin_and_AEZ/gadm36_TZA_1.tiff")

#### COMBINING RASTERS TO A TABLE ####
rasters_input <- cbind(values(gadm36_TZA_1),
                       values(pop2020),
                       values(gridorc),
                       values(gridacid),
                       values(acc),
                       values(slope),
                       values(SPAM),
                       values(N_price),
                       values(maize_farmgate_price)) %>% 
  as_tibble()

#### ADD ALL RAINFALL VALUES FROM 1981-2019 ####
rainfall_tif_files <- list.files("data/rainfall/", full.names = TRUE)

for (rainfall_tif_file in rainfall_tif_files){
  #rainfall_tif_file <- "data/rainfall/chirps-v2_200312-200405_sum_TZA.tif"
  year_label <- paste0("rainfall",
                       substr(rainfall_tif_file, 25, 28),
                       "_",
                       substr(rainfall_tif_file, 32, 35))
  
  #Extracting values for that years tif
  rainfall_tif <- rast(rainfall_tif_file)
  names(rainfall_tif) <- year_label
  rainfall_values <- values(rainfall_tif) %>% as_tibble()
  
  #binding to table
  rasters_input <- cbind(rasters_input,rainfall_values)
}

seasons <- c("rainfall1981_1982", "rainfall1982_1983", "rainfall1983_1984", "rainfall1984_1985",
             "rainfall1985_1986", "rainfall1986_1987", "rainfall1987_1988", "rainfall1988_1989",
             "rainfall1989_1990", "rainfall1990_1991", "rainfall1991_1992", "rainfall1992_1993", 
             "rainfall1993_1994", "rainfall1994_1995", "rainfall1995_1996", "rainfall1996_1997",
             "rainfall1997_1998", "rainfall1998_1999", "rainfall1999_2000", "rainfall2000_2001",
             "rainfall2001_2002", "rainfall2002_2003", "rainfall2003_2004", "rainfall2004_2005",
             "rainfall2005_2006", "rainfall2006_2007", "rainfall2007_2008", "rainfall2008_2009",
             "rainfall2009_2010", "rainfall2010_2011", "rainfall2011_2012", "rainfall2012_2013",
             "rainfall2013_2014", "rainfall2014_2015", "rainfall2015_2016", "rainfall2016_2017",
             "rainfall2017_2018", "rainfall2018_2019")
rasters_input$lograin <- rowMeans(log(rasters_input[,seasons]), na.rm = TRUE)  #to use all rainfalls. Faster than calculating all yields and then taking average

#### KEEPING ONLY COMPLETE CASES, AND CALCULATING NEW VARIABLES
rasters_input <- rasters_input %>% 
  mutate(index = 1:nrow(rasters_input)) %>% 
  filter(complete.cases(.)) %>% 
  mutate(loggridorc = log(gridorc)) %>% 
  dplyr::select(-gridorc)

#### PRINTING TO CHECK ####
head(rasters_input)

#### EXPORTING TABLE TO A FILE  ####
data.table::fwrite(rasters_input, file = "data/TZA_soilprice_table.csv")
