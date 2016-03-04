
# Epid 722
# G-computation with NAMCS
# Alan Brookhart

library(foreign)
library(foreach)

# read in NAMCS data -- will need to correct the path

ns=read.dta("~/Dropbox/work/classes/Epid722-2016/data/NAMCS/NSAID/nsaid008.dta")

# is there evidence of confounding?

covs=c("male","age","diabetes","arthrtis","copd","contppi",
       "reas1digest","tobacco_imp","contsteroids")
ret=foreach(var=covs,.combine="rbind") %do%
  tapply(ns[,var],ns$newcox2,mean)

row.names(ret)<-covs
colnames(ret)<-c("Old NSAIDS","Cox-2 Sel NSAIDs")
round(ret,2)


# simulate outcome using logistic regression

ns$pbleed=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                    .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                    .02*ns$raceblkoth- .3*ns$newcox2 )))

ns$bleed=rbinom(size=1,n=nrow(ns),p=ns$pbleed)


# what is E[Y(1)]-E[Y(0)], causal risk difference

pbleed.0=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                       .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                       .02*ns$raceblkoth)))

pbleed.1=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                      .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                      .02*ns$raceblkoth - 0.3)))

mean(pbleed.1)-mean(pbleed.0)


# what is E[Y(1)]/E[Y(0)]? causal risk ratio

mean(pbleed.1)/mean(pbleed.0)

# what is E[Y(1)|X=1]-E[Y(0)|X=1]?

mean(pbleed.1[ns$newcox2==1])-mean(pbleed.0[ns$newcox2==1])

# what is E[Y(1)|X=1]-E[Y(0)|contanticoag=1]?

mean(pbleed.1[ns$contanticoag==1])-mean(pbleed.0[ns$contanticoag==1])


# what is E[Y(“treat on if on warfarin”)]-E[Y(0)]?

newtreat=ifelse(ns$contanticoag==1,1,0)

pbleed.0=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                      .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                      .02*ns$raceblkoth)))

pbleed.1=1/(1+exp(-(-6.75 + .6*ns$contanticoag + 1*ns$tobacco_imp + .5*ns$contsteroids + 
                      .2*ns$contaspirin + .7*ns$arthrtis + .07*ns$age + .3*ns$male + 
                      .02*ns$raceblkoth - 0.3*newtreat)))

mean(pbleed.1)-mean(pbleed.0)


# esimtate E[Y(1)]-E[Y(0)] with MLE?

glm.out=glm(bleed~contanticoag+tobacco_imp+contsteroids+contaspirin+arthrtis+age+male+raceblkoth+newcox2,family=binomial,data=ns)
ns.temp=ns
ns.temp$newcox2=0
pbleed.0=predict(glm.out,newdata=ns.temp,type="response")
ns.temp$newcox2=1
pbleed.1=predict(glm.out,newdata=ns.temp,type="response")

mean(pbleed.1)-mean(pbleed.0)

