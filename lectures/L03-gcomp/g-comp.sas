******************************************************
* G-computation example applied in NAMCS NSAID data
* Xiaojuan Li
******************************************************;

options nocenter pagesize=60 linesize=80 nodate pageno=1 
	compress=yes threads cpucount=actual nofmterr;
dm log "clear;" continue; dm out "clear;" continue;

libname a "C:/Users/xli.AD/Dropbox/Epid722-2015/Data/NAMCS";

proc contents data = a.nsaid008;
run;

*simulate outcome using logistic regression and find prob of bleed;
DATA ns;
   SET a.nsaid008b;
   pbleed=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                    .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                    .02*raceblkoth- .3*newcox2 )));
   call streaminit(1234);
   bleed=rand("bernoulli",pbleed);   *simulate the observed outcome;
run;

proc freq data = ns;
    table bleed;
run;

*********************************************************
* what is E[Y(1)]-E[Y(0)], causal risk difference?
*********************************************************
* Approach 1 - 1) create two copies of the original dataset 
               2) set X=1 for the first copy and X=0 for the second copy
               3) predict Y for all observations using the coefficients and X: in first copy, X=1, predict Y which is Y(1), in second copy, X=0, predict Y which is Y(0)
               4) stack the datasets together and analyze using proc genmod modeling pbleed and treatment X 
                  or use simple proc means;
DATA ns1;
   SET ns;
   X=1;
   pbleed=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                       .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                       .02*raceblkoth -0.3*X)));  *E[Y(1)];
DATA ns0;
   SET ns;
   X=0;
   pbleed=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                       .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                       .02*raceblkoth -0.3*X)));  *E[Y(0)];
DATA nsf;
   SET ns1 ns0;
RUN;

*to find the causal risk difference E[Y(1)]-E[Y(0)] using proc genmod;
proc genmod data=nsf;
    model pbleed = x /link=identity ;
	title "causal risk difference";
run;
*to find the causal risk ratio E[Y(1)]/E[Y(0)] using proc genmod;
proc genmod data=nsf;
    model pbleed = x /link=log ;
	estimate 'causal risk ratio' x 1;
	title "causal risk ratio";
run;
title;
*or just can use simple proc means;
proc means data=nsf;
     class X;
	 var pbleed;
	 output out=a mean=pbleed; 
proc transpose data=a out=a1(rename=(col1=overall col2=pbleed0 col3=pbleed1)) ;
    var pbleed;
data a2;
    set a1;
	RD = pbleed1-pbleed0;
	RR = pbleed1/pbleed0;
proc print data=a2; run;

*Approach 2 - use the orginal dataset and add two predicted potential outcomes Y(1) and Y(2) as columns/variables;
DATA nsg;
   SET ns;
   pbleed_1=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                       .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                       .02*raceblkoth -0.3*1)));  *E[Y(1)];
   pbleed_0=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                       .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                       .02*raceblkoth -0.3*0)));  *E[Y(0)];
RUN;
*then use proc means to get causal RD and RR;
proc means data = nsg;
     var pbleed_1 pbleed_0;
	 output out=b mean=upbleed_1 upbleed_0;
DATA b1;
    set b;
	RD = upbleed_1 - upbleed_0;
	RR = upbleed_1/upbleed_0;
proc print data = b1;
run;

***********************************************************
*what is E[Y(1)|X=1]-E[Y(0)|X=1]? Among treated population
***********************************************************
 *conditioning the dataset to the treated population;
proc means data = nsg;
    where newcox2=1;
     var pbleed_1 pbleed_0;
	 output out=me_trt mean=upbleed_1 upbleed_0;
run;
DATA me_trt1;
    set me_trt;
	RD = upbleed_1 - upbleed_0;
	RR = upbleed_1/upbleed_0;
proc print data=me_trt1;
	title "among treated population"; run;
title;

***********************************************************
*what is E[Y(1)|contanticoag=1]-E[Y(0)|contanticoag=1]? 
***********************************************************;
proc means data = nsg;
    where contanticoag=1;
    var pbleed_1 pbleed_0;
	output out=me_cont mean=upbleed_1 upbleed_0;
run;
DATA me_cont1;
    set me_cont;
	RD = upbleed_1 - upbleed_0;
	RR = upbleed_1/upbleed_0;
proc print data=me_cont1;
	title "among warfarin users"; run;
run;
title;

************************************************************************************
* what is E[Y(treated if on warfarin)]-E(Y(0))? Assessing effect of treatment rules;
************************************************************************************;
DATA nsh;
   set nsg;
   if  contanticoag=1 then treat=1;
   else treat=0;
   pbleed_2=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                       .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                       .02*raceblkoth -0.3*treat)));  *E[Y(treated if on warfarin)];
run;
proc means data = nsh;
     var pbleed_2 pbleed_0;
	 output out=me_war mean=upbleed_2 upbleed_0;
run;
DATA me_war1;
    set me_war;
	RD = upbleed_2 - upbleed_0;
	RR = upbleed_2/upbleed_0;
proc print data=me_war1;
    title "treated if only on warfarin";
run;
title;

***********************************************
* how do you esimtate E[Y(1)]-E[Y(0)] with MLE
***********************************************;
proc genmod data = ns desc ;
    model bleed = contanticoag tobacco_imp contsteroids contaspirin arthrtis age male raceblkoth newcox2/link=logit dist=bin;
	ods select parameterestimates;
    ods output parameterestimates=betas(keep=parameter estimate);
run;
proc transpose data=betas out=betas2(drop=beta11) prefix=beta; *this makes the set of gamma horizontal;
run;

data ns_p;
   set ns;
   if _N_=1 then set betas2;
   pbleed_1=1/(1+exp(-(beta1 + beta2*contanticoag + beta3*tobacco_imp + beta4*contsteroids + 
                       beta5*contaspirin + beta6*arthrtis + beta7*age + beta8*male + 
                       beta9*raceblkoth + beta10*1)));  *E[Y(1)];
   pbleed_0=1/(1+exp(-(beta1 + beta2*contanticoag + beta3*tobacco_imp + beta4*contsteroids + 
                       beta5*contaspirin + beta6*arthrtis + beta7*age + beta8*male + 
                       beta9*raceblkoth + beta10*0)));  *E[Y(0)];
proc means data = ns_p;
     var pbleed_1 pbleed_0;
	 output out=me_mle mean=upbleed_1 upbleed_0;
run;
DATA me_mle1;
    set me_mle;
	RD = upbleed_1 - upbleed_0;
	RR = upbleed_1/upbleed_0;
proc print data=me_mle1;
   title "estimates with MLE";
run;


