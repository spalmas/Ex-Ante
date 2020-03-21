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

maize_farmgate_price <- rast("data/prices/maize_farmgate_price/TZ_maipkghat_fgprice.tif") / 1598 #to convert from Tsh/kg to USD/kg 2013 prices
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
