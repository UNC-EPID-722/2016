

******************************************************
* IPTW analysis applied in NAMCS NSAID data
* Alan Brookhart
******************************************************;

libname a "x:\work\classes\Epid722-2016\Data\NAMCS\NSAID";

options nofmterr;


/*  compute prob of bleed from known model, simulate outcome using logistic regression  */

DATA ns;
   call streaminit(1235);
   SET a.nsaid008;
   pbleed=1/(1+exp(-(-6.75 + .6*contanticoag + 1*tobacco_imp + .5*contsteroids + 
                    .2*contaspirin + .7*arthrtis + .07*age + .3*male + 
                    .02*raceblkoth- .3*newcox2 )));
   bleed=rand("bernoulli",pbleed);   *simulate the observed outcome;
run;


/* explore data, table 1 */

proc means data=ns mean;
	class newcox2;
	var male arthrtis contsteroids contanticoag contaspirin tobacco_imp
				 raceblkoth age ;
run;



/* create propensity score model */

proc logistic data=ns descending;
class newcox2 year;
 model newcox2 = male arthrtis contsteroids contanticoag contaspirin tobacco_imp
				 raceblkoth age ;
 output out=ps_data predicted=ps;
run;


/* Creating PS treatment groups for plotting */

DATA ps_data;
	set ps_data;
	if newcox2 = 1 then treated_ps = ps;
		ELSE treated_ps = .;
	if newcox2 = 0 then untreated_ps = ps;
		else untreated_ps = .;
run;


/* Plot the overlap of the PS distributions by treatment group */

PROC KDE DATA=ps_data;
	UNIVAR untreated_ps treated_ps / PLOTS=densityoverlay;
	TITLE "Propensity score distributions by treatment group";
RUN;


/* compute inverse-probability of treatment weight and SMR weight */

data ps_data;
	set ps_data;
	if newcox2=1 then ps_exp=ps; else ps_unexp=ps;
	iptw=(newcox2/ps) + (1-newcox2)/(1-ps);
	smrw=newcox2+(1-newcox2)*ps/(1-ps);
run;


/* IPT weighted table 1 */

proc means data=ps_data mean;
	class newcox2;
	var male arthrtis contsteroids contanticoag contaspirin tobacco_imp
				 raceblkoth age ;
		weight iptw;
run;


/* SMR weighted table 1 */

proc means data=ps_data mean;
	class newcox2;
	var male arthrtis contsteroids contanticoag contaspirin tobacco_imp
				 raceblkoth age ;
		weight smrw;
run;


/* estimate causal risk difference in the population using IPT-weighted linear regression */

proc genmod data=ps_data desc;
	class patcode;
	model pud=newcox2 /dist=bin link=identity;
	repeated subject=patcode / corr=ind;
	weight iptw;
run;


/* estimate causal risk difference in the population using SMR-weighted linear regression */

proc genmod data=ps_data desc;
	class patcode;
	model pud=newcox2 /dist=bin link=identity;
	repeated subject=patcode / corr=ind;
	weight smrw;
run;
