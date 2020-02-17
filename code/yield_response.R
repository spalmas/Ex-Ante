#' Simulates Fertilizer response to a nitrogen application
#'
#' \code{fert_response} Takes a vector of pixel parameters. More details in yield_response_fit.Rmd
#'
#' @param N_kgha applied Nitrogen
#' @param year 2017=1
#' @param intercrop Binary
#' @param rotat1 Crop rotation, binary
#' @param manure Binary
#' @param cropres Crop residue, Binary
#' @param weedings Number of weedings, Binary
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
#' @param elevation  #meters above sea level
#' @param slope  #degrees
#' @param seas_rainfall Seasonal (DEC-MAY) rainfall (mm)
#' 
#' @return yield (kg/ha)
#'
#' @examples
#' yield_response(N_kgha = 0, elevation = 100, slope=1, seas_rainfall = 62)
yield_response <- function(N_kgha, 
                           year = 2.016262e+03, 
                           intercrop = 5.250000e-01,   #mean value found in APS Tanzania data
                           rotat1 = 7.115385e-02,    #mean value found in APS Tanzania data
                           manure = 1.884615e-01,   #mean value found in APS Tanzania data
                           cropres = 1.038462e-01,   #mean value found in APS Tanzania data
                           weedings = 1.846154e+00,   #mean value found in APS Tanzania data
                           pesticide_bin = 1.923077e-03,   #mean value found in APS Tanzania data
                           impseed = 1.019231e-01,   #mean value found in APS Tanzania data
                           disease = 1.365385e-01,   #mean value found in APS Tanzania data
                           striga = 3.653846e-02,   #mean value found in APS Tanzania data
                           logha = -5.790308e-01,
                           headage = 4.742574e+01,   #mean value found in APS Tanzania data
                           femhead = 1.425743e-01,   #mean value found in APS Tanzania data
                           hhsize = 5.590385e+00,   #mean value found in APS Tanzania data
                           headeduc = 7.122772e+00,   #mean value found in APS Tanzania data
                           elevation,
                           slope,
                           seas_rainfall) {    #if year is 2017
  
  #### Parameters for each variable  ####
  intercept <- -1125632
  p_N_kgha <- 2.297359 
  p_year <- 558.4256   
  p_intercrop <- 96.5243 
  p_rotat1 <- -606.839
  p_manure <- 296.5286 
  p_cropres <- -106.0565
  p_weedings <- -21.68373 
  p_pesticide_bin <- -2374.574
  p_impseed <- 1437.885
  p_disease <- -211.2318
  p_striga <- 223.6319 
  p_logha <- 147.6604 
  p_headage <- -2.40868
  p_femhead <- -143.7437
  p_hhsize <- 36.73523
  p_headeduc <- 0.3248557 
  p_elevation <- 0.3986424 
  p_slope <- -125.503 
  p_seas_rainfall <- 2.238996
  
  #yield calculation
  yield <- intercept + 
    N_kgha*p_N_kgha+
    year*p_year +
    intercrop*p_intercrop +
    rotat1*p_rotat1 + 
    manure*p_manure +
    cropres*p_cropres + 
    weedings*p_weedings + 
    pesticide_bin*p_pesticide_bin + 
    impseed*p_impseed + 
    disease*p_disease + 
    striga*p_striga + 
    logha*p_logha + 
    headage*p_headage + 
    femhead*p_femhead + 
    hhsize*p_hhsize + 
    headeduc*p_headeduc + 
    elevation*p_elevation + 
    slope*p_slope +
    seas_rainfall*p_seas_rainfall
  
  #do not allow negative values.
  if (yield<0) yield <- 0
  
  return(yield)
}