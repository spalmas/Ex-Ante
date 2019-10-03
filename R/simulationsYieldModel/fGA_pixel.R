#' Definition of fitness function for the GA using integers, pixel version
#'
#' \code{fGA_pixel} Pixel fitness function for the floor (integer) version
#'
#' @param N_amount  amount of applied nitrogen (kg/ha)
#' @param siteSoilNutrient
#' @param ... siteSoilNutrient, fert_price, investment_max
#' 
#' @return fitness value
#'
#' @examples
#' fGA_pixel(X=c(1,6), rasters_input = rasters_input, fert_price = fert_price) #example with 200 kg/ha of NPK and 100 kg/ha of urea
fGA_pixel <- function(N_amount, rasters_input, ...) {
  #rasters_input <- rasters_input_all[1,]
  #Converting binary string to fertilizer amounts
  #X <- c(1,2)
  N_amount <- floor(N_amount)

  #totfert cost and total ivnestment
  totfertcost <- rasters_input["N_price"] * N_amount
  
  #if the fertilization cost is higher than the maximum ivestment allowed,
  #stop calculations and return low fitness outcome
  if(totfertcost > investment_max){   #investment_max is in startup.R
    return(-999999)
  } else {
    #calculate nutrients from fertilizer amount
    yield <- yield_response(N = N_amount, 
                            lograin = rasters_input["lograin"],
                            loggridorc = rasters_input["loggridorc"],
                            gridacid =  rasters_input["gridacid"],
                            acc = rasters_input["acc"],
                            accsq= rasters_input["accsq"],
                            slope= rasters_input["slope"])
    
    gross_rev <- rasters_input['maize_price'] * yield
    netrev <- gross_rev-totfertcost
    return(as.numeric(netrev))  #it should allow for only netrev as return, no??
  }
}