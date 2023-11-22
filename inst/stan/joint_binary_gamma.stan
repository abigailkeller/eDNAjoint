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

}

parameters{/////////////////////////////////////////////////////////////////////
    array[Nloc] real<lower=0> alpha_gamma;  // alpha param for gamma distribution
    array[Nloc] real <lower=0> beta_gamma;  // beta param for gamma distribution
    real<lower=0> beta; // scaling coefficient in saturation function
    real<upper=0> log_p10;  // p10, false-positive rate.
}

transformed parameters{/////////////////////////////////////////////////////////////////////
  array[Nloc] real<lower=0> mu;  // expected catch at each site
  array[Nloc] real<lower=0, upper = 1> p11; // true-positive detection probability
  array[Nloc]real<lower=0, upper = 1> p;   // total detection probability
  array[C] real<lower=0> E_trans;  //

  for (i in 1:Nloc){
    mu[i] = alpha_gamma[i]/beta_gamma[i];
    p11[i] = mu[i] / (mu[i] + exp(beta)); // Eq. 1.2
    p[i] = p11[i] + exp(log_p10); // Eq. 1.3
  }

  for(j in 1:C){
      E_trans[j] = E[j] + 0.0000000000001;
    }

}

model{/////////////////////////////////////////////////////////////////////


    for(j in 1:C){

      E_trans[j] ~ gamma(alpha_gamma[R[j]],beta_gamma[R[j]]); // Eq. 1.1
    }

    for (i in 1:S){
        K[i] ~ binomial(N[i], p[L[i]]); // Eq. 1.4
    }


  //priors
  log_p10 ~ normal(p10priors[1], p10priors[2]); // p10 prior
  beta ~ normal(0,10); // beta shrinkage priors
  beta_gamma ~ gamma(0.25,0.25);
  alpha_gamma ~ gamma(0.25,0.25);

}

generated quantities{
  vector[C+S] log_lik;
  real p10;

  p10 = exp(log_p10);

    for(j in 1:C){
          log_lik[j] = gamma_lpdf(E_trans[j] | alpha_gamma[R[j]], beta_gamma[R[j]]); //store log likelihood of traditional data given model
      }

      for(i in 1:S){
          log_lik[C+i] = binomial_lpmf(K[i] | N[i], p[L[i]]); //store log likelihood of eDNA data given model
      }

}

