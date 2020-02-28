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

########## ISRIC RASTERS  ############### 
af_ORCDRC_T__M_sd1_5000m_TZA <- rast("/media/sp/SPHD/Work/Ex-Ante/data/files.isric.org/af_ORCDRC_T__M_sd1_5000m_TZA.tif")
af_PHIHOX_T__M_sd1_5000m_TZA <- rast("/media/sp/SPHD/Work/Ex-Ante/data/files.isric.org/af_PHIHOX_T__M_sd1_5000m_TZA.tif")

rasters_input <- cbind(rasters_input,
                       values(af_ORCDRC_T__M_sd1_5000m_TZA),
                       values(af_PHIHOX_T__M_sd1_5000m_TZA))

#### N AND MAIZE PRICES ####
# I will use a constant N_price for now. $1 USD/kg of N
N_price <- rep(1, nrow(rasters_input))
rasters_input <- cbind(rasters_input, N_price)

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
rasters_input <- rasters_input[complete.cases(rasters_input),]

#### ADDING CONSTANT SOCIOECONOMIC VARIABLES FOUND IN TZAPS
rasters_input <- cbind(
  rasters_input,
  year           = 2.016310e+03,
  intercrop      = 5.643225e-01,
  rotat1         = 6.346484e-02,
  manure         = 1.972556e-01,
  cropres        = 9.262436e-02,
  weedings       = 1.826758e+00,
  impseed        = 1.355060e-01,
  disease        = 1.320755e-01,
  striga         = 3.430532e-02,
  fallow3yr      = 4.116638e-02,
  struct         = 2.521441e-01,
  terraced       = 3.430532e-02,
  logha          = -5.170819e-01,
  headage        = 4.777208e+01,
  femhead        = 1.360424e-01,
  hhsize         = 5.655232e+00,
  headeduc       = 7.051237e+00
)

#### PRINTING TO CHECK ####
head(rasters_input)
dim(rasters_input)
format(object.size(rasters_input), units="MB")

#### EXPORTING TABLE TO A FILE  ####
write.table(rasters_input, file="data/TZA_soilprice_table.txt", row.names=FALSE)
