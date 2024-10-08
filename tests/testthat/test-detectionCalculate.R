test_that("detectionCalculate input checks work", {
  testthat::skip_on_cran()
  #' @srrstats {G5.2,G5.2b} Tests the assure function input checks are behaving
  #'   as expected.
  # run joint model to do tests with
  model1 <- suppressWarnings({jointModel(data = gobyData,
                                         cov = c('Filter_time','Salinity'),
                                         n.chain = 1,n.iter.burn = 25,
                                         n.iter.sample = 75,multicore = FALSE)})

  model2 <- suppressWarnings({jointModel(data = greencrabData,family = 'negbin',
                                         n.chain = 1,n.iter.burn = 25,
                                         n.iter.sample = 75,multicore = FALSE)})

  #1. make sure model fit is of class stanfit
  expect_error(detectionCalculate(as.matrix(model1$model), mu = c(0.1, 0.5),
                                  cov.val = c(0,0)),
               "modelfit must be of class 'stanfit'.")

  #2. make sure ci is valid
  expect_error(detectionCalculate(model1$model, mu = c('0', 0.5),
                                  cov.val = c(0,0)),
               "mu must be a numeric vector of positive values")

  #3. make sure mu is a numeric vector of positive values
  expect_error(detectionCalculate(model1$model, mu = c(0, 0.5),
                                  cov.val = c(0,0)),
               "mu must be a numeric vector of positive values")

  #4. make sure probability is a numeric value between 0 and 1
  expect_error(detectionCalculate(model1$model, mu = c(0.1, 0.5),
                                  cov.val = c(0,0), probability = 1.05),
               "probability must be a numeric value between 0 and 1")

  #5. cov.val is numeric, if provided
  expect_error(detectionCalculate(model1$model, mu = c(0.1, 0.5),
                                  cov.val = c('0',0)),
               "cov.val must be a numeric vector")

  #6. Only include input cov.val if covariates are included in model
  expect_error(detectionCalculate(model2$model, mu = c(0.1, 0.5),
                                  cov.val = c(0,0)),
               paste0("cov.val must be NULL if the model does not ",
                      "contain site-level covariates."))

  #7. Input cov.val is the same length as the number of estimated covariates.
  expect_error(detectionCalculate(model1$model, mu = c(0.1, 0.5),
                                  cov.val = c(0,0,0)),
               paste0("cov.val must be of the same length as the number of ",
                      "non-intercept site-level coefficients in the model."))

  #8. If covariates are in model, cov.val must be provided
  expect_error(detectionCalculate(model1$model, mu = c(0.1, 0.5)),
               paste0("cov.val must be provided if the model contains ",
                      "site-level covariates."))

  #9. qPCR.N must be an integer
  expect_error(detectionCalculate(model1$model, mu = c(0.1, 0.5),
                                  cov.val = c(0,0), qPCR.N = 6.8),
               "qPCR.N should be an integer.")
})




