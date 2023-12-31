test_that("traditionalModel input checks work", {
  #1. input tags are valid, q = TRUE
  expect_error(traditionalModel(data=list(Count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c(1,2,1),c(1,2,NA))),q=TRUE),
               "Data should include 'count' and 'count.type'.")

  #2. input tags are valid, q = FALSE
  expect_error(traditionalModel(data=list(Count=rbind(c(4,1,1),c(1,1,NA)))),
               "Data should include 'count'.")

  #3. make sure dimensions of count and count.type are equal, if count.type is present
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c(1,2),c(1,2))),
                          q=TRUE),
               "Dimensions of count and count.type do not match.")

  #4. make sure all data is numeric -- if q == TRUE
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c('NA',2,2),c(1,2,2))),
                          q=TRUE),
               "Data should be numeric.")

  #5. make sure all data is numeric -- if q == FALSE
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,'NA')))),
               "Data should be numeric.")

  #6. make sure locations of NAs in count data match locations of NAs in count.type data
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c(NA,2,2),c(1,2,2))),
                                q=TRUE),
               "Empty data cells \\(NA\\) in count data should match empty data cells \\(NA\\) in count.type data.")

  #7. make sure family is either 'poisson', 'negbin', or 'gamma'
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA))),
                                family='normal'),
               "Invalid family. Options include 'poisson', 'negbin', or 'gamma'.")

  #8. the smallest count.type is 1
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c(0,1,2),c(1,2,NA))),
                                q=TRUE),
               "The first gear type should be referenced as 1 in count.type. Subsequent gear types should be referenced 2, 3, 4, etc.")

  #9. count are integers
  expect_error(traditionalModel(data=list(count=rbind(c(4.1,1,1),c(1,1,NA)),
                                          count.type=rbind(c(1,1,2),c(1,2,NA))),
                                q=TRUE, family = 'negbin'),
               "All values in count should be integers.")


  #10. count.type are integers
  expect_error(traditionalModel(data=list(count=rbind(c(4,1,1),c(1,1,NA)),
                                          count.type=rbind(c(1.1,1,2),c(1,2,NA))),
                                q=TRUE),
               "All values in count.type should be integers.")
})

test_that("traditional_catchability_pois works", {

  test <- list(count=greencrabData$count[1:10,],
               count.type=greencrabData$count.type[1:10,])

  out <- traditionalModel(data=test,q=TRUE,n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})

test_that("traditional_catchability_negbin works", {

  test <- list(count=greencrabData$count[1:10,],
               count.type=greencrabData$count.type[1:10,])

  out <- traditionalModel(data=test,q=TRUE,family='negbin',n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})

test_that("traditional_catchability_gamma works", {

  test <- list(count=greencrabData$count[1:10,],
               count.type=greencrabData$count.type[1:10,])

  out <- traditionalModel(data=test,q=TRUE,family='gamma',n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})

test_that("traditional_pois works", {

  test <- list(count=greencrabData$count[1:10,])

  out <- traditionalModel(data=test,n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})

test_that("traditional_negbin works", {

  test <- list(count=greencrabData$count[1:10,])

  out <- traditionalModel(data=test,family='negbin',n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})

test_that("traditional_gamma works", {

  test <- list(count=greencrabData$count[1:10,])

  out <- traditionalModel(data=test,family='gamma',n.chain=1,n.iter.burn=500,
                          n.iter.sample=500)
  expect_type(sum(colMeans(rstan::extract(out,par='log_lik')$log_lik)), 'double')

})
