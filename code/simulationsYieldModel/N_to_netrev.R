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
#' source("code/yield_response.R")
#' pixel <- data.frame(elevation=0, slope =1, N_price = 1, maize_farmgate_price = 1, seas_rainfall = 642)
#' N_to_netrev(10, pixel)
N_to_netrev <- function(N_kgha, pixel, ...) {
  
  #N_kgha <- 00
  #total fertilization cost
  totfertcost <- pixel[["N_price"]] * N_kgha
  
  #calculate nutrients from fertilizer amount
  yield <- as.numeric(yield_response(N_kgha = N_kgha, 
                                     elevation = pixel[["elevation"]],
                                     slope= pixel[["slope"]],
                                     seas_rainfall = pixel[["seas_rainfall"]]))
  
  if(is.infinite(yield)){yield <- NA}
  netrev <- pixel[['maize_farmgate_price']] * yield - totfertcost
  return(netrev)  #it should allow for only netrev as return, no??
}