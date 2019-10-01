#' Builds a raster based on a list and a template
#' 
#' \code{buildraster} saves the values of a table with index to a raster
#'
#' @param variable_results list of results 
#' @param rasters_input matrix of raster inputs to get the index used for simulation
#' @param template Template raster to copy 
#'
buildraster <- function(variable_result, rasters_input, template) {
  results  <- template
  values(results) <- NA
  values(results)[rasters_input[,'index']] <- variable_result
  return(results)
}