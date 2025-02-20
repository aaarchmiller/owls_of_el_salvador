#' # Richness model
#' 
#' Description: This program uses a Bayesian species richness model and data 
#' augmentation to analyze
#' species richness of each route and year. 
#' 
#' 


#' _____________________________________________________________________________
#' ## Write model
#' 
model.richness <- function(){
  # Priors for determining the probability of detection based on broadcast species
  beta.prebroad ~ dt(0, pow(2.5, -2), 1) #p(detection) before any broadcast
  beta.pacific ~  dt(0, pow(2.5, -2), 1)
  beta.mottled ~ dt(0, pow(2.5, -2), 1)
  beta.crested ~ dt(0, pow(2.5, -2), 1)
  beta.bw ~ dt(0, pow(2.5, -2), 1)
  beta.spectacled ~ dt(0, pow(2.5, -2), 1)
  beta.whiskered ~ dt(0, pow(2.5, -2), 1)
  beta.gbarred ~ dt(0, pow(2.5, -2), 1)
  beta.stygian ~ dt(0, pow(2.5, -2), 1)
  beta.ghorned ~ dt(0, pow(2.5, -2), 1)
  
  # Hyperpriors for psi
  lnrho.psi ~ dnorm(5,1)%_%T(0.01,10)
  rho.psi <- exp(lnrho.psi)
  
  
  for(hh in 1:n.route){
    
    # Prior for omega, which is prob(species membership)
    omega[hh] ~ dbeta(0.001, 1)
    
    
    for(tt in 1:n.year){
      

      
      #Hyperpriors for Psi ensure a flexible and uninformed prior
      logit.mu.psi[hh,tt] ~ dnorm(0, 0.2)
      mu.psi[hh,tt] <- exp(logit.mu.psi[hh,tt])/(1+exp(logit.mu.psi[hh,tt]))
      
      for(ss in 1:n.species.aug){
        #  Hyperpriors based off route/year random effects, shared mean but
        #    flexible to relate to each species' prob(occupancy) psi
        a.psi[hh,tt,ss] <- mu.psi[hh,tt]*rho.psi
        b.psi[hh,tt,ss] <- rho.psi-(mu.psi[hh,tt]*rho.psi)
        
        
        # Prior for Psi, which will vary by route (hh) and year (tt) and species (ss),
        # but based on shared mean probability of occupancy for each route/year (mu.psi)
        psi[hh,tt,ss] ~ dbeta(a.psi[hh,tt,ss], b.psi[hh,tt,ss])%_%T(0.0001,0.99)

        
        for(ii in 1:n.survey){ # 1 to 3 surveys per year
          for(jj in 1:10){ # 10 stations per route
            for(kk in 1:n.broadcast){ # before or after broadcast
              
              # Function that creates logistic equation for p(detection)
              
              # p = p(detection), which varies by route, year, survey, station, and 
              #       broadcast period (pre- or post-broadcast)
              p[hh,tt,ss,ii,jj,kk] <- exp(logit.p[hh,tt,ss,ii,jj,kk])/
                (1+exp(logit.p[hh,tt,ss,ii,jj,kk]))
              
              # Logistic regression equation
              logit.p[hh,tt,ss,ii,jj,kk] <- 
                beta.prebroad*ks.prebroad[hh,jj,kk]+
                beta.pacific*ks.pacific[hh,jj,kk]+
                beta.mottled*ks.mottled[hh,jj,kk]+
                beta.crested*ks.crested[hh,jj,kk]+
                beta.bw*ks.bw[hh,jj,kk]+
                beta.spectacled*ks.spectacled[hh,jj,kk]+
                beta.whiskered*ks.whiskered[hh,jj,kk]+
                beta.gbarred*ks.gbarred[hh,jj,kk]+
                beta.stygian*ks.stygian[hh,jj,kk]+
                beta.ghorned*ks.ghorned[hh,jj,kk]
              
            }
          }
        }
      }
    }
  } # end priors
  
  
  
  # Likelihood
  for(hh in 1:n.route){ # 6 routes
    

    for(ss in 1:n.species.aug){
      # Is each species present in that route's community?
      w[hh,ss] ~ dbern(omega[hh])
    }
    
    for(tt in 1:n.year){ # all years
      for(ss in 1:n.species.aug){ # all augmented species
        
        
        
        for(ii in 1:n.survey){ # 1 to 3 surveys per year
          
          # Occupancy by route and year and survey based on 
          #     psi, probability of occupancy for each route/year
          z[hh,tt,ss,ii] ~ dbern(psi[hh,tt,ss]*w[hh,ss]) 
          
          
          
          for(jj in 1:n.station){ # 10 stations per route
            
            
            for(kk in 1:n.broadcast){ # before or after broadcast
              # Detection by route, year, survey station, and broadcast period
              
              # Binary observations by route, year, survey, station, pre/post broadcast
              y[hh,tt,ss,ii,jj,kk] ~ 
                dbern(eff.p[hh,tt,ss,ii,jj,kk])
              
              # Effective p(detection), which depends on occupany (z) = 1 for 
              #    that route/year/survey/station
              eff.p[hh,tt,ss,ii,jj,kk] <- p[hh,tt,ss,ii,jj,kk]*z[hh,tt,ss,ii]
              
            }
          }
        }
      }
    }
  } # end likelihood
  
  # Derived quantities
  for(hh in 1:n.route){
    for(ss in 1:n.species.aug){
      # number of occupied years
      spp.occ[hh,ss] <- sum(z[hh,,ss,]) 
      
      # if each species exists by route
      species.present[hh,ss] <- ifelse(spp.occ[hh,ss]>0, 1, 0) 
    }
  }

  
  for(hh in 1:n.route){
    
    richness[hh] <- sum(w[hh,]) # number of species at each route
    
    for(tt in 1:n.year){
      for(ss in 1:n.species.aug){
        # If each species was present in each route/year
        occ.RtYrSpp[hh,tt,ss] <- max(z[hh,tt,ss,])
        
      }
      # Sum up if each species was present, to get richness estimates by route/year
      richness.RtYr[hh,tt] <- sum(occ.RtYrSpp[hh,tt,])
    }
  }
}



#' _____________________________________________________________________________
#' ### Footer
#' 
#' Session Info
devtools::session_info()
#' This document was "spun" with:
#' 
#' ezspin(file = "programs/b_richness_model_global.R", out_dir = "output", fig_dir = "figures", keep_md = F)
#' 