data{/////////////////////////////////////////////////////////////////////
    int<lower=1> S;    // number of paired qPCR samples
    int<lower=0> S_dna;    // number of unpaired qPCR samples
    int<lower=1> C;    // number of traditional samples
    array[S] int<lower=1> L;   // index of locations for qPCR samples w/traditional pair
    array[S_dna] int<lower=1> L_dna;   // index of locations for unpaired qPCR samples
    array[C] int<lower=1> R;   // index of locations for traditional samples
    int<lower=0> Nloc_dna;   // number of locations with unpaired dna samples
    int<lower=1> Nloc_trad;   // number of locations with paired samples
    array[Nloc_trad] int<lower=0> trad_ind;   // index of traditional samples
    array[Nloc_dna] int<lower=0> dna_ind;   // index of unpaired dna samples
    array[C] int<lower=0> E;   // number of animals in sample C
    array[S] int<lower=1> N;   // number of qPCR replicates per site
    array[S] int<lower=0> K; // number of qPCR detections among these replicates
    array[S_dna] int<lower=1> N_dna;   // number of qPCR replicates per site of unpaired samples
    array[S_dna] int<lower=0> K_dna; // number of qPCR detections among these replicates of unpaired samples
    array[2] real p10priors; // priors for normal distrib on p10
    array[2] real phipriors; // priors for gamma distrib on phi

}

parameters{/////////////////////////////////////////////////////////////////////
    array[Nloc_trad] real<lower=0> mu_trad;  // expected catch at each site for sites with traditional samples
    real<lower=0> beta; // scaling coefficient in saturation function
    real<upper=0> log_p10;  // p10, false-positive rate.
    array[Nloc_dna] real<lower=0, upper = 1> p_dna;   // total detection probability
    real<lower=0> phi;  // dispersion parameter
}

transformed parameters{/////////////////////////////////////////////////////////////////////
  array[Nloc_trad] real<lower=0, upper = 1> p11_trad; // true-positive detection probability
  array[Nloc_trad] real<lower=0, upper = 1> p_trad;   // total detection probability
  
  for (i in 1:Nloc_trad){
    p11_trad[i] = mu_trad[i] / (mu_trad[i] + exp(beta)); // Eq. 1.2
    p_trad[i] = p11_trad[i] + exp(log_p10); // Eq. 1.3
  }
}

model{/////////////////////////////////////////////////////////////////////


    for(j in 1:C){
      E[j] ~ neg_binomial_2(mu_trad[R[j]], phi); // Eq. 1.1
    }

    for (i in 1:S){
        K[i] ~ binomial(N[i], p_trad[L[i]]); // Eq. 1.4
    }
    
    if(Nloc_dna > 0)
       for (i in 1:S_dna){
           K_dna[i] ~ binomial(N_dna[i], p_dna[L_dna[i]]); // Eq. 1.4
       }


  //priors
  log_p10 ~ normal(p10priors[1], p10priors[2]); // p10 prior
  beta ~ normal(0,10);
  phi ~ gamma(phipriors[1], phipriors[2]); // phi prior

}

generated quantities{
  vector[C+S+S_dna] log_lik;
  real p10;
  array[Nloc_dna+Nloc_trad] real<lower=0> mu;  // expected catch at each site
  array[Nloc_dna] real<lower=0, upper = 1> p11_dna; // true-positive detection probability
  
  p10 = exp(log_p10);
  
  for(i in 1:Nloc_trad){
    mu[trad_ind[i]] = mu_trad[i];
  }
  
  if(Nloc_dna > 0)
     for (i in 1:Nloc_dna){
       p11_dna[i] = p_dna[i] - p10;
       mu[dna_ind[i]] = p11_dna[i]*exp(beta)/(1-p11_dna[i]);
     }

  for(j in 1:C){
    log_lik[j] = neg_binomial_2_lpmf(E[j] | mu_trad[R[j]], phi); //store log likelihood of traditional data given model
  }

  for(i in 1:S){
    log_lik[C+i] = binomial_lpmf(K[i] | N[i], p_trad[L[i]]); //store log likelihood of eDNA data given model
  }
  
  if(Nloc_dna > 0)
     for(i in 1:S_dna){
       log_lik[C+S+i] = binomial_lpmf(K_dna[i] | N_dna[i], p_dna[L_dna[i]]); //store log likelihood of eDNA data given model
     }

}

