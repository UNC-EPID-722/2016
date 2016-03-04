*program9.1feb16, missing data;

*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
%let dir = D:\dropbox\Cole\Teaching\EPID722\2016;
*%let dir = Y:\Cole\Teaching\EPID722\2016;

*Read ASCII file;
data a;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;
	
*Full data adjusted Cox model (we wish we had the full data);
proc phreg data=a;
	model t*delta(0)=idu white age cd4/rl ties=efron;
	ods select modelinfo censoredsummary fitstatistics parameterestimates;
	title "Full data adjusted Cox model";

*Make some data MAR, you can (and perhaps should) skip this data step at first;
data b; 
	set a;
	call streaminit(1); *initiaize a reproducable pseudorandom number stream;
	*expected values in the full data;
	eidu=.377;
	edelta=.497;
	*choose marginal distribution for missing data pattern;
	ep2=.2; ep3=.15; ep4=.05;
	*back-calculate intercepts;
	int4=-log(1/ep4-1);
	int3=-log(1/ep3-1)-log(5)*eidu;
	int2=-log(1/ep2-1)-log(5)*edelta;
	*pattern 4, both missing;
	p4=1/(1+exp(-(int4)));
	*pattern 2,3 one missing;
	p3=1/(1+exp(-(int3+log(5)*idu)));
	p2=1/(1+exp(-(int2+log(5)*delta)));
	*pattern 1, no missing;
	p1=1-p2-p3-p4;
	*draw pattern for each subject;
	pattern=rand("table",p1,p2,p3,p4);
	*set data missing depending on drawn pattern;
	if pattern=2 then idu=.;
		else if pattern=3 then delta=.;
		else if pattern=4 then do; idu=.; delta=.; end;
	if idu>. and delta>. then complete=1; else complete=0;

*Look at observed data, now with missingness (this is what we usually get);
proc means data=b n nmiss mean sum min max; 
	var delta t drop idu white age cd4 complete;
	title "Time from 12/6/95 to AIDS or death in WIHS";
proc freq data=b; tables pattern;

*Complete-case Cox model;
proc phreg data=b;
	where complete;
	model t*delta(0)=idu white age cd4/rl ties=efron;
	ods select modelinfo censoredsummary fitstatistics parameterestimates;
	title "Complete-case Cox model";

*MI, assuming MVN;
proc mi data=b seed=3 nimpute=100 out=c;
	var white age cd4 delta idu;
	mcmc; *default is chain=single nbiter=200 niter=100 prior=Jeffreys initial=EM;
proc phreg data=c covout outest=d noprint;
	model t*delta(0)=idu white age cd4/rl; 
	by _imputation_; 
proc mianalyze data=d; 
	modeleffects idu white age cd4;	
	title "Multiple imputation";

*Nonmonotonic IP weights, without constraint;
proc nlmixed data=b qtol=1e-12 gtol=1e-12; 
	parms gamma40 gamma30 gamma20 -2
			gamma41-gamma43 gamma31-gamma34 gamma21-gamma24 0;
	p4=1/(1+exp(-(gamma40+gamma41*white+gamma42*cd4+gamma43*age)));
	p3=1/(1+exp(-(gamma30+gamma31*white+gamma32*cd4+gamma33*age+gamma34*idu))); 
	p2=1/(1+exp(-(gamma20+gamma21*white+gamma22*cd4+gamma23*age+gamma24*delta)));
	sump=p4+p2+p3; 
	if sump>1 then sump=0.9990; *simple constraint;
	if pattern=1 then loglik=log(1-(sump));
		else if pattern=2 then loglik=log(p2);
		else if pattern=3 then loglik=log(p3);
		else if pattern=4 then loglik=log(p4);
	model pattern~general(loglik);
	ods select parameterestimates;
	ods output parameterestimates=gams(keep=parameter estimate);
	title "missing data model estimates";
proc transpose data=gams out=gams2 prefix=gam; *this makes the set of gamma horizontal;
data b2; set b; 
	if _N_=1 then set gams2; *this puts horisontal gammas on each record;
	if pattern=1 then do;
		p1=1-(
		1/(1+exp(-(gam1+gam4*white+gam5*cd4+gam6*age)))+
		1/(1+exp(-(gam2+gam7*white+gam8*cd4+gam9*age+gam10*idu)))+
		1/(1+exp(-(gam3+gam11*white+gam12*cd4+gam13*age+gam14*delta)))
		);
		w=1/p1; *the IP weight;
	end;
	else w=0;
proc means data=b2 maxdec=4; var p1 w; 
	title "Nonmonotonic IP weights, no constraint";
proc phreg data=b2 covs; 
	where pattern=1; 
	model t*delta(0)=idu white age cd4/rl; 
	weight w;
	ods select modelinfo censoredsummary parameterestimates;
	title "Nonmonotonic IP-weighted complete data, no constraint";
	*To implement the constraint try using proc mcmc;
	*To implement AIPW...;

run; quit; run;