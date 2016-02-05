*program4.19jan16, Bayes;

*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
*%let dir = D:\dropbox\Cole\Teaching\EPID722\2016;
%let dir = c:\temp;

/* 
THIS is extra code in the bayes.Rmd file.
libname mle "c:\temp";
%let dir = c:\temp;

*Read ASCII file;
data mle.b;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;
run;
*/

*Read ASCII file;
data a;
	infile "&dir\hividu15dec15.dat"; 
	input id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;

*Simplify to a binary outcome, delta;
proc freq data=a; 
	tables idu*delta;
	title "Injection drug use by AIDS or death";

*ML by genmod;
proc genmod data=a desc;
	model delta=idu/d=b;
	ods select modelinfo modelfit parameterestimates;
	title "ML by genmod procedure";

*Bayes by data augmentation, normal prior on b1, prior 95% CI 1/2, 2;
data priorb1;
	int=0;
	or=exp(0);
	v=.3536**2;
	f=400; *f=2/v*s**2; *f set large to ensure asymptotics;
	s=sqrt(f/(2/v));
	pair=1; idu=1/s; delta=1; offset=-log(or)/s; output; idu=0; delta=0; offset=0; output;
	pair=2; idu=0; delta=1; offset=0; output; idu=1/s; delta=0; offset=-log(or)/s; output;
	run;
	proc print data=priorb1; run;
	proc contents data=priorb1; run;

proc genmod data=priorb1 desc; 
	freq f;
	model delta=int idu/d=b noint offset=offset;
	ods select modelinfo modelfit parameterestimates;
	title "Prior for b1 by data augmentation";
	run;

data a; 
	set a;
	int=1;
	f=1;
	offset=0;
data both; 
	set a priorb1;
	run;
proc print data=both(firstobs=1160 obs=1168); run;

proc genmod data=both desc; 
	freq f;
	model delta=int idu/d=b noint offset=offset;
	ods select modelinfo modelfit parameterestimates;
	title "Posterior for b1 by data augmentation";
run;

* Note: the following part is set up to output to an html file I will read in to the R markdown file, 'bayes.Rmd', in R.
* See http://support.sas.com/kb/49/421.html for tips on setting up for html output;

ods listing gpath='c:\temp';

ods _all_ close;
ods html path='c:\temp\' body='bayes-sas.html' style=HTMLBlue; * get html file to put into R markdown file, bayes.Rmd;

ods graphics on;

*Bayes by MCMC;
data priors;
	input _type_ $ _name_:$9. Intercept idu;
	cards;
	mean . 0   0
	cov  Intercept 100 0
	cov  idu	   0   0.125
;
run;
proc print data=priors; run;

*ods listing gpath="c:\temp\";
*ods graphics on / reset=all imagename="Trace" imagefmt=jpeg height=8in width=8in;
proc genmod data=a desc; 
	model delta=idu/d=b;
	bayes seed=1234 nbi=500 nmc=2000 coeffprior=normal(input=priors);
	ods select modelinfo postsummaries tadpanel;
	ods output posteriorsample=post(keep=iteration idu);
	title "Bayes by genmod procedure";

*What is the probabuility that OR>1?;

	data post2; set post; if exp(idu)>1 then por=1; else por=0; run;
	proc means data=post2; var iteration idu por; run; * Note: all draws have exp(idu) greater than 1;

* Next try exp(idu)>2; * that is around 0.55;
	
	data post3; set post; if exp(idu)>2 then por=1; else por=0; run;
	proc means data=post3; var iteration idu por; run; * Note: all draws have exp(idu) greater than 1;
	
*What strength of null-prior would make this association not statistically significant?;
*What strength of null-prior would make this point estimate not larger than 1.2?;
*I did not include Bayes by rejection sampling, why not?;
run; quit; run;
*For some reason I am getting 2 copies of the TAD panels, and the HTML viewer is turning on?!?;

ods _all_ close;
ods listing;

