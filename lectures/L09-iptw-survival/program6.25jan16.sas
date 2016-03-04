*program6.25jan16, IP-weighted survival;

*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
*%let dir = D:\dropbox\Cole\Teaching\EPID722\2016;
%let dir = Y:\Cole\Teaching\EPID722\2016;

*Read ASCII file;
data a;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;
	
*Look at data;
proc means data=a n mean sum min max; 
	var delta t drop idu white age cd4;
	title "Time from 12/6/95 to AIDS or death in WIHS";

*Crude curves, by product limit aka KM;
proc phreg data=a noprint;
	model t*delta(0)=;
	strata idu;
	baseline out=b survival=s/method=pl;
data b;
	set b;
	r=1-s;
	label s="Survival" r="Risk" t="Years";
	title1 "Survival curves by injection drug use";
	title2 "Crude";
*Plot;
ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Crude_km_curves" imagefmt=jpeg height=8in width=8in;
proc sgplot data=b noautolegend;
	yaxis values=(0 to .8 by .2);
	xaxis values=(0 to 10 by 2);
	step x=t y=r/group=idu;

*Crude curves, by Nelson-Aalen (asymptotically equal, need below);
proc phreg data=a noprint;
	model t*delta(0)=;
	strata idu;
	baseline out=b survival=s/method=na;
data b;
	set b;
	r=1-s;
	label s="Survival" r="Risk" t="Years";
	title1 "Survival curves by injection drug use";
	title2 "Crude";
*Plot;
ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Crude_na_curves" imagefmt=jpeg height=8in width=8in;
proc sgplot data=b noautolegend;
	yaxis values=(0 to .8 by .2);
	xaxis values=(0 to 10 by 2);
	step x=t y=r/group=idu;

****IP confounding weights;

*Model for numerator of weights, to stabilize variance;
proc logistic data=a desc noprint; 
	model idu=; 
	output out=n p=n;

*Model for denominator of weights, to control confounding;
proc logistic data=a desc noprint; 
	model idu=white age cd4; 
	output out=d p=d;

*Construct weights;
data c;
	merge a n d;
	if idu then w=n/d;
	else w=(1-n)/(1-d);
	label n= d=;
	drop _level_;
proc means data=c;
	var n d w;
	title "IP confounding weights";

*IP-confounding weighted curves;
proc phreg data=c noprint;
	model t*delta(0)=;
	strata idu;
	weight w;
	baseline out=b2 survival=s/method=na; *Use NA, bc SAS wont give KM with weight statement;
data b2;
	set b2;
	r=1-s;
	label s="Survival" r="Risk" t="Years";
	title1 "Survival curves by injection drug use";
	title2 "Weighted for baseline confounding";
	
*Plot;
ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Weighted_curves" imagefmt=jpeg height=8in width=8in;
proc sgplot data=b2 noautolegend;
	yaxis values=(0 to .8 by .2);
	xaxis values=(0 to 10 by 2);
	step x=t y=r/group=idu;

****IP-censoring weights;

*Add a constant for merging;
data c; set c; retain z 1;

*Grab quintiles of the observed drop out times to merge with data;
proc univariate data=c noprint;
	where drop=1; var t;
	output out=q pctlpts=20 40 60 80 pctlpre=p;
data q; set q; p0=0; p100=10; z=1;
proc print data=q noobs; 
	var p0 p20 p40 p60 p80 p100;
	title "Quantiles of the drop out distribution";

*Expand data to up to 5 records per unit;
data e; merge c q; by z;
	array j{6} p0 p20 p40 p60 p80 p100;
	do k=1 to 5;
		in=j(k);
		if j(k)<t<=j(k+1) then do; 
			out=t; 
			delta2=delta; *make a time-varying event indicator;
			_drop=drop; *make a time-varying drop indicator;
			output; 
		end;
		else if j(k+1)<t then do; out=j(k+1); delta2=0; _drop=0; output; end;
	end;
proc sort data=e; by id in;

*drop-out numerator model;
proc logistic data=e noprint; 
	class in/param=ref desc; 
	model _drop=in;
	output out=nm2(keep=id _drop nm2 in out) prob=nm2;
*drop-out denominator model;
proc logistic data=e noprint; 	
	class in/param=ref desc; 
	model _drop=in idu white age cd4;
	output out=dn2(keep=id _drop dn2 in out) prob=dn2;
*drop-out weights;
proc sort data=nm2; by id in; 
proc sort data=dn2; by id in; 
data f; merge e nm2 dn2; by id in; retain num den;
	if first.id then do; num=1; den=1; end;
	num=num*nm2;
	den=den*dn2;
	if _drop then w2=(1-num)/(1-den); else w2=num/den;
	w3=w*w2;
	label nm2= dn2=;
proc means data=f; 
	var w w2 w3 num den;
	title "Weights";

proc print data=f(obs=100) noobs; 
	var id in out t delta drop _drop num den w2;
	title "Data expanded for drop out quintiles";

*IP-confounding-and-drop-out weighted curves;
proc phreg data=f noprint;
	model (in,out)*delta2(0)=;
	strata idu;
	weight w3;
	baseline out=b3 survival=s/method=na; *SAS wont give KM with weight statement;
data b3;
	set b3;
	r=1-s;
	label s="Survival" r="Risk" out="Years";
	title1 "Survival curves by injection drug use";
	title2 "Weighted for baseline confounding and drop out";

*Plot;
ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Weighted2_curves" imagefmt=jpeg height=8in width=8in;
proc sgplot data=b3 noautolegend;
	yaxis values=(0 to .8 by .2);
	xaxis values=(0 to 10 by 2);
	step x=out y=r/group=idu;

run; quit; run;
