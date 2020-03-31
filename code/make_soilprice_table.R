#!/usr/bin/env Rscript

# This script creates the table from which the simulations are run.
# It has one line per pixel with all the variables needed in the yield model and the prices for profitabilty.

#### +++++++ CLEAN MEMORY +++++++ ####
rm(list=ls())
gc()

#### +++++++ PACKAGES +++++++ ####
library(terra)
library(tidyverse)


########## RASTER TO USE FOR BUILDING TABLE AND AS TEMPLATE TO WARP  ############### 
srtm_TZA <- rast("data/CGIAR-SRTM/srtm_TZA.tif")

#### ADDING PIXEL INDEX
index <- 1:(dim(srtm_TZA)[1] * dim(srtm_TZA)[2])
rasters_input <- matrix(index)
colnames(rasters_input) <- "index"

########## ADDDING ELEVATION AND SLOPE TO THE TABLE  ############### 
#startging the table that will be exported
srtm_slope_TZA <- rast("data/CGIAR-SRTM/srtm_slope_TZA.tif")

rasters_input <- cbind(rasters_input, values(srtm_TZA) , values(srtm_slope_TZA))

#### ADMIN  ####
gadm36_TZA_1  <- rast("data/admin/gadm36_TZA_1.tiff")
rasters_input <- cbind(rasters_input, values(gadm36_TZA_1))
               

########## SPAM MAIZE PHYSICAL AREA  ############### 
SPAM2010 <- rast("data/SPAM/spam2010V1r1_global_A_MAIZ_A_TZA.tif")
rasters_input <- cbind(rasters_input,
                       values(SPAM2010))
                       
########## ISRIC RASTERS  ############### 
af_ORCDRC_T__M_sd1_5000m_TZA <- rast("data/files.isric.org/af_ORCDRC_T__M_sd1_5000m_TZA.tif")
af_PHIHOX_T__M_sd1_5000m_TZA <- rast("data/files.isric.org/af_PHIHOX_T__M_sd1_5000m_TZA.tif")

rasters_input <- cbind(rasters_input,
                       values(af_ORCDRC_T__M_sd1_5000m_TZA),
                       values(af_PHIHOX_T__M_sd1_5000m_TZA))

#### N AND MAIZE PRICES ####
# I will use a constant N_price for now. $1 USD/kg of N
N_price <- rast("data/prices/TZA_N_price.tif")
rasters_input <- cbind(rasters_input, values(N_price))

maize_farmgate_price <- rast("data/prices/maize_farmgate_price/maize_farmgate_price.tif")
maize_farmgate_price <- warp(maize_farmgate_price, srtm_TZA)
names(maize_farmgate_price) <- "maize_farmgate_price"
rasters_input <- cbind(rasters_input, values(maize_farmgate_price))

#### ADD ALL RAINFALL VALUES FROM 1981-2019 FROM CHIRPS OR CHIRPS####
#rainfall_rasters <- list.files("data/rainfall/", pattern = "^chirps.*\\.tif$", full.names = TRUE)
rainfall_rasters <- list.files("data/rainfall/", pattern = "^rfe.*05.*\\.tif$", full.names = TRUE)  #only those that have a 05 in the filaname (may include those that have 2005 in the name)
rainfall_rasters <- rainfall_rasters[grep(pattern = "12.*", rainfall_rasters)]  #keeping only those that have 12 in the filename 

seasons <- c()
for (rainfall_raster in rainfall_rasters){
  #rainfall_raster <- rainfall_rasters[9]  #to test
  #Extracting values for that years tif
  rainfall <- rast(rainfall_raster)
  names(rainfall) <- tools::file_path_sans_ext(basename(rainfall_raster))
  rasters_input <- cbind(rasters_input, values(rainfall))
  seasons <- c(seasons, names(rainfall))
}

#I couldn't do this in gdal because an overflow error
r1 <- rast("data/rainfall/rfe1987_12-1988_05.v3_sum_TZA.tif")
r2 <- rast("data/rainfall/rfe1995_12-1996_05.v3_sum_TZA.tif")
r3 <- rast("data/rainfall/rfe1996_12-1997_05.v3_sum_TZA.tif")
r4 <- rast("data/rainfall/rfe1999_12-2000_05.v3_sum_TZA.tif")
r5 <- rast("data/rainfall/rfe2000_12-2001_05.v3_sum_TZA.tif")
r6 <- rast("data/rainfall/rfe2001_12-2002_05.v3_sum_TZA.tif")
r7 <- rast("data/rainfall/rfe2002_12-2003_05.v3_sum_TZA.tif")
r8 <- rast("data/rainfall/rfe2003_12-2004_05.v3_sum_TZA.tif")
r9 <- rast("data/rainfall/rfe2005_12-2006_05.v3_sum_TZA.tif")
r10 <- rast("data/rainfall/rfe2007_12-2008_05.v3_sum_TZA.tif")
r11 <- rast("data/rainfall/rfe2008_12-2009_05.v3_sum_TZA.tif")
r12 <- rast("data/rainfall/rfe2009_12-2010_05.v3_sum_TZA.tif")
r13 <- rast("data/rainfall/rfe2010_12-2011_05.v3_sum_TZA.tif")
r14 <- rast("data/rainfall/rfe2011_12-2012_05.v3_sum_TZA.tif")
r15 <- rast("data/rainfall/rfe2012_12-2013_05.v3_sum_TZA.tif")
r16 <- rast("data/rainfall/rfe2013_12-2014_05.v3_sum_TZA.tif")
r17 <- rast("data/rainfall/rfe2014_12-2015_05.v3_sum_TZA.tif")
r18 <- rast("data/rainfall/rfe2015_12-2016_05.v3_sum_TZA.tif")
r19 <- rast("data/rainfall/rfe2016_12-2017_05.v3_sum_TZA.tif")
r20 <- rast("data/rainfall/rfe2017_12-2018_05.v3_sum_TZA.tif")
r21 <- rast("data/rainfall/rfe2018_12-2019_05.v3_sum_TZA.tif")
rmean <- (r1+r2+r3+r4+r5+r6+r7+r8+r9+r10+r11+r12+r13+r14+r15+r16+r17+r18+r19+r20+r21)/21
names(rmean) <- "rfeDEC-MAY.v3_MEAN_TZA"
writeRaster(rmean, filename = "data/rainfall/rfeDEC-MAY.v3_MEAN_TZA.tif", overwrite=TRUE)
rasters_input <- cbind(rasters_input, values(rmean))


#### KEEPING ONLY COMPLETE CASES
#SPAM will not count for the complete cases because we want to simulate all Tanzania for TZAPS compare.
#We just need SPAM for reasonable crop area calculations and for visualization
rasters_input <- rasters_input[complete.cases(rasters_input[, colnames(rasters_input) != "spam2010V1r1_global_A_MAIZ_A_TZA"]),]

#### ADDING CONSTANT SOCIOECONOMIC VARIABLES FOUND IN TZAPS
#the table of summary statistics is calculated in yield_response_fit.rmd
hh_summary_stats <- read.csv("data/hh_summary_stats.csv") 
hh_summary_stats_columns <- hh_summary_stats %>% dplyr::select(mean) %>% t() %>% data.frame()
colnames(hh_summary_stats_columns) <- hh_summary_stats$variable  #the t matrix does not keep the variable names
row.names(hh_summary_stats_columns) <- NULL  #the row name was causing an error when doing the cbind
rasters_input <- cbind(rasters_input, hh_summary_stats_columns)  #binding the values to the table. All pixels have the same hh values

#### PRINTING TO CHECK ####
head(rasters_input)
dim(rasters_input)
format(object.size(rasters_input), units="MB")

#### EXPORTING TABLE TO A FILE  ####
write.table(rasters_input, file="data/TZA_soilprice_table.txt", row.names=FALSE)
