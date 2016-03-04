*program8.1feb16, IP-sampling-weighted Cox model;

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
	*Make age groups as seen in US data;
	if age<=29 then agegp=1;
	if 29<age<=39 then agegp=2;
	if 39<age<=49 then agegp=3;
	if 49<age then agegp=4;
	*Make indicator of being sampled;
	sample=1;
	*Make a pseudorecord weight;
	w=1;

*Look at data, again;
proc means data=a n mean sum min max; 
	var delta t drop idu white age cd4;
	title "Time from 12/6/95 to AIDS or death in WIHS";
proc freq data=a; 
	tables agegp;

*Crude Cox model, again;
proc phreg data=a;
	model t*delta(0)=idu/rl ties=efron;
	ods select modelinfo censoredsummary fitstatistics parameterestimates;
	title "Crude Cox model";

*Are demographics related to outcome?;
proc phreg data=a;
	class agegp/desc;
	model t*delta(0)=white agegp/rl ties=efron;
	ods select modelinfo censoredsummary fitstatistics parameterestimates;
	title "Demographics";

*Build IP-sampling weights, with US pop reference;
*Get and look at US data;
libname data "&dir\";
data us;
	set data.us(drop=w);
	sample=0;
	w=10**10;
	do i=1 to n; output; end;
	drop i;

*Restrict to females like WIHS;
data us; set us; where male=0;
proc means data=us;	title "US CDC data";
proc freq data=us; tables white*agegp;

*Combine WIHS sample data with US data;
data b; set a us; 
proc freq data=b;
	tables (white agegp)*sample;
	title "Sample and US data combined";

*Model for numerator;
proc logistic data=b desc noprint;
	model sample=;
	weight w;
	output out=sn(keep=id snum) p=snum; 

*Model for denominator (are demographics related to sampling?);
proc logistic data=b desc;
	class agegp/desc;
	model sample=white agegp white*agegp;
	weight w;
	output out=sd(keep=id sden sample) p=sden;
	ods select modelinfo responseprofile parameterestimates oddsratios;
	title "Probability of being sampled";
proc sort data=sn; by id; 
proc sort data=sd; by id;
proc sort data=b; by id;

*Make sampling weights;
data c;
	merge b sn sd;
	by id;
	samplew=snum/sden;
	label snum= sden=;
data c; set c; if sample=1;
proc means data=c fw=8 maxdec=3 n mean std min max sum;
	var snum sden samplew;
	title "Sampling weights";

*Weighted Cox model;
proc phreg data=c covs(aggregate);
	id id;
	weight samplew;
	model t*delta(0)=idu/rl ties=efron; 
	ods select modelinfo censoredsummary parameterestimates;
	title "Sampling weighted Cox model"; 

*Sampling-weighted survival curves;
proc phreg data=c noprint; 
	model t*delta(0)=;
	weight samplew;
	strata idu;
	baseline out=d survival=s/method=na;
data d; set d; r=1-s;
proc sort data=d; by idu t;	
ods listing gpath="&dir";
ods graphics/reset imagename="Sampling Survival" imagefmt=jpeg height=8in width=8in;
proc sgplot data=d noautolegend;
	title "IP-sampling-weighted risk";	
	yaxis values=(0 to 1 by .2);
	xaxis values=(0 to 10 by 2);
	step x=t y=r/group=idu;

run; quit; run;
*What if you also adjusted for confounding by regression or IP weights?;
*What if you just generalized wrt age?;
