# --------------------------------------------------- #
# Author: Marius D. Pascariu
# License: GNU General Public License v3.0
# Last update: Fri Nov 23 16:47:29 2018
# --------------------------------------------------- #


#' The Oeppen Mortality Model (Oeppen -- CoDa)
#' 
#' Fit the Oeppen model for forecasting the life table 
#' distribution of deaths. This is a Lee-Carter type model adapted to a 
#' compositional-data framework (CoDa). A key difference 
#' between the \insertCite{lee1992;textual}{MortalityForecast}
#' method and the Oeppen model is that the former fits and 
#' forecasts the death rates (mx) while the latter is based on the life table 
#' death distribution (dx). 
#' \insertCite{@See @oeppen2008 and @bergeron2017;textual}{MortalityForecast} 
#' for a detail description and mathematical formulation.
#' @inheritParams do.MortalityModels 
#' @return The output is a list with the components:
#'  \item{input}{List with arguments provided in input. Saved for convenience;}
#'  \item{info}{Short details about the model;}
#'  \item{call}{An unevaluated function call, that is, an unevaluated 
#'  expression which consists of the named function applied to the given 
#'  arguments;}
#'  \item{coefficients}{Estimated coefficients;}
#'  \item{fitted.values}{Fitted values of the estimated model;}
#'  \item{observed.values}{The observed values used in fitting arranged in the 
#'  same format as the fitted.values;}
#'  \item{residuals}{Deviance residuals;} 
#'  \item{x}{Vector of ages used in the fitting;} 
#'  \item{y}{Vector of years used in the fitting.} 
#' @seealso 
#' \code{\link{predict.Oeppen}}
#' \code{\link{plot.Oeppen}}
#' @references \insertAllCited{}
#' @author Marius D. Pascariu and Marie-Pier Bergeron-Boucher
#' @examples
#' # Example 1 ----------------------
#' # Data
#' x  <- 0:100
#' y  <- 1980:2016
#' dx <- HMD_male$dx$GBRTENW[paste(x), paste(y)]
#' 
#' # If data contains zero's we have to replace them with very small 
#' # values in order to avoid errors in fitting. replace.zeros() will do it.
#' dx <- replace.zeros(dx)
#' 
#' # Fit model
#' M <- model.Oeppen(data = dx, x = x, y = y)
#' M
#' 
#' summary(M)
#' coef(M)
#' 
#' # Plot observed and fitted values
#' plot(M, plotType = "observed")
#' plot(M, plotType = "fitted")
#' 
#' # Plot residuals
#' R <- residuals(M)
#' plot(R, plotType = "scatter")
#' plot(R, plotType = "colourmap")
#' plot(R, plotType = "signplot")
#' 
#' # Perform forecasts
#' P  <- predict(M, h = 16)
#' P
#' 
#' plot(P, plotType = "mean")
#' plot(P, plotType = "lower")
#' plot(P, plotType = "upper")
#' 
#' #' # Example 2 ----------------------
#' # One can specify manually the ARIMA order, a drift to be included or not, 
#' # and the jump choice of the first forecast year.
#' P2 <- predict(M, h = 20, 
#'               order = c(0,1,1), 
#'               include.drift = FALSE, 
#'               jumpchoice = "fit")
#' 
#' \dontrun{
#' # Example 3 ----------------------
#' # Compute life tables using forecast values using the MortalityLaws R package
#' library(MortalityLaws)
#' dx <- P$predicted.values
#' lt <- LifeTable(x = P$x, dx = dx)
#' }
#' @export
model.Oeppen <- function(data, 
                         x = NULL, 
                         y = NULL, 
                         verbose = TRUE, 
                         ...){
  
  input <- c(as.list(environment()))
  Oeppen.input.check(input)
  x <- x %||% 1:nrow(data)
  y <- y %||% 1:ncol(data)
  
  data <- convertFx(x, data, from = "dx", to = "dx", lx0 = 1)
  
  # Info
  modelLN <- "Compositional-Data Lee-Carter Mortality Model -- Oeppen"
  modelSN <- "Oeppen"
  modelF  <- "clr d[x,t] = a[x] + b[x]k[t]"
  info <- list(name = modelLN, name.short = modelSN, formula = modelF)
  
  # Estimate model parameters: a[x], b[x], k[t]
  dx  <- data %>% t %>% acomp %>% unclass # data close
  ax  <- geometricmeanCol(dx) # geometric mean
  ax  <- ax/sum(ax)
  cdx <- sweep(dx, 2, ax, "/") # remove ax
  cdx <- cdx/rowSums(cdx)
  ccdx <- clr(cdx) # Centered log ratio transform
  
  S  <- svd(ccdx) # Singular Value Decomposition of a Matrix
  kt <- S$d[1] * S$u[, 1]
  bx <- S$v[,1]
  cf <- list(ax = as.numeric(ax), bx = as.numeric(bx), kt = as.numeric(kt))
  
  # Variability
  var <- cumsum((S$d)^2/sum((S$d)^2))
  
  # Compute fitted values and devinace residuals based on the estimated model
  fv  <- clrInv(c(kt) %*% t(bx)) # Inverse clr
  fv  <- sweep(unclass(fv), 2, ax, FUN = "*")
  fdx <- unclass(t(fv/rowSums(fv)))
  odx <- apply(data, 2, FUN = function(x) x/sum(x)) # observed dx - same scale as fitted dx
  resid <- odx - fdx
  dimnames(fdx) = dimnames(resid) = dimnames(data) <- list(x, y)
  
  # Exit
  out <- list(input = input, 
              info = info, 
              call = match.call(), 
              coefficients = cf, 
              fitted.values = fdx, 
              observed.values = odx,
              residuals = resid, 
              x = x, 
              y = y)
  out <- structure(class = 'Oeppen', out)
  return(out)
}



#' Forecast the age-at-death distribution using the Oeppen model.
#' 
#' @param object An object of class \code{Oeppen}.
#' @param order A specification of the non-seasonal part of the ARIMA model: 
#'  the three components (p, d, q) are the AR order, the degree of differencing, 
#'  and the MA order. If \code{order = NULL}, the ARIMA order will be estimated 
#'  automatically using the KPPS algorithm.
#' @param include.drift Logical. Should the ARIMA model include a linear drift 
#' term? If \code{include.drift = NULL}, the model will be estimated 
#' automatically.
#' @param method ARIMA fitting method: maximum likelihood or minimize 
#' conditional sum-of-squares. Options to use: conditional-sum-of-squares 
#' (\code{"CSS-ML"}), maximum likelihood (\code{"ML"}) and \code{"CSS"}.
#' @param ... Additional arguments to be passed to \code{\link[forecast]{Arima}}
#' @inheritParams do.MortalityForecasts
#' @return The output is a list with the components:
#'  \item{call}{An unevaluated function call, that is, an unevaluated 
#'  expression which consists of the named function applied to the given 
#'  arguments;}
#'  \item{info}{Short details about the model;}
#'  \item{kt}{The extrapolated values of the \code{kt} parameters;}
#'  \item{kt.arima}{An object of class \code{ARIMA} that contains all the
#'  components of the fitted time series model used in \code{kt} prediction;} 
#'  \item{predicted.values}{A list containing the predicted values given by 
#'  the estimated model over the forecast horizon \code{h};}
#'  \item{conf.intervals}{Confidence intervals for the predicted values;}
#'  \item{x}{Vector of ages used in prediction;} 
#'  \item{y}{Vector of years used in prediction.}
#' @author Marius D. Pascariu and Marie-Pier Bergeron-Boucher
#' @details 
#' \insertNoCite{@See @oeppen2008 and @bergeron2017;textual}{MortalityForecast}
#' @references \insertAllCited{}
#' @seealso 
#' \code{\link{model.Oeppen}}
#' @examples # For examples go to ?model.Oeppen
#' @export
predict.Oeppen <- function(object,
                           h, 
                           order = c(0,1,0), 
                           include.drift = TRUE,
                           level = c(80, 95), 
                           jumpchoice = c("actual", "fit"), 
                           method = "ML", 
                           verbose = TRUE, 
                           ...){
  
  # Timeline
  bop <- max(object$y) + 1
  eop <- bop + h - 1
  fcy <- bop:eop
  
  # Identify the k[t] ARIMA order
  C <- coef(object)
  A <- find_arima(C$kt)
  
  # forecast kt; ax and bx are time independent.
  kt.arima <- forecast::Arima(y = C$kt, 
                              order = order %||% A$order, 
                              include.drift = include.drift %||% A$drift,
                              method = method)
  
  # Forecast k[t] using the time-series model
  tsf <- forecast(kt.arima, h = h + 1, level = level)  # time series forecast
  fkt <- data.frame(tsf$mean, tsf$lower, tsf$upper) # forecast kt
  Cnames <- c('mean', paste0('L', level), paste0('U', level))
  dimnames(fkt) <- list(c(0, fcy), Cnames)
  
  # Get forecast d[x] based on k[t] extrapolation 
  # Here we are also adjusting for the jump-off
  J <- match.arg(jumpchoice)
  d <- get_dx_values(object = object, 
                     jumpchoice = J,
                     y = fcy, 
                     kt = fkt, 
                     B.kt = NULL)
  
  # Exit
  out <- list(call = match.call(), 
              info = object$info,
              kt = fkt, 
              kt.arima = kt.arima, 
              predicted.values = d[[1]],
              conf.intervals = d[-1], 
              x = object$x, 
              y = fcy)
  out <- structure(class = 'predict.Oeppen', out)
  return(out)
}


#' #' Get d[x] values and confidence intervals based on k[t] forecast
#' @inheritParams get_mx_values
#' @param B.kt The forecast k[t] values of the benchmark model.
#' @keywords internal
get_dx_values <- function(object, jumpchoice, y, kt, B.kt = NULL) {
  
  C  <- coef(object)
  OV <- t(object$observed.values)
  N  <- nrow(OV)
  P  <- NULL
  
  for (i in 1:ncol(kt)) {
    
    # This is used only in OeppenC model, and it is basically the trend
    # given by the benchmark population # --------
    if (is.null(B.kt)) {
      B.cdx <- 1
      
    } else {
      B.bx  <- coef(object$benchmark)$bx
      B.cdx <- clrInv(c(B.kt[, i]) %*% t(B.bx))
    } # ------------------------------------------
    
    # Compute predicted d[x] values
    p <- clrInv(c(kt[, i]) %*% t(C$bx)) + B.cdx
    p <- sweep(unclass(p), 2, C$ax, FUN = "*") # predicted dx values
    p <- unclass(p/rowSums(p))
    
    # Adjust d[x] for jump-off if needed
    if (jumpchoice == 'actual') {
      J <- as.numeric(OV[N, ]/p[1, ])
      p <- sweep(p, 2, J, FUN = "*")
      p <- unclass(p/rowSums(p))
    }
    
    p <- p[-1, ]
    dimnames(p) <- list(y, colnames(OV))
    P[[i]] <- t(p)
    remove(p)
  }
  
  names(P) <- colnames(kt)
  return(P)
}



#' Validate input values
#' @param X A list with input arguments provided in \code{\link{model.Oeppen}} function
#' @keywords internal
Oeppen.input.check <- function(X) {
  # Validate the other arguments
  with(X, {
    if (any(data == 0)) {
      stop("'data' contains zero's. ",
           "Please replace the values equal to zero from input.", 
           call. = FALSE)
    }
    if (any(data < 0)) {
      stop("'data' contains negative values. ",
           "The compositions must always be positive or equal to zero.", 
           call. = FALSE)
    }
    if (any(is.na(data))) {
      stop("'data' contains NA values. ",
           "The function does not know how to deal with these yet.", 
           call. = FALSE)
    }
    if (any(is.na(data))) {
      stop("'data' contains NA values", call. = FALSE)
    }
    if (any(is.na(y))) {
      stop("'y' contains NA values", call. = FALSE)
    }
    if (any(is.na(x))) {
      stop("'x' contains NA values", call. = FALSE)
    }
    if ((!is.null(x)) & dim(data)[1] != length(x)) {
      stop("The length of 'x' is not equal to the number or rows in 'data'.", 
           call. = FALSE)
    }
    if ((!is.null(y)) & dim(data)[2] != length(y)) {
      stop("The length of 'y' is not equal to the number or columns in 'data'.", 
           call. = FALSE)
    }
  })
}


#' Extract Model Residuals
#' @param object A fitted mortality model
#' @inheritParams print_default
#' @seealso 
#' \code{\link{model.HyndmanUllah}}
#' \code{\link{model.LeeCarter}}
#' \code{\link{model.LiLee}}
#' \code{\link{model.MEM}}
#' \code{\link{model.MRW}}
#' \code{\link{model.Oeppen}}
#' \code{\link{model.OeppenC}}
#' @examples # See examples in the main functions linked above.
#' @export
residuals.Oeppen <- function(object, ...){
  residuals_default(object, ...)
}


#' @rdname print_default
#' @export
print.Oeppen <- function(x, ...) {
  print_default(x, ...)
}


#' Generic Summary
#' @inheritParams residuals.Oeppen
#' @keywords internal
#' @export
summary.Oeppen <- function(object, ...) {
  axbx <- data.frame(ax = object$coefficients$ax, 
                     bx = object$coefficients$bx,
                     row.names = object$x)
  kt <- data.frame(kt = object$coefficients$kt)
  out = structure(class = 'summary.Oeppen', 
                  list(A = axbx, K = kt, call = object$call, info = object$info,
                       y = object$y, x_ = object$x))
  return(out)
}


#' @rdname print_default
#' @export
print.summary.Oeppen <- function(x, ...){
  cat('\nFit  :', x$info$name)
  cat('\nModel:', x$info$formula)
  cat('\n\nCoefficients:\n')
  A <- head_tail(x$A, digits = 5, hlength = 6, tlength = 6)
  K <- head_tail(data.frame(. = '|', y = as.integer(x$y), kt = x$K),
                 digits = 5, hlength = 6, tlength = 6)
  print(data.frame(A, K))
  cat('\n')
}


#' @rdname print_default
#' @export
print.predict.Oeppen <- function(x, ...) {
  print_predict_default(x, ...)
  cat('k[t]-ARIMA method:', arima.string1(x$kt.arima, padding = TRUE))
  cat('\n')
}



