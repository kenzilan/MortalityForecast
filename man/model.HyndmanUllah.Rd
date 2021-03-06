% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_HyndmanUllah.R
\name{model.HyndmanUllah}
\alias{model.HyndmanUllah}
\title{The Functional Demographic Model}
\usage{
model.HyndmanUllah(data, x, y, order = 1, transform = TRUE, ...)
}
\arguments{
\item{data}{demogdata object. Output from read.demogdata.}

\item{x}{Numerical vector indicating the ages in input \code{data}. 
Optional. Default: \code{NULL}.}

\item{y}{Numerical vector indicating the years in input \code{data}. 
Optional. Default: \code{NULL}.}

\item{order}{Number of basis functions to fit.}

\item{transform}{If TRUE, the data are transformed with a Box-Cox transformation before the model is fitted.}

\item{...}{Extra arguments passed to \code{\link[ftsa]{ftsm}}.}
}
\value{
The output is a list with the components:
 \item{input}{List with arguments provided in input. Saved for convenience;}
 \item{info}{Short details about the model;}
 \item{call}{An unevaluated function call, that is, an unevaluated 
 expression which consists of the named function applied to the given 
 arguments;}
 \item{coefficients}{Estimated coefficients;}
 \item{fitted.values}{Fitted values of the estimated model;}
 \item{observed.values}{The observed values used in fitting arranged in the 
 same format as the fitted.values;}
 \item{residuals}{Deviance residuals;} 
 \item{x}{Vector of ages used in the fitting;} 
 \item{y}{Vector of years used in the fitting.}
}
\description{
The Functional Demographic Model
}
\details{
\insertNoCite{hyndman2007}{MortalityForecast}
}
\examples{
# Data
x  <- 0:89
y  <- 1985:2014
mx <- HMD_male$mx$GBRTENW[paste(x), paste(y)]

M <- model.HyndmanUllah(data = mx, x = x, y = y) # fit
P <- predict(M, h = 20)  # forecast
P
}
\references{
\insertAllCited{}
}
\seealso{
\code{\link{predict.HyndmanUllah}}
}
