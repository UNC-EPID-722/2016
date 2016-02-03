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
run;

*First 20 records;
proc print data=a(obs=20) noobs; 
	var id idu white age cd4 art drop delta t;
	title "First 20 records, WIHS IDU data";

*Table 1, continuous;
proc sort data=a; by idu;
proc means data=a n median q1 q3 maxdec=1; by idu; 
	var age cd4;
	title "Table 1, continuous variables, by IDU";
proc means data=a n median q1 q3 maxdec=1;
	var age cd4;
	title "Table 1, continuous variables, overall";

*Table 1, categorical;
proc freq data=a; 
	tables white*idu/norow nopercent;
	title "Table 1, categorical variables, by IDU";
proc freq data=a; 
	tables white;
	title "Table 1, categorical variables, overall";

*Table 2, disposition;
proc freq; tables delta*drop; title "Table 2, disposition";

run; quit; run;
