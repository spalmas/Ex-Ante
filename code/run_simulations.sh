#!/bin/bash

cd source/repos/spalmas/Ex-Ante
Rscript code/make_soilprice_table.R
Rscript code/simulationsYieldModel/simulation_ZERO_BK_rf.R
Rscript code/simulationsYieldModel/simulation_OPyield_rf.R
Rscript code/simulationsYieldModel/simulation_OPnetrev_rf.R

#copy results to SPHD
cp --recursive results /media/sp/SPHD
