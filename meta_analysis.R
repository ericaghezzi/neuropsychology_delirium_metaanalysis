####Neuropsychology of Delirium Meta-analysis######

#load packages
library(estmeansd)
library(esc)
library(readxl)
library(readr)
library(tidyverse)
library(metafor)

#set working directory
setwd("R:/GitHub/neuropsych_delirium_metaanalysis/")

#import data
data <- read_csv("data.csv", col_types = cols(g = col_number(),
                                              g_vi = col_number(),
                                              g_sei = col_number(),
                                              or = col_number(),
                                              or_vi = col_number(),
                                              or_sei = col_number()))
#rename data file
prac_data <- data

#transformations (of median or mean/95%CI or mean/SEM) to mean/SD
for (i in 1:length(prac_data$id)) {
  if(prac_data[i, "mean_median_na"] == "median") {
    if(prac_data[i, "median_type"] == "s1") { #s1 (min, med, max)
      ##del mean and sd calc
      min <- prac_data[[i, "del_qmin"]]
      max <- prac_data[[i, "del_qmax"]]
      med <- prac_data[[i, "del_median_q2"]]
      n <- prac_data[[i, "del_sample_size"]]
      
      mean_calc <- qe.mean.sd(min.val = min, med.val = med, max.val = max, n = n)
      
      prac_data[i, "del_mean"] <- as.numeric(mean_calc["est.mean"])
      prac_data[i, "del_sd"] <- as.numeric(mean_calc["est.sd"])
      
      ##no del mean and sd calc
      min <- prac_data[[i, "NoDel_qmin"]]
      max <- prac_data[[i, "NoDel_qmax"]]
      med <- prac_data[[i, "NoDel_median_q2"]]
      n <- prac_data[[i, "NoDel_sample_size"]]
      
      mean_calc <- qe.mean.sd(min.val = min, med.val = med, max.val = max, n = n)
      
      prac_data[i, "NoDel_mean"] <- mean_calc[["est.mean"]]
      prac_data[i, "NoDel_sd"] <- mean_calc[["est.sd"]]
    }
    if(prac_data[i, "median_type"] == "s2") { #s2 (q1,q3,med)
      ##del mean and sd calc
      q1 <-  prac_data[[i, "del_q1"]]
      q3 <- prac_data[[i, "del_q3"]]
      med <- prac_data[[i, "del_median_q2"]]
      n <- prac_data[[i, "del_sample_size"]]
      
      mean_calc <- qe.mean.sd(q1.val = q1, med.val = med, q3.val = q3, n = n)
      
      prac_data[i, "del_mean"] <- mean_calc[["est.mean"]]
      prac_data[i, "del_sd"] <- mean_calc[["est.sd"]]
      
      ##no del mean and sd calc
      q1 <- prac_data[[i, "NoDel_q1"]]
      q3 <- prac_data[[i, "NoDel_q3"]]
      med <- prac_data[[i, "NoDel_median_q2"]]
      n <- prac_data[[i, "NoDel_sample_size"]]
      
      mean_calc <- qe.mean.sd(q1.val = q1, med.val = med, q3.val = q3, n = n)
      
      prac_data[i, "NoDel_mean"] <- mean_calc[["est.mean"]]
      prac_data[i, "NoDel_sd"] <- mean_calc[["est.sd"]]
    }
  }
  if(prac_data[i, "mean_median_na"] == "mean_95CI") { #calculate standard deviation from 95%CI data
    prac_data[i, "del_sd"] <- sqrt(prac_data[[i, "del_sample_size"]])*((prac_data[[i, "del_95CI_ul"]]-prac_data[[i, "del_95CI_ll"]])/3.92)
    prac_data[i, "NoDel_sd"] <- sqrt(prac_data[[i, "NoDel_sample_size"]])*((prac_data[[i, "NoDel_95CI_ul"]]-prac_data[[i, "NoDel_95CI_ll"]])/3.92)
  }
  if(prac_data[i, "mean_median_na"] == "mean_sem") { #calculate standard deviation from SEM data
    prac_data[i, "del_sd"] <- prac_data[[i, "del_sem"]]*sqrt(prac_data[[i, "del_sample_size"]])
    prac_data[i, "NoDel_sd"] <- prac_data[[i, "NoDel_sem"]]*sqrt(prac_data[[i, "NoDel_sample_size"]])
  }
}

#effect size calculations for:
  #mean/SD data to Hedges g
  #categorical/count data to OR and Hedges g
  #OR to Hedges g
  #chi square to Hedges g
for (i in 1:length(prac_data$id)) {
  if(prac_data[i, "data_type"] == "quant_mean_sd") { #take all mean/SD data
    #assign variables (mean, sd, N for both groups)
    m1i <- prac_data[[i, "del_mean"]]
    sd1i <- prac_data[[i, "del_sd"]]
    n1i <- prac_data[[i, "del_sample_size"]]
    
    m2i <- prac_data[[i, "NoDel_mean"]]
    sd2i <- prac_data[[i, "NoDel_sd"]]
    n2i <- prac_data[[i, "NoDel_sample_size"]]
    
    #run effect size (Hedges g) calc
    es <- escalc(measure = "SMD", m1i = m1i, sd1i = sd1i, n1i = n1i, m2i = m2i, sd2i = sd2i, n2i = n2i)
    es_summary <- summary.escalc(es)
    
    #copy across effect size into data frame
    prac_data[i, "g"] <- as.numeric(es$yi[1])
    prac_data[i, "g_vi"] <- as.numeric(es$vi[1])
    prac_data[i, "g_sei"] <- as.numeric(es_summary$sei)
  }
  if(prac_data[i, "data_type"] == "quant_count") {  #take all categorical/count data
    #assign variables (N with decline, N without, total N for both groups)
    ai <- prac_data[[i, "Del_n_with_impaired_cog"]]
    bi <- prac_data[[i, "Del_total_n"]] - prac_data[[i, "Del_n_with_impaired_cog"]]
    n1i <- prac_data[[i, "Del_total_n"]]
    ci <- prac_data[[i, "No_del_n_with_impaired_cog"]]
    di <- prac_data[[i, "No_del_total_n"]] - prac_data[[i, "No_del_n_with_impaired_cog"]]
    n2i <- prac_data[[i, "No_del_total_n"]]
    
    #run effect size (OR) calc
    or <- escalc(measure = "OR", ai = ai, bi = bi, n1i = n1i, ci = ci, di = di, n2i = n2i)
    or_summary <- summary.escalc(or) #use this to calculate sei (which is also able to be calculated for raw OR data and so both can be pooled together)
    
    #run effect size (Hedges g) calc
    g_or <- escalc(measure = "OR2DN", ai = ai, bi = bi, n1i = n1i, ci = ci, di = di, n2i = n2i)
    g_or_summary <- summary.escalc(g_or)
    
    #copy across effect size into data frame
    prac_data[i, "or"] <- as.numeric(or$yi[1])
    prac_data[i, "or_vi"] <- as.numeric(or$vi[1]) 
    prac_data[i, "or_sei"] <- as.numeric(or_summary$sei)
    
    prac_data[i, "g"] <- as.numeric(g_or$yi[1]) 
    prac_data[i, "g_vi"] <- as.numeric(g_or$vi[1])
    prac_data[i, "g_sei"] <- as.numeric(g_or_summary$sei)
  }
  if(prac_data[i, "data_type"] == "or") { #take all OR data 
    #or to smd calculation
    smd_or <- (sqrt(3)/pi)*log(prac_data[[i, "odds_ratio"]])
    
    #or upper and lower limits to st error
    lower <- log(prac_data[[i, "or_95CI_ll"]])
    upper <- log(prac_data[[i, "or_95CI_ul"]])
    
    logodds_sterr <- (upper - lower)/3.92 #calculate standard error with 95% CI
    
    #convert to standard error of SMD by multiplying by same constant
    smd_or_sterr <- (sqrt(3)/pi)*logodds_sterr
    
    #copy across effect size into data frame
    prac_data[i, "or"] <- as.numeric(log(prac_data[[i, "odds_ratio"]])) #log odds to match other calc
    prac_data[i, "or_sei"] <- as.numeric(logodds_sterr)
    
    prac_data[i, "g"] <- as.numeric(smd_or)
    prac_data[i, "g_sei"] <- as.numeric(smd_or_sterr)
  } 
  if(prac_data[i, "data_type"] == "chi_square") { #take all chi square data
    #assign variables (chi square, p, N)
    chisq <- prac_data[[i, "chi_square"]]
    p <- prac_data[[i, "chi_square_p"]]
    N <- prac_data[[i, "chi_square_N"]]
    
    #run effect size (Hedges g) calc
    chisq <- esc_chisq(chisq = chisq, totaln = N, es.type = "g")
    
    #copy across effect size into data frame (transform negatively coded effect direction)
    if(prac_data[i, "effect_direction"] == "Negative") {
      #copy to df
      prac_data[i, "g"] <- as.numeric(chisq$es[[1]])*-1
      prac_data[i, "g_sei"] <- as.numeric(chisq$se[[1]])
    }
    if(prac_data[i, "effect_direction"] == "Positive"){
      #copy to df
      prac_data[i, "g"] <- as.numeric(chisq$es[[1]])
      prac_data[i, "g_sei"] <- as.numeric(chisq$se[[1]])
    }
  }
}

#### add data for subgroup analyses ####
#load demographic data
demo_data <- read_csv("demo_data.csv")
#we only need covidence identifier column and columns relevant for subgroup analyses
demo_data <- demo_data %>%
  select(covidence_study_id, predel_exclusion, precog_exclusion, precipitant, del_assessors_trained) %>%
  mutate(precog_exclusion_yesno = ifelse(precog_exclusion == "no", "no", "yes")) #mutate to collapse across dementia/cognition exclusion criteria
#join demo_data to main data file (prac_data)
prac_data <- left_join(prac_data, demo_data, by="covidence_study_id")

####### cognitive domain analysis ######
######Remove extreme value (following inspection of forest plot of all data points)#####
prac_data <- prac_data %>%
  filter(author != "Tai") #remove as extreme value

#set up data file (only include relevant data [domain] and adjust for test direction)
meta_data_cog <- prac_data %>%
  filter(analysis == "domain") %>% #only include data relevant for domains analysis
  mutate(g_trans = ifelse(test_direction == "Negative", g*-1, g), #add in adjustment for negatively coded tests (*-1)
         or_trans = ifelse(test_direction == "Negative", or*-1, or)) #add in adjustment for negatively coded tests (*-1)

#### analysis for all data (quant_mean_sd/quant_count/OR/chi_square) ####
#set up data file for all cognition (not pooled by domains) analysis
data_allcog <- meta_data_cog %>%
  filter(data_type == "quant_mean_sd" | data_type == "quant_count" | data_type == "or"| data_type == "chi_square") %>% 
  group_by(covidence_study_id) %>% #group by study so future calculations are done within each study
  mutate(g_trans = mean(g_trans, na.rm = T),
         g_sei = mean(g_sei, na.rm = T)) %>% #obtain average g and st err within each study (average across domains), removing NAs from calculation
  filter(row_number()==1) %>% #make each study only appear on one row
  ungroup()

#all cognition meta-analysis
meta_allcog <- rma(data = data_allcog, yi = g_trans, sei = g_sei, method = "PM", test = "knha")

#set up data file for domain analysis
data_domain <- meta_data_cog %>%
  filter(data_type == "quant_mean_sd" | data_type == "quant_count" | data_type == "or" | data_type == "chi_square") %>%
  group_by(covidence_study_id, cog_domain_lezak) %>% #group by study/domain so future calculations are done within each domain within each study
  mutate(g_trans = mean(g_trans, na.rm = T),
         g_sei = mean(g_sei, na.rm = T)) %>% #obtain average g and st err within each study/domain, removing NAs from calculation
  filter(row_number()==1) %>% #make each study/domain only appear on one row
  ungroup() %>%
  group_by(cog_domain_lezak) %>% #group by cognitive domain
  mutate(cog_domain_n = n()) %>% #count n rows for each domain
  filter(cog_domain_n != 1) %>% #remove any domains where k = 1
  ungroup()

#domain meta-analysis (separate estimates of residual heterogeneity)
#run individual meta-analyses for each cognitive domain
att <- rma(data = data_domain, subset = (cog_domain_lezak == "Attention"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
con <- rma(data = data_domain, subset = (cog_domain_lezak == "Construction & Motor Performance"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
exe <- rma(data = data_domain, subset = (cog_domain_lezak == "Executive Functions"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
mem <- rma(data = data_domain, subset = (cog_domain_lezak == "Memory"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
ori <- rma(data = data_domain, subset = (cog_domain_lezak == "Orientation"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
per <- rma(data = data_domain, subset = (cog_domain_lezak == "Perception"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")
ver <- rma(data = data_domain, subset = (cog_domain_lezak == "Verbal Functions & Language Skills"), yi = g_trans, sei = g_sei, method = "PM", test = "knha")

#add all estimates and model information for individual domain meta-analyses into one data frame
domain_sep <- data.frame(b = c(coef(att), 
                               coef(con),
                               coef(exe),
                               coef(mem),
                               coef(ori),
                               coef(per),
                               coef(ver)),
                          k = c(att$k,
                                con$k,
                                exe$k,
                                mem$k,
                                ori$k,
                                per$k,
                                ver$k),
                          ci.lb = c(att$ci.lb,
                                    con$ci.lb,
                                    exe$ci.lb,
                                    mem$ci.lb,
                                    ori$ci.lb,
                                    per$ci.lb,
                                    ver$ci.lb),
                          ci.ub = c(att$ci.ub,
                                    con$ci.ub,
                                    exe$ci.ub,
                                    mem$ci.ub,
                                    ori$ci.ub,
                                    per$ci.ub,
                                    ver$ci.ub),
                          stderror = c(att$se,
                                       con$se,
                                       exe$se,
                                       mem$se,
                                       ori$se,
                                       per$se,
                                       ver$se),
                          pval = c(att$pval,
                                   con$pval,
                                   exe$pval,
                                   mem$pval,
                                   ori$pval,
                                   per$pval,
                                   ver$pval),
                          domain = c("Attention",
                                     "Construction & Motor Performance",
                                     "Executive Functions",
                                     "Memory",
                                     "Orientation",
                                     "Perception",
                                     "Verbal Functions & Language Skills"),
                          tau2 = c(att$tau2,
                                   con$tau2,
                                   exe$tau2,
                                   mem$tau2,
                                   ori$tau2,
                                   per$tau2,
                                   ver$tau2),
                          se.tau2 = c(att$se.tau2,
                                      con$se.tau2,
                                      exe$se.tau2,
                                      mem$se.tau2,
                                      ori$se.tau2,
                                      per$se.tau2,
                                      ver$se.tau2),
                          I2 = c(att$I2,
                                 con$I2,
                                 exe$I2,
                                 mem$I2,
                                 ori$I2,
                                 per$I2,
                                 ver$I2),
                          QE = c(att$QE,
                                 con$QE,
                                 exe$QE,
                                 mem$QE,
                                 ori$QE,
                                 per$QE,
                                 ver$QE),
                          QEp = c(att$QEp,
                                  con$QEp,
                                  exe$QEp,
                                  mem$QEp,
                                  ori$QEp,
                                  per$QEp,
                                  ver$QEp))

#compare domains (with fixed effects model)
meta_domain_sep <- rma(b, sei = stderror, mods = ~domain, method = "FE", data = domain_sep)

###### variability analysis ###### 
#set up data file
meta_data_variability <- prac_data %>%
  filter(data_type == "quant_mean_sd"| data_type == "quant_count" | data_type == "or" | data_type == "chi_square") %>%
  filter(analysis == "variability") %>% #only keep variability data points
  group_by(covidence_study_id) %>% #group by study so future calculations are done within each study
  mutate(g = mean(g, na.rm = T),
         g_sei = mean(g_sei, na.rm = T)) %>% #obtain average g and st err within each study, removing NAs from calculation
  filter(row_number()==1) %>% #make each study only appear on one row
  ungroup() %>%
  select(id,cog_domain_lezak,test_direction,g,g_sei)

#run meta-analysis
meta_variability <- rma(data = meta_data_variability, yi = g, sei = g_sei, method = "PM", test = "knha")

#assess publication bias
tiff(filename = "funnel_var.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(meta_variability, xlab = "Hedges' g")
dev.off()

#### assess publication bias ####
#publication bias on individual cog domain analyses
#save funnel plot and run egger's test for all
tiff(filename = "funnel_att.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(att, xlab = "Hedges' g")
dev.off()
#egger's regression test
regtest(att, model = "rma")
#p >0.1 no evidence of asymmetry

tiff(filename = "funnel_con.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(con, xlab = "Hedges' g")
dev.off()
#egger's regression test
regtest(con, model = "rma")
#p >0.1 no evidence of asymmetry

tiff(filename = "funnel_exe.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(exe, xlab = "Hedges' g")
dev.off()
#egger's regression test
regtest(exe, model = "rma")
#p >0.1 no evidence of asymmetry

tiff(filename = "funnel_mem.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(mem, xlab = "Hedges' g")
dev.off()
#egger's regression test
regtest(mem, model = "rma")
#p >0.1 no evidence of asymmetry

tiff(filename = "funnel_ori.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(ori, xlab = "Hedges' g")
dev.off()
#visual inspection

tiff(filename = "funnel_per.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(per, xlab = "Hedges' g")
dev.off()
#visual inspection

tiff(filename = "funnel_ver.tiff", width = 8, height = 6, units = "in", res = 300, compression = "lzw")
funnel(ver, xlab = "Hedges' g")
dev.off()
#egger's regression test
regtest(ver, model = "rma")
#p >0.1 no evidence of asymmetry

#### forest plot ####
#arrange the domain data frame in descending order of cognitive domains and effect size
forest_domain <- data_domain %>%
  arrange(desc(cog_domain_lezak), desc(g_trans)) %>%
  mutate(row_n = row_number()) #number rows so this can be used to order forest plot

#run meta-analysis on this data so forest plot can be built
forest <- rma(data = forest_domain, yi = g_trans, sei = g_sei, method = "PM", test = "knha")

#create (and save as .tiff) forest plot
tiff(filename = "forest.tiff", width = 11, height = 23, units = "in", res = 600, compression = "lzw") #set up .tiff save conditions

#domain forest plot
forest(forest, #specify data
       slab = paste(forest_domain$author, forest_domain$year, sep = ", "), #study labels
       xlim=c(-4, 2), at=c(-3,-2,-1,0,1),
       alim=c(-3,1),
       cex=0.9, 
       order = forest_domain$row_n, #order rows based on previous calculation
       ylim = c(-1,127),
       rows=c(3:15,20:23,28:32,37:55,60:74,79:88,93:123), #specify rows for each effect size to occupy (separate for each cognitive domain, with 5 rows in between each)
       xlab="Hedges' g", mlab="", psize=1, 
       header=c("Lead author, Year", "Hedges' g [95% CI]"),
       addfit = F,
       efac = 0.5)

#add horizontal line at y=0
abline(h=0)
#add summary stats for global cognition model (RE model)
text(2, -1, cex = 0.9, pos = 2, bquote(paste(.(formatC(meta_allcog$b, digits = 2, format = "f")), " [", .(formatC(meta_allcog$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(meta_allcog$ci.ub, digits = 2, format = "f")), "]")))
#add overall summary polygon for global cognition model (RE model)
addpoly.default(x = meta_allcog$b, sei = meta_allcog$se, row = -1, cex = 0.9, mlab = "", efac = 0.5, annotate = F)


#add text for dfs, p, and I2 for global cognition model (RE model)
text(-4,-1, pos = 4, cex = 0.9, bquote(paste("RE Model for Global Cognition (df = ", .(meta_allcog$k - meta_allcog$p), ", p < 0.001; ", I^2, " = ",
                                           .(formatC(meta_allcog$I2, digits = 1, format = "f")), "%)")))

#add text for the test of subgroup differences (FE model)
text(-4, -2.5, pos=4, cex=0.9, bquote(paste("Test for Subgroup Differences (FE Model): ",
                                              Q[M], " = ", .(formatC(meta_domain_sep$QM, digits=2, format="f")), ", df = ", .(meta_domain_sep$p - 1),
                                              ", p = ", .(formatC(meta_domain_sep$QMp, digits=3, format="f")))))

### set font expansion factor (as in forest() above) and use bold italic
### font and save original settings in object 'op'
op <- par(cex=0.9, font=4)

#add subheadings for the subgroups (1 point above the last row of data for each subgroup)
text(-4, c(124,89,75,56,33,24,16), pos = 4, c("Attention",
                                              "Construction & Motor Performance",
                                              "Executive Functions",
                                              "Memory",
                                              "Orientation",
                                              "Perception",
                                              "Verbal Functions & Language Skills"))
op <- par(cex=0.9, font=2)
#add subheadings for the 'Overall' effect size for each subgroup (1.5 points before the first row of data for each subgroup)
text(-4, c(91.5,77.5,58.5,35.5,26.5,18.5,1.5), pos=4, "Overall", col = "red")

#add summary polygons for the subgroups (1.5 points before the first row of data for each subgroup)
addpoly.default(x = att$b, sei = att$se, row = 91.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #att
addpoly.default(x = con$b, sei = con$se, row = 77.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #con
addpoly.default(x = exe$b, sei = exe$se, row = 58.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #exe
addpoly.default(x = mem$b, sei = mem$se, row = 35.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #mem
addpoly.default(x = ori$b, sei = ori$se, row = 26.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #ori
addpoly.default(x = per$b, sei = per$se, row = 18.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #per
addpoly.default(x = ver$b, sei = ver$se, row = 1.5, cex = 1, mlab = "", efac = 0.5, annotate = F, col = "red", border = "red") #ver

#add summary statistics (estimate and 95%CI) for each subgroup
#format "f" keeps trailing zeros
text(2, 91.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(att$b, digits = 2, format = "f")), " [", .(formatC(att$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(att$ci.ub, digits = 2, format = "f")), "]")))
text(2, 77.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(con$b, digits = 2, format = "f")), " [", .(formatC(con$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(con$ci.ub, digits = 2, format = "f")), "]")))
text(2, 58.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(exe$b, digits = 2, format = "f")), " [", .(formatC(exe$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(exe$ci.ub, digits = 2, format = "f")), "]")))
text(2, 35.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(mem$b, digits = 2, format = "f")), " [", .(formatC(mem$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(mem$ci.ub, digits = 2, format = "f")), "]")))
text(2, 26.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(ori$b, digits = 2, format = "f")), " [", .(formatC(ori$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(ori$ci.ub, digits = 2, format = "f")), "]")))
text(2, 18.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(per$b, digits = 2, format = "f")), " [", .(formatC(per$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(per$ci.ub, digits = 2, format = "f")), "]")))
text(2, 1.5, cex = 1, pos = 2, col = "red", bquote(paste(.(formatC(ver$b, digits = 2, format = "f")), " [", .(formatC(ver$ci.lb, digits = 2, format = "f")), ", " ,.(formatC(ver$ci.ub, digits = 2, format = "f")), "]")))

dev.off() #save plot
