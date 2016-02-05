*Set some options;
options nocenter pagesize=60 linesize=80 nodate pageno=1;

*Set log and output to clear on each run;
dm log "clear;" continue; dm out "clear;" continue;

*Set a directory pointer;
*%LET dir = D:\dropbox\Cole\Teaching\EPID722\2016;
%let dir=c:\temp;

*Read excel data file;
proc import out=a datafile="&dir\hividu.csv" dbms=csv replace; getnames=yes;

*Make new random id;
data a; set a; 
	call streaminit(123);
	u=rand("uniform");
proc sort data=a; by u;

*Rename variables;
data b; set a; by u;
	if eventtype=0 then do; delta=0; t=t; art=.; end; *Censored w/out ART;
	if eventtype=1 and dth=0 then do; delta=0; t=taidsdth; art=tarv; end; *Censored w/ART;
	if eventtype=1 and dth=1 then do; delta=1; t=taidsdth; art=tarv; end; *Event (AIDS or death) w/ART;
	if eventtype=2 and arv=0 then do; delta=1; t=taidsdth; art=.; end; *Event w/out ART;
	if eventtype=2 and arv=1 then do; delta=1; t=taidsdth; art=.; end; *Event w/out ART, ART was after AIDS;
	if t>10 then do; *Admin censor at 10 years;
		t=10; delta=0;
		if art>10 then art=.;
	end;
	if t<10 and delta=0 then drop=1; else drop=0;
	id=_n_;
	idu=baseidu;
	white=1-black;
	age=ageatfda;
	cd4=cd4nadir;
	art=round(art,.001); *Round times to .001 of a year, or about 8h;
	t=round(t,.001);
	keep id idu white age cd4 drop delta art t;

*Save as flat ASCII file;
data _null_; set b;
	file "&dir\hividu15dec15.dat"; 
	put id 1-4 idu 6 white 8 age 10-11 cd4 13-16 drop 18 delta 20 @22 art 6.3 @29 t 6.3;

* Export so I can read in R. Important if I want to compare ids;
proc export data=b 
   outfile='c:\temp\hividu15dec15.csv'
   dbms=csv
   replace;
run;

/**************
** CODEBOOK

**
** id = random patient id
** idu = indicator of injection drug use
** white = indicator of being caucasian
** age = age in years on 12/6/1995
** cd4 = nadir cd4 cell count in units of cells per mm^3 by 12/6/1995
** drop = indicator of loss to follow up before 10 years
** delta = indicator of AIDS or death during 10 year follow up
** art = time at which patient started antiretroviral therapy in units of decimal years
** t = time under follow up in units of decimal years from 12/6/1995
****************/

run; quit; run;
