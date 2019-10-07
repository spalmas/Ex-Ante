#' Definition of fitness function for the GA using integers, pixel version
#'
#' \code{N_to_netrev} Pixel fitness function for the floor (integer) version
#'
#' @param N_kgha  amount of applied nitrogen (kg/ha)
#' @param siteSoilNutrient
#' @param ... siteSoilNutrient, fert_price, investment_max
#' 
#' @return fitness value
#'
#' @examples
#' rasters_input <- read.csv('data/TZA_soilprice_table.csv')[1,]
#' N_to_netrev(50, rasters_input)
N_to_netrev <- function(N_kgha, rasters_input, ...) {
  #Converting binary string to fertilizer amounts
  N_kgha <- floor(N_kgha)

  #totfert cost and total ivnestment
  totfertcost <- rasters_input["N_price"] * N_kgha
  
  #if the fertilization cost is higher than the maximum ivestment allowed,
  #stop calculations and return low fitness outcome
  if(totfertcost > investment_max){   #investment_max is in startup.R
    return(-999999)
  } else {
    #calculate nutrients from fertilizer amount
    yield <- yield_response(N = N_kgha, 
                            lograin = rasters_input["lograin"],
                            loggridorc = rasters_input["loggridorc"],
                            gridacid =  rasters_input["gridacid"],
                            acc = rasters_input["acc"],
                            slope= rasters_input["slope"])
    
    netrev <- rasters_input['maize_price'] * yield - totfertcost
    return(as.numeric(netrev))  #it should allow for only netrev as return, no??
  }
}