#' Fertilizer profitability formulas
#' * Marginal physical product (mp)
#' * Average physical product (ap)
#' * Average value cost ratio (acvr)
#' * Marginal value cost ratio (mcvr)
#'
#' \code{mcvr} 
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
mp <- function(yield_nf, yield_f, N_kgha_nf, N_kgha_f){
  (yield_f-yield_nf)/(N_kgha_f - N_kgha_nf)
}

ap <- function(yield_nf, yield_f, output_price, N_kgha_f, input_price){
  (yield_f-yield_f_nf)*output_price/(N_kgha*input_price)
}

enr <- function(yield_nf, yield_f, output_price, N_kgha_f, input_price){
  (yield_f-yield_f_nf)*output_price - (N_kgha*input_price)
}

mcvr <- function(output_price, mp, input_price){
  output_price*mp/input_price
}

acvr <- function(output_price, ap, input_price){
  output_price*ap/input_price
}