#' Simulates Fertilizer response to a nitrogen application
#'
#' \code{fert_response} Takes a vector of pixel parameters...
#'
#' @param N applied Nitrogen
#' @param lograin mm of rain in season (log)
#' @param loggridorc  
#' @param gridacid africasoils pH value < 65
#' @param acc
#' @param accsq
#' @param slope
#' @param intercrop Binary
#' @param rotat1 Crop rotation, binary
#' @param manure Binary
#' @param cropres Crop residue, Binary
#' @param weedings Number of weedings, Binary
#' @param herbicide_n Binary
#' @param pesticide_n Binary
#' @param impseed Improved seed, Binary
#' @param disease Binary
#' @param striga Binary
#' @param logha log(ha)
#' @param headage Age of head of HH, Years
#' @param headagesq Age of head of HH, squared, Years^2
#' @param femhead Female head of HH, Binary
#' @param hhsize Household size, Persons
#' @param headeduc Years of education of head of HHYears
#' @param year 2017=1
#' 
#' @return yield (kg/ha)
#'
#' @examples
#' yield_response(N = 0, lograin = 6.8, loggridorc = 2.6, gridacid = 1,acc =900,slope=2)
yield_response <- function(N, 
                           lograin,
                           loggridorc,
                           gridacid,
                           acc,
                           slope,
                           intercrop = 0.5741935,   #mean value found in APS Tanzania data
                           rotat1 = 0.0840868,    #mean value found in APS Tanzania data
                           manure = 0.1952984,   #mean value found in APS Tanzania data
                           cropres = 0.0786618,   #mean value found in APS Tanzania data
                           weedings = 1.685353,   #mean value found in APS Tanzania data
                           herbicide_n = 0.0027125,   #mean value found in APS Tanzania data
                           pesticide_n = 0.0072333,   #mean value found in APS Tanzania data
                           impseed = 0.1925859,   #mean value found in APS Tanzania data
                           disease = 0.1229656,   #mean value found in APS Tanzania data
                           striga = 0.0271248,   #mean value found in APS Tanzania data
                           logha = -0.6459806,   #mean value found in APS Tanzania data
                           headage = 48.61806,   #mean value found in APS Tanzania data
                           headagesq = 2563.171,   #mean value found in APS Tanzania data
                           femhead = 0.1333333,   #mean value found in APS Tanzania data
                           hhsize = 5.670886,   #mean value found in APS Tanzania data
                           headeduc = 7.221596,   #mean value found in APS Tanzania data
                           year = 1) {    #if year is 2017
  #### Parameters for each variable  ####
  p_N <- 10.87
  p_NN <- -0.00942
  p_lograin <- 692.8
  p_intercrop <- -408.9
  p_rotat1 <- -294.4
  p_manure <- 465.8
  p_cropres <- -296.1
  p_weedings <- -31.94
  p_herbicide_n <- -303.6
  p_pesticide_n <- -2541
  p_impseed <- 714.5
  p_disease <- -118.4
  p_striga <- 46.53
  p_logha <- 247.9
  p_headage <- -9.239
  p_headagesq <- 0.0352
  p_femhead <- 0.0176
  p_hhsize <- 31.12
  p_headeduc <- -11.98
  p_loggridorc <- 550.8
  p_gridacid <- -315.5
  p_acc <- 11.82
  p_accsq <- -0.00638
  p_slope <- -65.92
  p_year <- 465.6
  constant <- -8228
  
  #yield calculation
  yield <- N*p_N + 
    N^2*p_NN+
    lograin*p_lograin +
    intercrop*p_intercrop +
    rotat1*p_rotat1 + 
    manure*p_manure +
    cropres*p_cropres + 
    weedings*p_weedings + 
    herbicide_n*p_herbicide_n + 
    pesticide_n*p_pesticide_n + 
    impseed*p_impseed + 
    disease*p_disease + 
    striga*p_striga + 
    logha*p_logha + 
    headage*p_headage + 
    headagesq*p_headagesq + 
    femhead*p_femhead + 
    hhsize*p_hhsize + 
    headeduc*p_headeduc + 
    loggridorc*p_loggridorc + 
    gridacid*p_gridacid + 
    acc*p_acc + 
    acc^2*p_accsq + 
    slope*p_slope + 
    year*p_year +
    constant
  
  #do not allow negative values.
  if (yield<0) yield <- 0
  
  return(yield)
}