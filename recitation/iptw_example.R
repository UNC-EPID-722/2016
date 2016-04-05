# 
# IPTW estimation applied in NAMCS NSAID data
# Alan Brookhart
#

library(foreign)
library(foreach)
library(ggplot2)
library(geepack)

# read in NAMCS data -- will need to correct the path

ns=read.dta("~/Dropbox/work/classes/Epid722-2015/Data/NAMCS/nsaid008b.dta")

# Simulate outcome using logistic regression

ns$pbleed=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                       .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                       .02*ns$raceblkoth- .3*ns$newcox2 )))

set.seed(101)
ns$bleed=rbinom(size=1,n=nrow(ns),p=ns$pbleed)


# What is true E[Y(1)]-E[Y(0)] in our population, the causal risk difference?

pbleed.0=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                      .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                      .02*ns$raceblkoth)))

pbleed.1=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                      .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                      .02*ns$raceblkoth - 0.3)))

mean(pbleed.1)-mean(pbleed.0)


# What is E[Y(1)]/E[Y(0)], the true causal risk ratio?

mean(pbleed.1)/mean(pbleed.0)

# what is E[Y(1)|X=1]-E[Y(0)|X=1]?

mean(pbleed.1[ns$newcox2==1])-mean(pbleed.0[ns$newcox2==1])


# Estimate the (unknown) propensity score, and plot the density by treatment group

glm.out=glm(newcox2~contanticoag+tobacco_imp+contsteroids+diabetes+contaspirin+arthrtis+age+male+raceblkoth,family=binomial,data=ns)
ns$ps=predict(glm.out,type="response")

plot(density(ns$ps[ns$newcox2==0]),lty=1,main="Propensity Score Distribution")
lines(density(ns$ps[ns$newcox2==1]),lty=2)
legend("right",c("newcox2==0","newcox2==1"),lty=c(1,2),box.col=NA)

ggplot(data=ns,aes(x=ps,group=factor(newcox2), fill=factor(newcox2)))+
  geom_histogram(aes(y=..density..),alpha = 0.75,binwidth=0.01, 
                 position = position_dodge(width=0.005))+theme_bw()


# compute IPTW and SMRW weights

ns$iptw=ns$newcox2/ns$ps+(1-ns$newcox2)/(1-ns$ps)
ns$smrw=ns$newcox2+(1-ns$newcox2)*ns$ps/(1-ns$ps)


# Table 1
covs=c("male","age","diabetes","arthrtis","copd",
       "reas1digest","tobacco_imp","contsteroids")
ret=foreach(var=covs,.combine="rbind") %do%
  c(mean(ns[ns$newcox2==0,var]),mean(ns[ns$newcox2==1,var]))
row.names(ret)<-covs
colnames(ret)<-c("Old NSAIDS","Cox-2 Sel NSAIDs")
round(ret,2)


# Compute Table 1 statistics for IPTW sample
ret=foreach(var=covs,.combine="rbind") %do%
  c(sum(ns[,var]*ns$iptw*ns$newcox2),sum(ns[,var]*ns$iptw*(1-ns$newcox2)))/nrow(ns)
row.names(ret)<-covs
colnames(ret)<-c("Old NSAIDS","Cox-2 Sel NSAIDs")
round(ret,2)


# Unweighted regression, crude
summary(glm(bleed~newcox2,data=ns))

# IPT weighted, use GEE for SE
summary(geeglm(bleed~newcox2,family=gaussian, weight=iptw, id=patcode, data=ns))

# SMR weighted, use GEE for SE
summary(geeglm(bleed~newcox2,family=gaussian, weight=smrw, id=patcode, data=ns))




