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
  #Converting binary string to fertilizer amounts
  N_kgha <- floor(N_kgha)

  #totfert cost and total ivnestment
  totfertcost <- pixel["N_price"] * N_kgha
  
  #if the fertilization cost is higher than the maximum ivestment allowed,
  #stop calculations and return low fitness outcome
  if(totfertcost > investment_max){   #investment_max is in startup.R
    return(-999)
  } else {
    #calculate nutrients from fertilizer amount
    yield <- yield_response(N = N_kgha, 
                            lograin = pixel["lograin"],
                            loggridorc = pixel["loggridorc"],
                            gridacid =  pixel["gridacid"],
                            acc = pixel["acc"],
                            slope= pixel["slope"])
    
    netrev <- pixel['maize_price'] * yield - totfertcost
    return(as.numeric(netrev))  #it should allow for only netrev as return, no??
  }
}