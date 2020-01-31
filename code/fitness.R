rsq <- function (obs, pred) cor(obs, pred, use = 'complete.obs') ^ 2
RMSE <- function(obs, pred){sqrt(mean((pred - obs)^2, na.rm = TRUE))}
