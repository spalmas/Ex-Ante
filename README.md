# Simulation of fertilizer application profitability for Tanzania

These scripts are used to predict if N application is profitable in maize farms in Tanzania. Incorporates soil characteristics, maize price predictions, fertilizer price and distance to markets.


* [code/access.rmd](code/access.rmd): to estimate time from every pixel to to large cities.
* [code/buildraster.R](code/buildraster.R): function to use when constructing a raster from values in a table.
* [code/preprocess_rasters.sh](code/preprocess_rasters.sh): processes all original elevation, slope, soil, rainfall rasters to a common geometry to use in the analysis. It runs as a bash script in linux.


## Data


* [data/hh_summary_stats.csv](data/hh_summary_stats.csv): Contains all the household variable means used in the simulation.

* [data/models/yield.rf2.rda](data/models/yield.rf2.rda): Random forest model used in the simulation.