*program3.19jan16, maximum likelihood;

*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
%LET dir = D:\dropbox\Cole\Teaching\EPID722\2016;

*Read ASCII file;
data a;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;

*Simplify to a binary outcome, delta;
proc freq data=a; 
	tables idu*delta;
	title "Injection drug use by AIDS or death";

*ML by logistic;
proc logistic data=a desc; 
	model delta=idu;
	ods select modelinfo fitstatistics parameterestimates;
	title "ML by logistic procedure";

*ML by genmod;
proc genmod data=a desc; 
	model delta=idu/d=b;
	ods select modelinfo modelfit parameterestimates;
	title "ML by genmod procedure";

*ML by nlmixed;
proc nlmixed data=a; 
	parms b0 b1 0;
	mu=1/(1+exp(-(b0+b1*idu)));
	logl=delta*log(mu)+(1-delta)*log(1-mu);
	model delta~general(logl);
	ods select specifications fitstatistics parameterestimates;
	title "ML by nlmixed procedure";

*profile ML;
data b; 
	set a;
	do b1=0 to 1 by .02, .796442;
		b1idu=b1*idu;
		output;
	end;
proc sort data=b; 
	by b1;
run; ods select none; run; *Turn off output;
proc genmod data=b desc; 
	by b1;
	model delta=/d=b offset=b1idu;
	ods output modelfit=c;
run; ods select all; run; *Turn on output;
data d; 
	set c;
	by b1;
	logl=value;
	format logl stderr 10.4;
	if criterion='Log Likelihood' then output;
	keep b1 logl;

*plot profile loglikelihood;
ods listing gpath="&dir\";
ods graphics/reset imagename="profile" imagefmt=jpeg height=8in width=8in;
proc sgplot data=d;
	xaxis values=(0 to 1 by .2);
	series x=b1 y=logl;
	title "Profile loglikelihood for b1";

*approximate derivatives using cubic splines;
*EXPAND procedure converts measurements from one interval to another or interpolates missing values,
it is also a handy way to get numerical derivatives;
proc expand data=d out=e; convert logl=first/observed=(beginning,derivative); id b1;
proc expand data=e out=f; convert first=second/observed=(beginning,derivative); id b1;
data f; 
	set f;
	se=sqrt(1/-second);
proc print data=f noobs; 
	var b1 logl first second se;
	title "1st and 2nd approximate derivitives";

*penalized ML, laplace prior;
data a2;
	set a;
	m=0; *prior log OR;
	r=1/8; *prior precision;
	records=1164;
proc nlmixed data=a2; 
	parms b0 b1 0;
	mu=1/(1+exp(-(b0+b1*idu)));
	logl=(log(mu)*delta+log(1-mu)*(1-delta))-0.5*r*(b1-m)**2/records;
	model delta~general(logl);
	ods select specifications fitstatistics parameterestimates;
	title "Penalized ML, Laplace prior";
*NOTE: # records is needed because SAS applies the penalty to each record;
*WARNING: Disregard  generated  CI;

*penalized ML, near-dogmatic prior;
data a2;
	set a;
	m=0; *prior log OR;
	r=10000; *prior precision;
	records=1164;
proc nlmixed data=a2; 
	parms b0 b1 0;
	mu=1/(1+exp(-(b0+b1*idu)));
	logl=(log(mu)*delta+log(1-mu)*(1-delta))-0.5*r*(b1-m)**2/records;
	model delta~general(logl);
	ods select specifications fitstatistics parameterestimates;
	title "Penalized ML, near-dogmatic prior";
*NOTE: # records is needed because SAS applies the penalty to each record;
*WARNING: Disregard  generated  CI;

*Time permitting, try some other priors like in Table 2;
*Also, you can subset the data to make it sparse, then show how penalization helps (comparing against the full data);

run; quit; run;
