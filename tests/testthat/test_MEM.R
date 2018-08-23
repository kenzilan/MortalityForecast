remove(list = ls())
library(MortalityForecast)

x  <- 0:110
y  <- 1985:2014
dx <- MortalityForecast.data$dx[paste(x), paste(y)]
M  <- MEM(data = dx, n = 6)
P1 <- predict(M, h = 16, x.h = 0:110, jumpchoice = 'fit')
P2 <- predict(M, h = 16, x.h = 0:130, jumpchoice = 'actual')


M$fitted.values >= 0 


test_that("Test for positive densities.", {
  expect_true(all(is.na(M$fitted.values[,1])))
  expect_true(all(M$fitted.values[,-1] >= 0))
  expect_true(all(P1$predicted.values >= 0))
  expect_true(all(P2$predicted.values >= 0))
})


test_that("Test that MEM plots are produced.", {
  res <- resid(M)
  expect_error(plot(res, plotType = 'scatterxxx'))
  expect_false(is.null(plot(res)))
  expect_false(is.null(plot(res, plotType = 'scatter')))
  expect_false(is.null(plot(res, plotType = 'colourmap')))
  expect_false(is.null(plot(res, plotType = 'signplot')))
  expect_false(is.null(plot(M, plotType = 'observed')))
  expect_false(is.null(plot(M, plotType = 'fitted')))
  expect_false(is.null(plot(P1)))
  expect_false(is.null(plot(P1, plotType = "upper")))
  expect_false(is.null(plot(P1, plotType = "lower")))
})
