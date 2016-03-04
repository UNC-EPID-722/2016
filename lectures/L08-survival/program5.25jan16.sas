*program5.25jan16, Survival;

*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
*%let dir = D:\dropbox\Cole\Teaching\EPID722\2016;
%let dir = Y:\Cole\Teaching\EPID722\2016;

*Read ASCII file, adin censor at 1/2 year to ease exposition;
data a;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;
	if t>.5 then do; t=.5; delta=0; end;

*Data;
proc means data=a n mean sum min max; 
	var delta t;
	title "Time from 12/6/95 to AIDS or death in WIHS";

*Product limit survival curve data;
proc phreg data=a noprint;
	model t*delta(0)=;
	baseline out=b survival=s stderr=se/method=pl; *output survival function and se;
	output out=c(keep=t n) atrisk=n/method=pl; *output numbers in risk sets;
proc sort data=c nodups; by t; *order times;
data c; set c; by t; if first.t; *keep distinct times;
data d; merge b c; by t; if t=0 then n=1164; if s>.; *merge keeping event times;
data d;
	set d;
	r=1-s;
	se2=s*sqrt((1-s)/n); *Peto se;
	if r>0 then do;
		lo=max(0,r-1.96*se);
		hi=min(1,r+1.96*se);
	end;
	label s="Survival" r="Risk" t="Years";
proc print data=d noobs;
	var t n r s se se2;
	
*Plot;
ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Survival" imagefmt=jpeg height=8in width=8in;
proc sgplot data=d noautolegend;
	yaxis values=(0 to .1 by .02);
	xaxis values=(0 to .5 by .1);
	step x=t y=r/lineattrs=(color=black);
	step x=t y=lo/lineattrs=(color=black pattern=dot);
	step x=t y=hi/lineattrs=(color=black pattern=dot);

*Some other pieces;
proc sort data=d; 
	by descending s;
data d; 
	set d; 
	by descending s;
	retain chm1 0 sm1 1 tm1 0;
	if t=0 then do; d=0; *n=315; end;
	deltat=t-tm1; 
	if s>0 then ch=-log(s);
	y=round((ch-chm1)*n,1);	
	*above recreates y because SAS does not output;
	if deltat>0 then h=y/(n*deltat);
	label n=;
	logh=log(h);
	output;
	chm1=ch; sm1=s; tm1=t;
	drop chm1 sm1 tm1;
proc print data=d noobs; 
	title2 "Hazard function";
	var t y n deltat h;

ods listing gpath="Y:\Cole\Teaching\EPID722\2016\";
ods graphics/reset imagename="Hazard" imagefmt=jpeg height=8in width=8in;
proc sgplot data=d noautolegend;
	xaxis values=(0 to .5 by .1);
	loess x=t y=h/smooth=.6;
	pbspline x=t y=h/lineattrs=(color=red) nomarkers;

data d; 
	set d;
	by descending s;
	retain v 0;
	v=v+y/(n*(n-y));
	se3=sqrt(s**2*v); *se by hand;
	ch=-log(s);
	output;
proc print data=d noobs; 
	title2 "Standard error by hand";
	var t ch s se se3;

/*IML code;
proc iml;
	use d;
	read all var {s t y n} into r;
	s=r[,1]; t=r[,2]; y=r[,3]; n=r[,4];
	se3=sqrt(s##2#cusum(y/(n#(n-y))));
	print t s y n se3;
*/

*If we remove all nonevents, what is the value of the jumps/masses in the survival curve (i.e., the step sizes), and why?;
*Make the curve for 10 years instead of 1/2 year;
run; quit; run;
