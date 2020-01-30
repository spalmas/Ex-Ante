#' Definition of fitness function for the GA using integers, pixel version
#'
#' \code{N_to_netrev} Pixel fitness function for the floor (integer) version
#'
#' @param N_kgha  amount of applied nitrogen (kg/ha)
#' @param pixel
#' 
#' @return net revenue value
#'
#' @examples
#' source("R/yield_response.R")
#' rasters_input <- read.csv('data/TZA_soilprice_table.csv')
#' pixel <- rasters_input[8,]
#' N_to_netrev(seq(0,200,5), pixel)
#' N_to_netrev(00, pixel)
N_to_netrev <- function(N_kgha, pixel, ...) {
  
  #N_kgha <- 00
  #total fertilization cost
  totfertcost <- pixel[["N_price"]] * N_kgha
  
  #calculate nutrients from fertilizer amount
  yield <- as.numeric(yield_response(N = N_kgha, 
                                     lograin = pixel[["lograin"]],
                                     loggridorc = pixel[["loggridorc"]],
                                     gridacid =  pixel[["gridacid"]],
                                     acc = pixel[["acc"]],
                                     slope= pixel[["slope"]]))
  
  if(is.infinite(yield)){yield <- NA}
  netrev <- pixel[['maize_farmgate_price']] * yield - totfertcost
  return(netrev)  #it should allow for only netrev as return, no??
}