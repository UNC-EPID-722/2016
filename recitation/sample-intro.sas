******************************************************************************************
* Program: sample-intro.sas
* Purpose: Show SAS code from EPID 700 R intro slides
* Input data: exdat.csv (simulated exdat data set from R)
* Output data: NA
*
* Date: 2016/01/24
* Authors: Code copied from EPID 700 Fall 2015 class by Xiaojuan Li (L25_R Data management.pdf)
******************************************************************************************; 

*
##@knitr sasread1
;
LIBNAME example "C:/temp";
filename dat1  "c:\temp\exdat.dbf";

proc import datafile=dat1 out=example.exdat dbms=dbf replace; run;

PROC PRINT DATA = example.exdat (OBS=10);
RUN; quit;


*
##@knitr section1
;
PROC CONTENTS DATA = example.exdat;
RUN; quit;


*
##@knitr section2
;
data exdata1; set example.exdat(drop=var1);*Could also use KEEP;
RUN;

* 
##@knitr section3
;
DATA exdata1;
SET example.exdat;
WHERE var1 >=10; *IF var1 >=10;
RUN;

* ##@knitr section4
;
DATA exdata1;
SET example.exdat;
FORMAT var4 var1 var2 var3;
RUN;

* 
##@knitr section5
;
PROC FREQ DATA = example.exdat;
TABLES var1;
TABLES var1*var2;
TABLES var1*var2*var3;
RUN;

* 
##@knitr section6
;
DATA exdat2;
SET exdata1;
IF var2 = "female" THEN var2n= "yes";
ELSE IF var2 = "male" THEN var2n= "no";
RUN;

*
##@knitr section7
;
DATA exdat2;
SET exdata1;
IF 0<var3 <=5 THEN var3class=1;
ELSE IF 5<var3 <=6 THEN var3class=2;
ELSE IF 6<var3 THEN var3class=3;
RUN;

*
##@knitr section8
;
PROC GENMOD DATA=example.exdat DESCENDING;
class var2;
MODEL var1=var2 var3/DIST=bin LINK=logit;
*ESTIMATE 'var2 label' var2 1/EXP;
RUN;

*
##@knitr section9
;
data example.exdat; set example.exdat; id=_n_; run;
PROC GENMOD DATA=example.exdat;
CLASS id var2;
MODEL var1=var2 var3/DIST=poisson LINK=log;
REPEATED SUBJECT=id/TYPE=ind;
*ESTIMATE 'var2 label' var2 1 /EXP;
RUN; quit;
