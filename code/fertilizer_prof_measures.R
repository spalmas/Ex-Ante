#' Fertilizer profitability formulas
#'
#' @param yield1,yield0 yield from treatment and from treatment minus one unit of input (kg/ha)
#' @param N_kgha1,N_kgha0 Nitrogen applied in treatment and in treatment minus one unit  (kg/ha)
#' @param output_price  #farmgate price of crop ($/kg)
#' @param input_price  #price of N ($/kg)
#' 
#' @references  
#'
#' @examples
#' (mp0 <- mp(000,0000,0,30))
#' mcvr(0.4,mp0, 2)

#Average product
ap <- function(yield1, N_kgha1){
  yield1/N_kgha1
}

#Nitrogen use efficiency
nue <- function(yield1, yield0, N_kgha1){
  100*(yield1-yield0)/N_kgha1
}

#Marginal product
#In ex-ante, the increments of input are in unit of 1, then the DeltaY is just Y1-Y0, but I leave the complete formula just in case is used for other unit increments
mp <- function(yield1, yield0, N_kgha1, N_kgha0){
  (yield1-yield0)/(N_kgha1 - N_kgha0)
}

enr <- function(yield1, yield0, output_price, N_kgha1, input_price){
  (yield1-yield0)*output_price - (N_kgha1*input_price)
}

#Average value cost ratio
avcr <- function(output_price, ap, input_price){
  output_price*ap/input_price
}

#Marginal value cost ratio
mvcr <- function(output_price, mp, input_price){
  output_price*mp/input_price
}
