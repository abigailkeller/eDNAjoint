#' Calculate the survey effort necessary to detect species presence, given the species expected catch rate.
#'
#' This function calculates the median number of survey effort units to necessary detect species presence. Detecting species presence is defined as producing at least one true positive eDNA detection or catching at least one individual.
#' @srrstats {G1.4} Roxygen function documentation begins here
#' @export
#' @srrstats {G2.1a} Here are explicit documentation of vector input types
#' @param modelfit An object of class `stanfit`.
#' @param mu A numeric vector of species densities/capture rates. If multiple traditional gear types are represented in the model, mu is the catch rate of gear type 1.
#' @param cov.val A numeric vector indicating the values of site-level covariates to use for prediction. Default is 'None'.
#' @param probability A numeric value indicating the probability of detecting presence. The default is 0.9.
#' @param qPCR.N An integer indicating the number of qPCR replicates per eDNA sample. The default is 3.
#' @return A summary table of survey efforts necessary to detect species presence, given mu, for each survey type.
#'
#' @note  Before fitting the model, this function checks to ensure that the function is possible given the inputs. These checks include:
#' \itemize{
#' @srrstats {G2.8} Makes sure input of sub-function is of class 'stanfit' (i.e., output of jointModel())
#' \item  Input model fit is an object of class 'stanfit'.
#' \item  Input mu is a numeric vector.
#' @srrstats {G2.0a,G2.2} Explicit secondary documentation of any expectations on lengths of inputs
#' \item  Input probability is a univariate numeric value.
#' \item  If model fit contains alpha, cov.val must be provided.
#' \item  Input cov.val is numeric.
#' @srrstats {G2.0a} Explicit secondary documentation of any expectations on lengths of inputs
#' \item  Input cov.val is the same length as the number of estimated covariates.
#' \item  Input model fit has converged (i.e. no divergent transitions after warm-up).
#' }
#'
#' If any of these checks fail, the function returns an error message.
#'
#' @examples
#' \donttest{
#' # Ex. 1: Calculating necessary effort for detection with site-level covariates
#'
#' # Load data
#' data(gobyData)
#'
#' # Fit a model including 'Filter_time' and 'Salinity' site-level covariates
#' fit.cov = jointModel(data=gobyData, cov=c('Filter_time','Salinity'),
#'                      family='poisson', p10priors=c(1,20), q=FALSE)
#'
#' # Calculate at the mean covariate values (covariates are standardized, so mean=0)
#' detectionCalculate(fit.cov$model, mu = seq(from=0.1,to=1,by=0.1), cov.val = c(0,0), qPCR.N = 3)
#'
#' # Calculate mu_critical at habitat size 0.5 z-scores greater than the mean
#' detectionCalculate(fit.cov$model, mu = seq(from=0.1,to=1,by=0.1), cov.val = c(0,0.5), qPCR.N = 3)
#'
#' # Ex. 2: Calculating necessary effort for detection with multiple traditional gear types
#'
#' # Load data
#' data(greencrabData)
#'
#' # Fit a model with no site-level covariates
#' fit.q = jointModel(data=greencrabData, cov='None', family='negbin',
#'                    p10priors=c(1,20), q=TRUE)
#'
#' # Calculate
#' detectionCalculate(fit.q$model, mu = seq(from=0.1,to=1,by=0.1), cov.val = 'None', qPCR.N = 3)
#'
#' # Change probability of detecting presence to 0.95
#' detectionCalculate(fit.q$model, mu = 0.1, cov.val = 'None', probability = 0.95, qPCR.N = 3)
#' }
#'

detectionCalculate <- function(modelfit, mu, cov.val = 'None', probability=0.9, qPCR.N = 3){

  # input checks
  #' @srrstats {G2.1} Types of inputs are checked/asserted using this helper function
  detectionCalculate_input_checks(modelfit, mu, cov.val, probability, qPCR.N)

  if (!requireNamespace("rstan", quietly = TRUE)){
    stop ("The 'rstan' package is not installed.", call. = FALSE)
  }

  ## check to see if there are any divergent transitions
  #' @srrstats {BS4.5} Warning message if the input model fit has divergence transitions
  if(sum(lapply(rstan::get_sampler_params(modelfit,inc_warmup=FALSE),div_check)[[1]]) > 0){

    sum <- sum(lapply(rstan::get_sampler_params(modelfit,inc_warmup=FALSE),div_check)[[1]])

    warning <- paste0('Warning: There are ',sum,' divergent transitions in your model fit. ')
    print(warning)

  }


  ############################################
  #joint, no catchability, negbin, no sitecov#
  ############################################

  if('phi' %in% modelfit@model_pars && all(!c('q','alpha') %in% modelfit@model_pars)){
    #get median parameter estimates
    phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))
    beta <- stats::median(unlist(rstan::extract(modelfit,pars='beta')))

    ##
    #number of traditional survey effort
    ntrad_out <- vector(length = length(mu))

    for(i in 1:length(mu)){
      #number of traditional survey replicates
      ntrad <- seq(from = 0, to = 50000, by = 1)

      pr <- stats::pnbinom(q = 0, mu = mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
      #dnbinom: x = failed events; size = successful events
      prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

      #find value
      value <- match(min(prob[prob >= probability]), prob)
      ntrad_out[i] <- ntrad[value]
      }

    ##
    #number of qPCR reactions to get at least one true detection (among N replicates)
    ndna_out <- vector(length = length(mu))

    for(i in 1:length(mu)){
      #number of eDNA samples
      ndna <- seq(from = 0, to = 50000, by = 1)

      p11 <- mu[i]/(mu[i]+exp(beta))
      #P(at least one detection|mu) out of total bottles/PCR replicates
      prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

      #find value
      value <- match(min(prob[prob >= probability]), prob)
      ndna_out[i] <- ndna[value]
    }

    out <- cbind(mu,ntrad_out,ndna_out)
    colnames(out) <- c('mu','n_traditional','n_eDNA')

    ##########################################
    #joint, no catchability, pois, no sitecov#
    ##########################################
    } else if(all(!c('q','phi','alpha') %in% modelfit@model_pars)){
      #get median parameter estimates
      beta <- stats::median(unlist(rstan::extract(modelfit,pars='beta')))

      ##
      #number of traditional survey effort
      ntrad_out <- vector(length = length(mu))

      for(i in 1:length(mu)){
        #number of traditional survey replicates
        ntrad <- seq(from = 0, to = 50000, by = 1)

        pr <- stats::ppois(q = 0, lambda = mu[i]) #P(X = 0 | mu) in one traditional survey trial
        #dnbinom: x = failed events; size = successful events
        prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

        #find value
        value <- match(min(prob[prob >= probability]), prob)
        ntrad_out[i] <- ntrad[value]
      }

      ##
      #number of qPCR reactions to get at least one true detection (among N replicates)
      ndna_out <- vector(length = length(mu))

      for(i in 1:length(mu)){
        #number of eDNA samples
        ndna <- seq(from = 0, to = 50000, by = 1)

        p11 <- mu[i]/(mu[i]+exp(beta))
        #P(at least one detection|mu) out of total bottles/PCR replicates
        prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

        #find value
        value <- match(min(prob[prob >= probability]), prob)
        ndna_out[i] <- ndna[value]
      }

      out <- cbind(mu,ntrad_out,ndna_out)
      colnames(out) <- c('mu','n_traditional','n_eDNA')

      #########################################
      #joint, catchability, negbin, no sitecov#
      #########################################
    } else if(all(c('phi','q') %in% modelfit@model_pars) && !c('alpha') %in% modelfit@model_pars){
      #get median parameter estimates
      phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))
      beta <- stats::median(unlist(rstan::extract(modelfit,pars='beta')))

      #create empty q list
      q_list <- list()

      ##fill in q list
      for(i in 1:modelfit@par_dims$q){
       name <- paste('q',i,sep='')
        q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
      }
      q_list <- c(1,unlist(q_list))

      ##
      #number of traditional survey effort
      ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

      for(j in 1:length(q_list)){
        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::pnbinom(q = 0, mu = q_list[j]*mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i,j] <- ntrad[value]
        }
      }

      ##
      #number of qPCR reactions to get at least one true detection (among N replicates)
      ndna_out <- vector(length = length(mu))

      for(i in 1:length(mu)){
        #number of eDNA samples
        ndna <- seq(from = 0, to = 50000, by = 1)

        p11 <- mu[i]/(mu[i]+exp(beta))
        #P(at least one detection|mu) out of total bottles/PCR replicates
        prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

        #find value
        value <- match(min(prob[prob >= probability]), prob)
        ndna_out[i] <- ndna[value]
      }

      out <- cbind(mu,ntrad_out,ndna_out)
      #rename columns
      for(i in 1:modelfit@par_dims$q){
        trad_names <- paste('n_traditional_',i+1,sep='')
      }
      colnames(out) <- c('mu','n_traditional_1',trad_names,'n_eDNA')

      #######################################
      #joint, catchability, pois, no sitecov#
      #######################################
    } else if('q' %in% modelfit@model_pars && all(!c('phi','alpha') %in% modelfit@model_pars)){
      #get median parameter estimates
      beta <- stats::median(unlist(rstan::extract(modelfit,pars='beta')))

      #create empty q list
      q_list <- list()

      ##fill in q list
      for(i in 1:modelfit@par_dims$q){
        name <- paste('q',i,sep='')
        q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
      }
      q_list <- c(1,unlist(q_list))

      ##
      #number of traditional survey effort
      ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

      for(j in 1:length(q_list)){
        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::ppois(q = 0, lambda = q_list[j]*mu[i]) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i,j] <- ntrad[value]
        }
      }

      ##
      #number of qPCR reactions to get at least one true detection (among N replicates)
      ndna_out <- vector(length = length(mu))

      for(i in 1:length(mu)){
        #number of eDNA samples
        ndna <- seq(from = 0, to = 50000, by = 1)

        p11 <- mu[i]/(mu[i]+exp(beta))
        #P(at least one detection|mu) out of total bottles/PCR replicates
        prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

        #find value
        value <- match(min(prob[prob >= probability]), prob)
        ndna_out[i] <- ndna[value]
      }

      out <- cbind(mu,ntrad_out,ndna_out)
      #rename columns
      for(i in 1:modelfit@par_dims$q){
        trad_names <- paste('n_traditional_',i+1,sep='')
      }
      colnames(out) <- c('mu','n_traditional_1',trad_names,'n_eDNA')

      #########################################
      #joint, no catchability, negbin, sitecov#
      #########################################

      } else if(all(c('phi','alpha') %in% modelfit@model_pars) && !c('q') %in% modelfit@model_pars){
        #get median parameter estimates
        phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))
        alpha <- apply(rstan::extract(modelfit,pars='alpha')$alpha,2,'median')
        beta <- alpha %*% c(1,cov.val)

        ##
        #number of traditional survey effort
        ntrad_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::pnbinom(q = 0, mu = mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i] <- ntrad[value]
        }

        ##
        #number of qPCR reactions to get at least one true detection (among N replicates)
        ndna_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of eDNA samples
          ndna <- seq(from = 0, to = 50000, by = 1)

          p11 <- mu[i]/(mu[i]+exp(beta))
          #P(at least one detection|mu) out of total bottles/PCR replicates
          prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ndna_out[i] <- ndna[value]
        }

        out <- cbind(mu,ntrad_out,ndna_out)
        colnames(out) <- c('mu','n_traditional','n_eDNA')

        #######################################
        #joint, no catchability, pois, sitecov#
        #######################################
      } else if('alpha' %in% modelfit@model_pars && all(!c('q','phi') %in% modelfit@model_pars)){
        #get median parameter estimates
        alpha <- apply(rstan::extract(modelfit,pars='alpha')$alpha,2,'median')
        beta <- alpha %*% c(1,cov.val)


        ##
        #number of traditional survey effort
        ntrad_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::ppois(q = 0, lambda = mu[i]) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i] <- ntrad[value]
        }

        ##
        #number of qPCR reactions to get at least one true detection (among N replicates)
        ndna_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of eDNA samples
          ndna <- seq(from = 0, to = 50000, by = 1)

          p11 <- mu[i]/(mu[i]+exp(beta))
          #P(at least one detection|mu) out of total bottles/PCR replicates
          prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ndna_out[i] <- ndna[value]
        }

        out <- cbind(mu,ntrad_out,ndna_out)
        colnames(out) <- c('mu','n_traditional','n_eDNA')

        ######################################
        #joint, catchability, negbin, sitecov#
        ######################################
      } else if(all(c('phi','q','alpha') %in% modelfit@model_pars)){
        #get median parameter estimates
        phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))
        alpha <- apply(rstan::extract(modelfit,pars='alpha')$alpha,2,'median')
        beta <- alpha %*% c(1,cov.val)

        #create empty q list
        q_list <- list()

        ##fill in q list
        for(i in 1:modelfit@par_dims$q){
          name <- paste('q',i,sep='')
          q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
        }
        q_list <- c(1,unlist(q_list))

        ##
        #number of traditional survey effort
        ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

        for(j in 1:length(q_list)){
          for(i in 1:length(mu)){
            #number of traditional survey replicates
            ntrad <- seq(from = 0, to = 50000, by = 1)

            pr <- stats::pnbinom(q = 0, mu = q_list[j]*mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
            #dnbinom: x = failed events; size = successful events
            prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

            #find value
            value <- match(min(prob[prob >= probability]), prob)
            ntrad_out[i,j] <- ntrad[value]
          }
        }

        ##
        #number of qPCR reactions to get at least one true detection (among N replicates)
        ndna_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of eDNA samples
          ndna <- seq(from = 0, to = 50000, by = 1)

          p11 <- mu[i]/(mu[i]+exp(beta))
          #P(at least one detection|mu) out of total bottles/PCR replicates
          prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ndna_out[i] <- ndna[value]
        }

        out <- cbind(mu,ntrad_out,ndna_out)
        #rename columns
        for(i in 1:modelfit@par_dims$q){
          trad_names <- paste('n_traditional_',i+1,sep='')
        }
        colnames(out) <- c('mu','n_traditional_1',trad_names,'n_eDNA')

        #######################################
        #joint, catchability, pois, no sitecov#
        #######################################
      } else if(all(c('alpha','q') %in% modelfit@model_pars) && !c('phi') %in% modelfit@model_pars){
        #get median parameter estimates
        alpha <- apply(rstan::extract(modelfit,pars='alpha')$alpha,2,'median')
        beta <- alpha %*% c(1,cov.val)

        #create empty q list
        q_list <- list()

        ##fill in q list
        for(i in 1:modelfit@par_dims$q){
          name <- paste('q',i,sep='')
          q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
        }
        q_list <- c(1,unlist(q_list))

        ##
        #number of traditional survey effort
        ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

        for(j in 1:length(q_list)){
          for(i in 1:length(mu)){
            #number of traditional survey replicates
            ntrad <- seq(from = 0, to = 50000, by = 1)

            pr <- stats::ppois(q = 0, lambda = q_list[j]*mu[i]) #P(X = 0 | mu) in one traditional survey trial
            #dnbinom: x = failed events; size = successful events
            prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

            #find value
            value <- match(min(prob[prob >= probability]), prob)
            ntrad_out[i,j] <- ntrad[value]
          }
        }

        ##
        #number of qPCR reactions to get at least one true detection (among N replicates)
        ndna_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of eDNA samples
          ndna <- seq(from = 0, to = 50000, by = 1)

          p11 <- mu[i]/(mu[i]+exp(beta))
          #P(at least one detection|mu) out of total bottles/PCR replicates
          prob <- 1 - stats::dbinom(x = 0, size = ndna*qPCR.N, prob = p11)

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ndna_out[i] <- ndna[value]
        }

        out <- cbind(mu,ntrad_out,ndna_out)
        #rename columns
        for(i in 1:modelfit@par_dims$q){
          trad_names <- paste('n_traditional_',i+1,sep='')
        }
        colnames(out) <- c('mu','n_traditional_1',trad_names,'n_eDNA')

        ###############################
        #trad, no catchability, negbin#
        ###############################

      } else if(c('phi') %in% modelfit@model_pars && all(!c('q','p10') %in% modelfit@model_pars)){
        #get median parameter estimates
        phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))

        ##
        #number of traditional survey effort
        ntrad_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::pnbinom(q = 0, mu = mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i] <- ntrad[value]
        }

        out <- cbind(mu,ntrad_out)
        colnames(out) <- c('mu','n_traditional')

        #############################
        #trad, no catchability, pois#
        #############################
      } else if(all(!c('q','p10','phi') %in% modelfit@model_pars)){

        ##
        #number of traditional survey effort
        ntrad_out <- vector(length = length(mu))

        for(i in 1:length(mu)){
          #number of traditional survey replicates
          ntrad <- seq(from = 0, to = 50000, by = 1)

          pr <- stats::ppois(q = 0, lambda = mu[i]) #P(X = 0 | mu) in one traditional survey trial
          #dnbinom: x = failed events; size = successful events
          prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

          #find value
          value <- match(min(prob[prob >= probability]), prob)
          ntrad_out[i] <- ntrad[value]
        }

        out <- cbind(mu,ntrad_out)
        colnames(out) <- c('mu','n_traditional')

        ############################
        #trad, catchability, negbin#
        ############################
      } else if(all(c('phi','q') %in% modelfit@model_pars) && !c('p10') %in% modelfit@model_pars){
        #get median parameter estimates
        phi <- stats::median(unlist(rstan::extract(modelfit,pars='phi')))

        #create empty q list
        q_list <- list()

        ##fill in q list
        for(i in 1:modelfit@par_dims$q){
          name <- paste('q',i,sep='')
          q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
        }
        q_list <- c(1,unlist(q_list))

        ##
        #number of traditional survey effort
        ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

        for(j in 1:length(q_list)){
          for(i in 1:length(mu)){
            #number of traditional survey replicates
            ntrad <- seq(from = 0, to = 50000, by = 1)

            pr <- stats::pnbinom(q = 0, mu = q_list[j]*mu[i], size = phi) #P(X = 0 | mu) in one traditional survey trial
            #dnbinom: x = failed events; size = successful events
            prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

            #find value
            value <- match(min(prob[prob >= probability]), prob)
            ntrad_out[i,j] <- ntrad[value]
          }
        }

        out <- cbind(mu,ntrad_out)
        #rename columns
        for(i in 1:modelfit@par_dims$q){
          trad_names <- paste('n_traditional_',i+1,sep='')
        }
        colnames(out) <- c('mu','n_traditional_1',trad_names)

        ##########################
        #trad, catchability, pois#
        ##########################
      } else if(c('q') %in% modelfit@model_pars && all(!c('phi','p10') %in% modelfit@model_pars)){

        #create empty q list
        q_list <- list()

        ##fill in q list
        for(i in 1:modelfit@par_dims$q){
          name <- paste('q',i,sep='')
          q_list[[name]] <- stats::median(rstan::extract(modelfit,pars='q')$q[,i])
        }
        q_list <- c(1,unlist(q_list))

        ##
        #number of traditional survey effort
        ntrad_out <- matrix(NA,nrow = length(mu),ncol = length(q_list))

        for(j in 1:length(q_list)){
          for(i in 1:length(mu)){
            #number of traditional survey replicates
            ntrad <- seq(from = 0, to = 50000, by = 1)

            pr <- stats::ppois(q = 0, lambda = q_list[j]*mu[i]) #P(X = 0 | mu) in one traditional survey trial
            #dnbinom: x = failed events; size = successful events
            prob <- 1 - stats::dnbinom(x = 0, size = ntrad, prob = pr) #probability of catching >0 animals based on ntrad

            #find value
            value <- match(min(prob[prob >= probability]), prob)
            ntrad_out[i,j] <- ntrad[value]
          }
        }

        out <- cbind(mu,ntrad_out)
        #rename columns
        for(i in 1:modelfit@par_dims$q){
          trad_names <- paste('n_traditional_',i+1,sep='')
        }
        colnames(out) <- c('mu','n_traditional_1',trad_names)
      }

    return(out)
  }

#function to check for divergent transitions
div_check <- function(x){
  divergent <- sum(x[,'divergent__'])
  return(divergent)
}

# function for input checks
#' @srrstats {G5.2a} Pre-processing routines to check inputs have unique messages
detectionCalculate_input_checks <- function(modelfit, mu, cov.val, probability, qPCR.N){
  ## #1. make sure model fit is of class stanfit
  #' @srrstats {G2.8} Makes sure input of sub-function is of class 'stanfit' (i.e., output of jointModel())
  if(!is(modelfit,'stanfit')) {
    errMsg = "modelfit must be of class 'stanfit'."
    stop(errMsg)
  }

  ## #2. make sure mu is a numeric vector
  #' @srrstats {G5.8,G5.8b} Pre-processing routines to check for data of unsupported type
  if(!any(is.numeric(mu)) | any(mu <= 0)) {
    errMsg = "mu must be a numeric vector of positive values"
    stop(errMsg)
  }

  ## #3. make sure probability is a numeric value between 0 and 1
  #' @srrstats {G2.0,G2.2} Assertion on length of input, prohibit multivariate input to parameters expected to be univariate
  if(!is.numeric(probability) | length(probability)>1 | any(probability < 0) | any(probability > 1)) {
    errMsg = "probability must be a numeric value between 0 and 1"
    stop(errMsg)
  }

  ## #4. cov.val is numeric, if provided
  #' @srrstats {G5.8,G5.8b} Pre-processing routines to check for data of unsupported type
  if(all(cov.val != 'None') && !is.numeric(cov.val)) {
    errMsg = "cov.val must be a numeric vector"
    stop(errMsg)
  }

  ## #5. Only include input cov.val if covariates are included in model
  if(all(cov.val != 'None') && !c('alpha') %in% modelfit@model_pars) {
    errMsg = "cov.val must be 'None' if the model does not contain site-level covariates."
    stop(errMsg)
  }

  ## #6. Input cov.val is the same length as the number of estimated covariates.
  #' @srrstats {G2.0} Assertion on length of input
  if(all(cov.val != 'None') && length(cov.val)!=(modelfit@par_dims$alpha-1)) {
    errMsg = "cov.val must be of the same length as the number of non-intercept site-level coefficients in the model."
    stop(errMsg)
  }

  ## #7. If covariates are in model, cov.val must be provided
  if('alpha' %in% modelfit@model_pars && all(cov.val == 'None')) {
    errMsg = "cov.val must be provided if the model contains site-level covariates."
    stop(errMsg)
  }

  ## #8. qPCR.N must be an integer
  #' @srrstats {G5.8,G5.8b} Pre-processing routines to check for data of unsupported type
  if(qPCR.N %% 1 != 0) {
    errMsg = "qPCR.N should be an integer."
    stop(errMsg)
  }
}


