# Simulation of fertilizer application profitability for Tanzania

These scripts are used to predict if N application is profitable in maize farms in Tanzania. Incorporates soil characteristics, maize price predictions, fertilizer price and distance to markets.

## Code

* [simulationsYieldModel/simulation_OPnetrev_rf.R](code/simulationsYieldModel/simulation_OPnetrev_rf.R): simulation to get an optimized nitrogen application amount for a maximum profitability.
* [simulationsYieldModel/simulation_OPyield_rf.R](code/simulationsYieldModel/simulation_OPyield_rf.R): simulation to get an optimized nitrogen application amount for a maximum yield.
* [simulationsYieldModel/simulation_ZERO_BK_rf.R](code/simulationsYieldModel/simulation_ZERO_BK_rf.R): simulation for no nitrogen and a blanket nitrogen application amount.
* [simulationsYieldModel/N_to_netrev.R](code/simulationsYieldModel/N_to_netrev.R): Definition of the fitness function to optimize for profitability.
* [access.rmd](code/access.rmd): to estimate time from every pixel to to large cities.
* [buildraster.R](code/buildraster.R): function to use when constructing a raster from values in a table.
* [fertilizer_price.rmd](code/fertilizer_price.rmd): simple model to create fertilizer price using city access, a mean fertilizer price and a correction factor depending on transportation costs.
* [fertilizer_prof_measures.R](code/fertilizer_prof_measures.R): Methods for fertilizer profitability measures such as NUE, AVCR, MVCR.
* [fitness.R](code/fitness.R): Methods for r squared and RMSE.
* [maize_price_farmgate.rmd](code/maize_price_farmgate.rmd): To estimate maize farmgate prices depending on market prices in several locations and using market access.
* [maize_price_market.rmd](code/maize_price_market.rmd): Random forest model to predict maize market prices using multiple covariates.
* [make_soilprice_table.R](code/make_soilprice_table.R): Creates a table from multiple rasters that will be used in the simulation.
* [preprocess_rasters.sh](code/preprocess_rasters.sh): Processes all original elevation, slope, soil, rainfall rasters to a common geometry to use in the analysis. It runs as a bash script in linux.
* [rainfall_CV.R](code/rainfall_CV.R): To estimate coefficient of variance of the rainfall in Tanzania.
* [Results_TablesFigures.rmd](code/Results_TablesFigures.rmd): To create tables and figures for the paper.
* [run_simulations.sh](code/run_simulations.sh): 
* [TZAPS_hhid_coords_extract.R](code/TZAPS_hhid_coords_extract.R): to extract covariates from many rasters into a table with the household measurements to use in the yield prediction.
* [yield_response.R](code/yield_response.R): Previous linear fit model for yield response.
* [yield_response_fit.rmd](code/yield_response_fit.rmd): To fit a random forest model for yield using multiple covariates.





## Data


* [data/hh_summary_stats.csv](data/hh_summary_stats.csv): Contains all the household variable means used in the simulation.

* [data/models/yield.rf2.rda](data/models/yield.rf2.rda): Random forest model used in the simulation.