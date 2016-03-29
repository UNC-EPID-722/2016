*************************************************************
* PROJECT: 			EPID 722 class project
* Task:				Read in class data
* Investigator: 	
* Programmer: 		
* Created on:   	2015/12
* Last Revision: 	2016/03/21
* Program:      	sas-read-url.sas
* Output data:		temp data set, dat1
* Note:				reading url in SAS 9.3 does not work with proc import
*************************************************************;

/*
* Note: this does not run for SAS 9.3. Works in SAS 9.4
proc import datafile=dat1
     out=dat1
     dbms=csv
     replace;
     getnames=yes;
run;
*/

filename dat1 url "http://epid722.web.unc.edu/files/2015/11/namcs-class-2016.csv";

      data WORK.DAT1;
      infile DAT1 delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
      input
                  YEAR
                  patcode
                  AGE
                  male
                  DIABETES
                  HYPLIPID
                  HTN
                  newusercat
                  newuser
                  white
                  obese
                  dbp
                  sbp
                  smoke
                  t
                  delta 
      ;
      run;
      
proc format;
value newuser	0 = 'not a new user' 1 = 'new user';
value newusercat 0 = 'not a new user' 1 = 'low potency statin' 2 = 'high potency statin';
value delta 0 = 'Administratively censored at 10 years'
	1 = 'Hospitalization for CVD'
	2 = 'All-cause mortality'
	3 = 'Loss to follow-up';
value diabetes	0 = 'Does not have diabetes' 1 = 'Has diabetes';
value htn 0 = 'Does not have hypertension' 1 = 'Has hypertension';
value hyplipid 0 = 'Does not have hyperlipidemia' 1 = 'Has hyperlipidemia';
value white 0 = 'Black/other' 1 = 'White';
value male 0 = 'Female/other' 1 = 'Male';
value obese 0 = 'Not obese' 1 = 'Obese';
value smoke 0 ='not a current smoker' 1 = 'current smoker';
run;

data dat1; set dat1;
label 
patcode = 'Patient code'
newuser = 'New statin user'
newusercat = 'New user, stratifying potency'
t = 'Observed time, in years'
delta = 'Outcome status'
diabetes = 'Current diabetes status'
htn = 'Hypertension status'
hyplipid = 'Current hyperlipidemia status'
white = 'Race'
year = 'Calendar year of study entry'
male = 'Gender'
obese = 'Obesity status'
age = 'Patient age, in years'
smoke = 'Current tobacco smoking status'
dbp = 'Diastolic blood pressure'
sbp = 'Systolic blood pressure'
;
format newuser newuser. newusercat newusercat. delta delta. diabetes diabetes.
htn htn. hyplipid hyplipid. white white. male male. obese obese. smoke smoke.;
run; quit;

