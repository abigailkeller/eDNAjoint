data{/////////////////////////////////////////////////////////////////////
    int<lower=1> S;    // number of qPCR samples
    int<lower=1> C;    // number of traditional samples
    array[S] int<lower=1> L;   // index of locations for qPCR samples
    array[C] int<lower=1> R;   // index of locations for traditional samples
    int<lower=1> Nloc;   // number of locations
    array[C] int<lower=0> E;   // number of animals in sample C
    array[S] int<lower=1> N;   // number of qPCR replicates per site
    array[S] int<lower=0> K; // number of qPCR detections among these replicates
    array[2] real p10priors; // priors for normal distrib on p10
    int<lower=0> nsitecov;  // number of site-level covariates
    matrix[Nloc,nsitecov] mat_site;  // matrix of site-level covariates
    int<lower = 0, upper = 1> include_phi; // binary indicator of negbinomial

}

parameters{/////////////////////////////////////////////////////////////////////
    array[Nloc] real<lower=0> mu;  // expected catch at each site
    real<upper=0> log_p10;  // p10, false-positive rate.
    vector[nsitecov] alpha; // site-level beta covariates
    vector<lower=0>[include_phi ? 1 : 0] phi;  // dispersion parameter, if include_phi = 1
}

transformed parameters{/////////////////////////////////////////////////////////////////////
  array[Nloc] real<lower=0, upper = 1> p11; // true-positive detection probability
  array[Nloc]real<lower=0, upper = 1> p;   // total detection probability

  for (i in 1:Nloc){
    p11[i] = mu[i] / (mu[i] + exp(dot_product(mat_site[i],alpha))); // Eq. 1.2
    p[i] = p11[i] + exp(log_p10); // Eq. 1.3
  }
}

model{/////////////////////////////////////////////////////////////////////


    if (include_phi == 1)
       for (j in 1:C){
        E[j] ~ poisson(mu[R[j]]); // Eq. 1.1
       }
    else
       for (j in 1:C){
        E[j] ~ neg_binomial_2(mu[R[j]], phi); // Eq. 1.1
       }

    for (i in 1:S){
        K[i] ~ binomial(N[i], p[L[i]]); // Eq. 1.4
    }


  //priors
  log_p10 ~ normal(p10priors[1], p10priors[2]); // p10 prior
  alpha ~ normal(0,10); // sitecov shrinkage priors

}

generated quantities{
  vector[C+S] log_lik;
  vector[Nloc] beta;
  real p10;

  p10 = exp(log_p10);

  for (i in 1:Nloc){
    beta[i] = dot_product(mat_site[i],alpha);
  }

    if (include_phi == 1)
       for (j in 1:C){
        log_lik[j] = poisson_lpmf(E[j] | mu[R[j]]); //store log likelihood of traditional data given model
       }
    else
       for (j in 1:C){
        log_lik[j] = neg_binomial_2_lpmf(E[j] | mu[R[j]], phi); //store log likelihood of traditional data given model
       }

      for(i in 1:S){
          log_lik[C+i] = binomial_lpmf(K[i] | N[i], p[L[i]]); //store log likelihood of eDNA data given model
      }

}
