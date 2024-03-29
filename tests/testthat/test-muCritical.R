test_that("muCritical input checks work", {
  #' @srrstats {G5.2,G5.2b} Tests the assure function input checks are
  #' behaving as expected.

  # run joint model to do tests with
  model1 <- jointModel(data=gobyData, cov=c('Filter_time','Salinity'),
                       multicore=FALSE,
                       n.chain=2,n.iter.burn=50,n.iter.sample=200)

  model2 <- traditionalModel(data=gobyData,multicore=FALSE,
                             n.chain=2,n.iter.burn=50,n.iter.sample=200)

  model3 <- jointModel(data=greencrabData,family='negbin',multicore=FALSE,
                       n.chain=2,n.iter.burn=50,n.iter.sample=200)

  #1. make sure model fit is of class stanfit
  expect_error(muCritical(as.matrix(model1$model), cov.val = c(0,0)),
               "modelfit must be of class 'stanfit'.")

  #2. make sure ci is valid
  expect_error(muCritical(model1$model, ci = 1, cov.val = c(0,0)),
               "ci must be a numeric value >0 and <1.")

  #3. make sure model fit contains p10 parameter
  expect_error(muCritical(model2$model),
               "modelfit must contain 'p10' parameter.")

  #4. if modelfit contains alpha, cov.val must be provided
  expect_error(muCritical(model1$model),
               paste0("If modelfit contains site-level covariates, values ",
                      "must be provided for cov.val"))

  #5. cov.val is numeric, if provided
  expect_error(muCritical(model1$model, cov.val=c(TRUE,TRUE)),
               "cov.val must be a numeric vector")

  #6. Only include input cov.val if covariates are included in model
  expect_error(muCritical(model3$model, cov.val=c(0,0)),
               paste0("cov.val must be 'None' if the model does not ",
                      "contain site-level covariates."))

  #7. Only include input cov.val if covariates are included in model
  expect_error(muCritical(model1$model, cov.val=c(0,0,0)),
               paste0("cov.val must be of the same length as the number of ",
                      "non-intercept site-level coefficients in the model."))

})


