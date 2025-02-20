#' ### Create Broadcast arrays
ks <-  array(0, dim = c(n.route,n.station, n.broadcast))
ks.prebroad <- ks.mottled <- ks.pacific <- ks.crested <- ks.bw <- ks.spectacled <-
  ks.whiskered <- ks.gbarred <- ks.stygian <- ks.ghorned <- ks

broadcast.array <- array(c(
  rep(c("pacific", "mottled", "crested", "bw", "spectacled"),4), # routes EI1/EI2
  rep(c("whiskered", "mottled", "gbarred", "stygian", "ghorned"),2), # routes M1/M2
  rep(c("pacific", "mottled", "crested", "bw", "spectacled"),4)), # routes N1/N2
  dim = c(n.station, n.route))
broadcast.array

for(hh in 1:n.route){
  for(jj in 1:n.station){
    ks.prebroad[hh,jj,1] <- 1
    ks.prebroad[hh,jj,2] <- 0
    
    if(broadcast.array[jj,hh] == "pacific"){
      ks.pacific[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "mottled"){
      ks.mottled[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "crested"){
      ks.crested[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "bw"){
      ks.bw[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "spectacled"){
      ks.spectacled[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "whiskered"){
      ks.whiskered[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "gbarred"){
      ks.gbarred[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "stygian"){
      ks.stygian[hh,jj,2] <- 1
    }else if(broadcast.array[jj,hh] == "ghorned"){
      ks.ghorned[hh,jj,2] <- 1
    }
  }
}

model.occ <- function(){
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
  
  
  
  for(hh in 1:n.route){
    for(tt in 1:n.year){
      #Hyperpriors for Psi ensure a flexible and uninformed prior
      mu.psi[hh,tt] ~ dunif(0.01,0.99)
      lnrho.psi[hh,tt] ~ dnorm(5,1)%_%T(0.01,10)
      rho.psi[hh,tt] <- exp(lnrho.psi[hh,tt])
      a.psi[hh,tt] <- mu.psi[hh,tt]*rho.psi[hh,tt]
      b.psi[hh,tt] <- rho.psi[hh,tt]-(mu.psi[hh,tt]*rho.psi[hh,tt])
      
      
      # Prior for Psi, which will vary by route (hh) and year (tt)
      psi[hh,tt] ~ dbeta(a.psi[hh,tt], b.psi[hh,tt])%_%T(0.0001,0.99)
      
      
      for(ii in 1:n.survey){ # 1 to 3 surveys per year
        for(jj in 1:10){ # 10 stations per route
          for(kk in 1:n.broadcast){ # before or after broadcast
            
            # Function that creates logistic equation for p(detection)
            
            # p = p(detection), which varies by route, year, survey, station, and 
            #       broadcast period (pre- or post-broadcast)
            p[hh,tt,ii,jj,kk] <- exp(logit.p[hh,tt,ii,jj,kk])/
              (1+exp(logit.p[hh,tt,ii,jj,kk]))
            
            # Logistic regression equation
            logit.p[hh,tt,ii,jj,kk] <- 
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
  
  
  
  # Likelihood
  for(hh in 1:n.route){ # 6 routes
    for(tt in 1:n.year){ # all years
      for(ii in 1:n.survey){ # 1 to 3 surveys per year
        for(jj in 1:n.station){ # 10 stations per route
          # Occupancy by route and year and survey and station based on 
          #     psi, probability of occupancy for each route/year
          z[hh,tt,ii,jj] ~ dbern(psi[hh,tt]) 
          
          for(kk in 1:n.broadcast){ # before or after broadcast
            # Detection by route, year, survey station, and broadcast period
            
            # Binary observations by route, year, survey, station, pre/post broadcast
            y[hh,tt,ii,jj,kk] ~ 
              dbern(eff.p[hh,tt,ii,jj,kk])
            
            # Effective p(detection), which depends on occupany (z) = 1 for 
            #    that route/year/survey/station
            eff.p[hh,tt,ii,jj,kk] <- p[hh,tt,ii,jj,kk]*z[hh,tt,ii,jj]
            
          }
        }
      }
    }
  }
}

ferpy.jagsout <- jags(data = ferpy.jag.data, 
                      inits = function(){list(z = z.init)}, 
                      parameters.to.save = c("psi",
                                             "beta.prebroad",
                                             "beta.pacific",
                                             "beta.mottled",
                                             "beta.crested",
                                             "beta.bw",
                                             "beta.spectacled",
                                             "beta.whiskered",
                                             "beta.gbarred",
                                             "beta.stygian",
                                             "beta.ghorned"), 
                      model.file = model.occ, 
                      n.chains = 3,
                      n.iter = 1000,
                      n.burnin = 100,
                      n.thin = 1)












































library(readxl)
remove(list = ls())
set.seed(2583722)

#' _____________________________________________________________________________
#' ## Load Data
#' 
#' 
#' 



#' _____________________________________________________________________________
#' ## Create tables for Ys and Broad Cast species covariates
#' 
#' 
#' Create an array of Ys (detections/non-detections) for each of the **possible**
#' surveys
#' 
#' Specifically: 6 routes (hh), 10 stations (jj), up to 3 surveys per year (ii), 
#' 11 total years (tt)
#' and 2 broadcast times (kk)
#' 
#' 
#' There will be 198 total matrices, each with 10 rows (j, stations) and 2 columns 
#' (k, before or after broadcast)
#' 



















# _____________________________________                                           old code below


#' Create matrices for covariate of broadcast species (shared intercept)
#'
#' 
(route.Names <- unique(tab.route$Route_ID))
(broadcast.species <- unique(tab.stations$Broadcast_Species))
(broadcast.species.index <- 1:length(broadcast.species))
ks.index.numb <- ks
for(hh in 1:length(route.Names)){
  
  for(ht in 1:length(grep(pattern = route.Names[hh], names(ks)))){
    
    for(jj in 1:10){ # across all 10 stations per route
      
      # Find all the tables in the ks list with correct Route and fill in intercept
      ks[[grep(pattern = route.Names[hh], names(ks))[ht]]][jj,1] <- 0 #intercept pre-broadcast
      ks.index.numb[[grep(pattern = route.Names[hh], 
                          names(ks.index.numb))[ht]]][jj,1] <- 0 #intercept pre-broadcast
      
      # Find all the tables in the ks list with correct Route and fill in intercept
      ks[[grep(pattern = route.Names[hh], names(ks))[ht]]][jj,2] <- unique(
        tab.stations$Broadcast_Species[tab.stations$Station == paste0(route.Names[hh],".",jj)]
      )
      ks.index.numb[[grep(pattern = route.Names[hh], names(ks))[ht]]][jj,2] <- 
        broadcast.species.index[broadcast.species == ks[[grep(pattern = route.Names[hh], names(ks))[ht]]][jj,2]]
      
    }
    
  }
  
}








#' ## Prepare support data for saving
#' 
#' _____________________________________________________________________________


#' Create a lookup table to link the route.year.survey 
#' dataset of Ys with a numerical index 1:198

lookup.hhttii.names <- names(ys)
lookup.hhttii.numb <- 1:length(lookup.hhttii.names)
lookup.hhttii.array <- array(NA, dim = c(n.route, n.year, n.survey))

for(ii in 1:n.survey){
  for(hh in 1:n.route){
    for(tt in 1:n.year){
      
      temp.record <- 
        lookup.hhttii.numb[
          lookup.hhttii.names == paste0(route.names[hh],".",year.names[tt],".",ii)]
      
      lookup.hhttii.array[hh,tt,ii] <- temp.record
      
    }
  }
}
lookup.hhttii.array

#' Turn ks into arrays
ks.array <- array(unlist(ks), dim = c(10, 2, length(lookup.hhttii.names)))
ks.array.index <- array(as.numeric(unlist(ks.index.numb)), 
                        dim = c(10, 2, length(lookup.hhttii.names)))

#' Convert ks into a series of 10 model matrices
#' 
#' For example means parameterization, w/ 1s for Pacific screech owl in one matrix, etc
#' 
#' Pre-broadcast
ks.prebroad <- array(as.numeric(rep(c(1,0), each = 10)), 
                     dim = c(10,2, length(lookup.hhttii.names)))
ks.prebroad[,,1]
#' 
ks.pacific.list <- 
  rapply(ks, function(x) ifelse(x == "Pacific Screech Owl", 1, 0), how = "replace")
ks.pacific <- array(as.numeric(unlist(ks.pacific.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))

ks.mottled.list <- 
  rapply(ks, function(x) ifelse(x == "Mottled Owl", 1, 0), how = "replace")
ks.mottled <- array(as.numeric(unlist(ks.mottled.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))

ks.crested.list <- 
  rapply(ks, function(x) ifelse(x == "Crested Owl", 1, 0), how = "replace")
ks.crested <- array(as.numeric(unlist(ks.crested.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))

ks.bw.list <- 
  rapply(ks, function(x) ifelse(x == "Black and White Owl", 1, 0), how = "replace")
ks.bw <- array(as.numeric(unlist(ks.bw.list)), 
               dim = c(10, 2, length(lookup.hhttii.names)))

ks.spectacled.list <- 
  rapply(ks, function(x) ifelse(x == "Spectacled Owl", 1, 0), how = "replace")
ks.spectacled <- array(as.numeric(unlist(ks.spectacled.list)), 
                       dim = c(10, 2, length(lookup.hhttii.names)))

ks.whiskered.list <- 
  rapply(ks, function(x) ifelse(x == "Whiskered", 1, 0), how = "replace")
ks.whiskered <- array(as.numeric(unlist(ks.whiskered.list)), 
                      dim = c(10, 2, length(lookup.hhttii.names)))

ks.gbarred.list <- 
  rapply(ks, function(x) ifelse(x == "Guat. Barred Owl", 1, 0), how = "replace")
ks.gbarred <- array(as.numeric(unlist(ks.gbarred.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))

ks.stygian.list <- 
  rapply(ks, function(x) ifelse(x == "Stygian Owl", 1, 0), how = "replace")
ks.stygian <- array(as.numeric(unlist(ks.stygian.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))

ks.ghorned.list <- 
  rapply(ks, function(x) ifelse(x == "Great Horned Owl", 1, 0), how = "replace")
ks.ghorned <- array(as.numeric(unlist(ks.ghorned.list)), 
                    dim = c(10, 2, length(lookup.hhttii.names)))



#' All levels of k
#' 
k.names <- unique(as.character(ks.array[,2,]))
ks.levels <- c(0, 1:length(k.names)) # 0 if pre-broadcast, 1:9 if post-broadcast

