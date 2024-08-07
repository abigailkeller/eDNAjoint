% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/muCritical.R
\name{muCritical}
\alias{muCritical}
\title{Calculate mu_critical}
\usage{
muCritical(modelfit, cov.val = NULL, ci = 0.9)
}
\arguments{
\item{modelfit}{An object of class \code{stanfit}}

\item{cov.val}{A numeric vector indicating the values of site-level
covariates to use for prediction. Default is NULL.}

\item{ci}{Credible interval calculated using highest density interval (HDI).
Default is 0.9 (i.e., 90\% credible interval).}
}
\value{
A list with median mu_critical and lower and upper bounds on the
credible interval. If multiple gear types are used, a table of mu_critical
and lower and upper credible interval bounds is returned with one column
for each gear type.
}
\description{
This function uses the full posterior distributions of parameters estimated
by \code{jointModel()} to calculate mu_critical, or the expected catch rate at
which the probabilities of a false positive eDNA detection and true positive
eDNA detection are equal. See more examples in the
\href{https://bookdown.org/abigailkeller/eDNAjoint_vignette/}{Package
Vignette}.
}
\note{
Before fitting the model, this function checks to ensure that the
function is possible given the inputs. These checks include:
\itemize{
\item  Input model fit is an object of class 'stanfit'.
\item  Input credible interval is a univariate numeric value greater than 0
and less than 1.
\item  Input model fit contains p10 parameter.
\item  If model fit contains alpha, cov.val must be provided.
\item  Input cov.val is numeric.
\item  Input cov.val is the same length as the number of estimated
covariates.
\item  Input model fit has converged (i.e. no divergent transitions after
warm-up).
}

If any of these checks fail, the function returns an error message.
}
\examples{
\donttest{
# Ex. 1: Calculating mu_critical with site-level covariates

# Load data
data(gobyData)

# Fit a model including 'Filter_time' and 'Salinity' site-level covariates
fit.cov <- jointModel(data = gobyData, cov = c('Filter_time','Salinity'),
                      family = "poisson", p10priors = c(1,20), q = FALSE,
                      multicore = FALSE)

# Calculate mu_critical at the mean covariate values (covariates are
# standardized, so mean = 0)
muCritical(fit.cov$model, cov.val = c(0,0), ci = 0.9)

# Calculate mu_critical at habitat size 0.5 z-scores greater than the mean
muCritical(fit.cov$model, cov.val = c(0,0.5), ci = 0.9)

# Ex. 2: Calculating mu_critical with multiple traditional gear types

# Load data
data(greencrabData)

# Fit a model with no site-level covariates
fit.q <- jointModel(data = greencrabData, cov = NULL, family = "negbin",
                    p10priors = c(1,20), q = TRUE, multicore = FALSE)

# Calculate mu_critical
muCritical(fit.q$model, cov.val = NULL, ci = 0.9)
}

}
