#Scripts to optimize fertilizer application pixel by pixel

#### +++++++ CLEAN MEMORY +++++++ ####
gc()
rm(list=ls())

#### +++++++ PACKAGES +++++++ ####
library(dplyr)
library(magrittr)
library(terra)

#### +++++++ SCRIPTS +++++++ ####
source("code/simulationsYieldModel/N_to_netrev.R")
source("code/buildraster.R")
source("code/fertilizer_prof_measures.R")
source("code/yield_response.R")

#### +++++++ TIMING +++++++ ####
t0 <- Sys.time()
print(t0)

#### +++++++ SIMULATION +++++++ #### 
#Getting the matrix of rasters data
rasters_input_all <- read.table(paste0("data/TZA_soilprice_table.txt"), header=TRUE, sep=" ")

########## \\ OPyield table start ###############
OPyield <- rasters_input_all %>% 
  dplyr::select(index, gadm36_TZA_1, N_price, maize_farmgate_price)

########## \\ OPyield OPTIMIZATION ###############
#pixel <- rasters_input_all[23918,]
#Optimization function
optim_pixel <- function(pixel, ...){
  solution <- optimize(f=yield_response,  #optimizing yield
                       interval=c(0,300),   #N_kgha options
                       seas_rainfall = pixel[["seas_rainfall"]],
                       elevation=pixel[["elevation"]],
                       slope=pixel[["slope"]],
                       maximum=TRUE, tol=0.0000001)
  if (solution$maximum<0 | solution$objective < 0){solution$maximum <- 0}
  return(floor(solution$maximum))
}
#optim_pixel(pixel)  #to test

# Apply optimization to each row
OPyield$N_kgha <- apply(X = rasters_input_all, FUN = optim_pixel, MARGIN = 1)  #not returning maximum (using other rows?)

#### \\ Calculating Yield  ####
OPyield$yield <- mapply(FUN = yield_response,
                        N = OPyield$N_kgha,   #nitrogen application kg/ha
                        seas_rainfall = rasters_input_all$seas_rainfall,
                        elevation = rasters_input_all$elevation,
                        slope = rasters_input_all[["slope"]])


#### \\ Calculating Yield0 for mvcr  ####
#Getting amount of fertilizer with one unit less
N_kgha0 <- OPyield$N_kgha-1
N_kgha0[N_kgha0<0] <- 0  #just in case some OPyield$N_kgha were negative

#Yield0
yield0 <- mapply(FUN = yield_response,
                 N = N_kgha0,   #nitrogen application kg/ha
                 seas_rainfall = rasters_input_all[["seas_rainfall"]],
                 elevation = rasters_input_all[["elevation"]],
                 slope = rasters_input_all[["slope"]])


#remove Inf values
OPyield$yield[is.infinite(OPyield$yield)] <- NA
yield0[is.infinite(yield0)] <- NA

#### \\ Reading ZERO results to calculate changes ####
ZERO <- read.csv(paste0("results/tables/", COUNTRY,"_ZERO.csv"))

#### \\ Calculating totfercost, netrevenue, changes and fertilizer profitabilities for OPyield ####
OPyield <- OPyield %>% 
  mutate(totfertcost = N_kgha * N_price,
         netrev = maize_farmgate_price*yield - totfertcost,
         yield_gain_perc = 100*(yield-ZERO$yield)/ZERO$yield,
         totfertcost_gain_perc = 100*(totfertcost-ZERO$totfertcost)/ZERO$totfertcost,
         netrev_gain_perc = 100*(netrev-ZERO$netrev)/ZERO$netrev,
         ap=ap(yield1=yield, N_kgha1=N_kgha),
         mp=mp(yield1=yield, yield0=yield0, N_kgha1=N_kgha, N_kgha0=N_kgha0),
         avcr=avcr(output_price=maize_farmgate_price, ap, input_price=N_price),
         mvcr=mvcr(output_price=maize_farmgate_price, mp, input_price=N_price))

#### +++++++ REMOVING Inf VALUES +++++++ ####
#Because some optimization results return a zero N_kg_ha, avcr and mvcr are not properly estimated.
#Here we remove all these Inf values from the avcr and mvcr for better plotting
OPyield$ap[OPyield$N_kgha==0] <- NA
OPyield$mp[OPyield$N_kgha==0] <- NA
OPyield$avcr[OPyield$N_kgha==0] <- NA
OPyield$mvcr[OPyield$N_kgha==0] <- NA

#### +++++++ WRITING RESULTS FILES +++++++ ####
#### \\ Writing table of pixel results
data.table::fwrite(OPyield, paste0("results/tables/TZA_OPyield.csv"))

#### \\ Writing rasters
template <- rast(paste0("data/CGIAR-SRTM/srtm_slope_TZA.tif"))
writeRaster(buildraster(OPyield$yield, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_yield.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$N_kgha, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_N_kgha.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_totfertcost.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_netrev.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$yield_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_yield_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$totfertcost_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_totfertcost_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$netrev_gain_perc, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_netrev_gain_perc.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$avcr, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_avcr.tif"), overwrite=TRUE)
writeRaster(buildraster(OPyield$mvcr, rasters_input_all, template), filename=paste0("results/tif/TZA_OPyield_mvcr.tif"), overwrite=TRUE)
#### +++++++ TIMING +++++++ ####
print(paste0("Finished : ", Sys.time() - t0))

#### +++++++ PARALLEL END +++++++ ####
#stopCluster(cl)
head(OPyield)
summary(OPyield[["netrev"]])
