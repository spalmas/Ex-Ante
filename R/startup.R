# startup.R file to begin all QUEFTS analysis

#Clean memory
gc()
rm(list=ls())

#### PACKAGES ####

#### SCRIPTS ####
source("R/yield_response.R")

########## FOLDER DEPENDING ON SYSTEM ###############
sys.name <- Sys.info()['sysname']
if (sys.name == 'Windows'){
  files.path <- 'C:/Users/S.PALMAS/source/repos/spalmas/Ex-Ante'
} else if (sys.name == 'Linux'){
  files.path <- '~/'
}

########## MASS FRACTION MATRIX OF FERTILIZERS USED IN SIMULATION  ###############
all_fert_massfrac <-  matrix(c(0.46, 0.0, 0.0,     #Urea nutrients
                               0.19, 0.38, 0.0,   #NPS nutrients
                               0.18, 0.46, 0.0),      #DAP nutrientss
                             ncol = 3, byrow = TRUE)      #N,P,K Mass fraction for Urea, NPS and DAP

########## MXIMUM INVESTMENT ALLOWED IN EACH OPTIMIZATION  ###############
investment_max <- 200   #Max investment (USD/ha)

########## CURRENCY EXCHANGE RATES  ###############
ex <- data.frame(COUNTRY = c('ETH', 'NGA', 'TZA'),  
                 CURRENCY = c('ETB', 'NGN', 'TZS'),
                 rate2018 = c(28.01, 363.35, 2291.20))