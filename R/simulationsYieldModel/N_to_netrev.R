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
#' pixel <- read.csv('data/TZA_soilprice_table.csv')[1,]
#' N_to_netrev(70, pixel)
N_to_netrev <- function(N_kgha, pixel, ...) {
  
  #N_kgha <- 70
  #totfert cost and total ivnestment
  totfertcost <- pixel[["N_price"]] * N_kgha
  
  #calculate nutrients from fertilizer amount
  yield <- yield_response(N = N_kgha, 
                          lograin = pixel[["lograin"]],
                          loggridorc = pixel[["loggridorc"]],
                          gridacid =  pixel[["gridacid"]],
                          acc = pixel[["acc"]],
                          slope= pixel[["slope"]])
  
  netrev <- pixel[['maize_price_farmgate']] * yield - totfertcost
  return(netrev)  #it should allow for only netrev as return, no??
}