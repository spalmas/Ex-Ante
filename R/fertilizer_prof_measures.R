#' Fertilizer profitability formulas
#' * Marginal physical product (mp)
#' * Marginal vlaue cost ratio (mcvr)
#'
#' \code{mcvr} 
#'
#' @param pixel
#' 
#' @references  
#'
#' @examples
#' (mp0 <- mp(100,1000,0,30))
#' mcvr(0.4,mp0, 2)
mp <- function(yield_f, yield_nf, N_kgha_f, N_kgha_nf){
  (yield_f-yield_nf)/(N_kgha_f - N_kgha_nf)
}

ap <- function(yield_f, yield_nf, output_price, N_kgha, input_price){
  (yield_f-yield_nf)*output_price/(N_kgha*input_price)
}

enr <- function(yield_nf, yield_f, output_price, N_kgha, input_price){
  (yield_f-yield_nf)*output_price - (N_kgha*input_price)
}

mcvr <- function(output_price, mp, input_price){
  output_price*mp/input_price
}

acvr <- function(output_price, ap, input_price){
  output_price*ap/input_price
}