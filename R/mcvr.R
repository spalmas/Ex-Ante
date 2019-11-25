#' Fertilizer profitability formulas
#'
#' @param yield_nf,yield_f yield from of non-fertilized and fertilized areas (kg/ha)
#' @param N_kgha_nf,N_kgha_f Nitrogen applied in non-fertilized and fertilized areas  (kg/ha)
#' @param output_price  #farmgate price of crop ($/kg)
#' @param input_price  #price of N ($/kg)
#' 
#' @references  
#'
#' @examples
#' (mp0 <- mp(100,1000,0,30))
#' mcvr(0.4,mp0, 2)

#Average product
ap <- function(yield, N_kgha){
  yield/N_kgha
}

#Marginal product
mp <- function(yield_nf, yield_f, N_kgha_nf, N_kgha_f){
  (yield_f-yield_nf)/(N_kgha_f - N_kgha_nf)
}

enr <- function(yield_nf, yield_f, output_price, N_kgha_f, input_price){
  (yield_f-yield_f_nf)*output_price - (N_kgha*input_price)
}

#Average value cost ratio
avcr <- function(output_price, ap, input_price){
  output_price*ap/input_price
}

#Marginal value cost ratio
mvcr <- function(output_price, mp, input_price){
  output_price*mp/input_price
}
