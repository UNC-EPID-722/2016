# simulated free drugs study
# Alan Brookhart

n=50000
set.seed(100)
free_drugs = rbinom(p=0.5,n=n,size=1)
hx_nonadherence = rbinom(p=0.5,n=n,size=1)
c2=rnorm(n=n)
py = (1+exp(1.9+0.9*free_drugs-1.2*hx_nonadherence-c2))^(-1)
y = rbinom(p=py,size=1,n=n)

mean(y)
mean(y[free_drugs==1])
mean(y[free_drugs==0])
mean(y[hx_nonadherence==1])
mean(y[hx_nonadherence==0])

ds=data.frame(free_drugs=free_drugs,hx_nonadherence=hx_nonadherence,
              y=y,c2=c2)

out.glm=glm(y~free_drugs+hx_nonadherence+c2,family=binomial,data=ds)
summary(out.glm)

out.glm=glm(y~free_drugs*hx_nonadherence+c2,family=binomial,data=ds)
summary(out.glm)

# "g-computation"

# E[Y(1)]-E[Y(0)]
temp1=ds
temp1$free_drugs=1
temp2=ds
temp2$free_drugs=0
mean(predict(out.glm,newdata=temp1,type="response")) - mean(predict(out.glm,newdata=temp2,type="response"))

mean(y[free_drugs==1])  - mean(y[free_drugs==0])

# E[Y(1)|history of non-adh]-E[Y(0)|history of non-adh]

temp1=ds[ds$hx_nonadherence==1,]
temp1$free_drugs=1
temp2=temp1
temp2$free_drugs=0
mean(predict(out.glm,newdata=temp1,type="response"))-
  mean(predict(out.glm,newdata=temp2,type="response"))

mean(y[free_drugs==1 & hx_nonadherence==1]) - mean(y[free_drugs==0  & hx_nonadherence==1])

# E[Y(1)|history of non-adh]-E[Y(0)|!history of non-adh]

temp1=ds[ds$hx_nonadherence==0,]
temp1$free_drugs=1
temp2=temp1
temp2$free_drugs=0
mean(predict(out.glm,newdata=temp1,type="response"))-
  mean(predict(out.glm,newdata=temp2,type="response"))

mean(y[free_drugs==1 & hx_nonadherence==0]) - mean(y[free_drugs==0  & hx_nonadherence==0])

# E[Y(1)]-E[Y]

temp1=ds
temp1$free_drugs=1
 mean(predict(out.glm,newdata=temp1,type="response")) -mean(y) 

mean(y[free_drugs==1])-mean(y)  

# E[Y(if hx_nonadherence==1, then free_drugs=1, else free_drugs=0)] - E[Y]

temp1=ds
temp1$free_drugs=ifelse(temp1$hx_nonadherence==1,1,0)
mean(predict(out.glm,newdata=temp1,type="response")) - mean(y) 

(mean(y[(free_drugs==1 & hx_nonadherence==1)])*0.5 + mean(y[(free_drugs==0 & hx_nonadherence==0)])*0.5) - mean(y)
