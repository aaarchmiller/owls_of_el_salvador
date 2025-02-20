#' # Graphing Occupancy Analysis: Mottled
#' 
#' Description: This program graphs occupancy analysis results for owls of El 
#' Salvador. Plots show the posteriors of Psi and P(detection). 
#' 
#' 
#' ### Preamble
#' 
#' Load libraries
#+ libraries, message = F, warning = F
library(knitr) # documentation-related
library(ezknitr) # documentation-related
library(devtools) # documentation-related

# analysis-related
library(ggplot2)
library(ggthemes)

#' Clear environment and set seed
#' 
#' *Note: for reproducibility, it is important to include these. Clearing the
#' environment ensures that you have specified all pertinent files that need
#' to be loaded, and setting the seed ensures that your analysis is 
#' repeatable*
remove(list = ls())
set.seed(587453)

#' _____________________________________________________________________________
#' ## Load Data
#' 
#' 
#' Psi Posteriors by year and route
load(file = "data/plotting_data/mottd_psi_posteriors_RtYr.Rdata")

#' Psi posteriors across years by species and route
load(file = "data/plotting_data/mottd_psi_posteriors_RtSpp.Rdata")

#' Probability of detection by broadcast species and species of analysis
#' 
load(file = "data/plotting_data/mottd_p_detection_posteriors.Rdata")

#' _____________________________________________________________________________
#' ## Psi = Probability of occupancy
#' 
#' ### By Route and Year
#' 
#' Mottd
#+ mottd_psi_byYr
ggplot(data = psi.post.mottd, 
       aes(x = Year, y = Psi.median, group = Route, shape = Route))+
  geom_pointrange(aes(ymin = Psi.LL05, ymax = Psi.UL95, color = Route),
                  position = position_dodge(width = .1))+
  geom_line(aes(color = Route))+
  scale_color_manual(values = c("blue", "lightblue", "green", "lightgreen", "red", "pink"))+
  scale_shape_manual(values = c(0, 16, 0, 16, 0, 16))+
  facet_wrap(~Region, nrow = 3)+
  theme_minimal()+
  xlab("Year")+
  ylab("Probability of Occupancy")+
  scale_x_continuous(breaks = 2003:2013)




#' ### By Route, averages
#'
#+ mottd_psi_means
ggplot(data = psi.means.mottd, aes(x = Route, y = Psi.median))+
  geom_bar(stat = "identity", position= position_dodge())+
  geom_linerange(aes(ymin = Psi.LL05, ymax = Psi.UL95), position = position_dodge(width = 0.9))+
  facet_wrap(~Region, nrow = 3, scales = "free_x")+
  ylim(c(0,1))+
  theme_minimal()+
  ylab("Probability of Occupancy")+
  xlab("Route")

#' _____________________________________________________________________________
#' ## p = Probability of detection
#' 
#' Probability of detection was a function of what broadcast species was used, 
#' with a constant probability of detection for all pre-broadcast time periods.
#' 
#' 
#+ mottd_p_detection, fig.width = 12
ggplot(data = p.det.post.mottd, 
       aes(y = median.plogis, x = Broadcast))+
  geom_bar(stat = "identity", position = position_dodge())+
  geom_linerange(aes(ymin = LL05.plogis, ymax = UL95.plogis), 
                 position = position_dodge(0.9))+
  geom_hline(data = p.det.post.mottd[p.det.post.mottd$broadcast.param == "beta.prebroad",], 
             aes(yintercept = median.plogis))+
  geom_hline(data = p.det.post.mottd[p.det.post.mottd$broadcast.param == "beta.prebroad",], 
             aes(yintercept = LL05.plogis), color = "grey")+
  geom_hline(data = p.det.post.mottd[p.det.post.mottd$broadcast.param == "beta.prebroad",], 
             aes(yintercept = UL95.plogis), color = "grey")+
  ylab("Probability of Detection")+
  xlab("Broadcast Species")+
  theme_minimal()

#' _____________________________________________________________________________
#' ## Save files
#' 



#' _____________________________________________________________________________
#' ### Footer
#' 
#' Session Info
devtools::session_info()
#' This document was "spun" with:
#' 
#' ezknitr::ezspin(file = "programs/f02_graphing_results_mottd.R", out_dir = "output", fig_dir = "figures", keep_md = F)
#' 