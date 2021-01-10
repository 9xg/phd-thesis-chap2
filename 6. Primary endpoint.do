version 15
log using "6", replace

********************************************************************************
* CALCULATE VIF and WEIGHTED AVERAGE FOLLOW-UP
********************************************************************************

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CODED_SEARCH_CRF.dta", ///
	clear

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("Power") modify
***

* Compare Baseline and Endpoint dates with Beth's spreadsheet
merge 1:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/FUspreadsheet.dta"
// ok, 2 sites not matched because still missing from CODED SEARCH CRF

drop _merge
format Datesitepassed %tdDD/NN/CCYY
format Followupperiod %tdDD/NN/CCYY

br if BaselineDate != Datesitepassed
// List copied and pasted --> queried with Beth (03/01)

br if EndpointDate != Followupperiod
// Same date in some cases!
format Followupperiod %9.0g
format EndpointDate %9.0g
gen EndDate = floor(Followupperiod)
drop Followupperiod
format EndDate %tdDD/NN/CCYY
format EndpointDate %tdDD/NN/CCYY
br if EndpointDate != EndDate

gen FUmonths = round(FUmths, 1)
br if FUmonths != Numberofmonths
// no differences in FU

merge 1:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SiteArm.dta"

keep Site FUdays RandGroup StudyArm Size

********
* Calculate VIF by stratum for CLR group

summ Size if RandGroup == 0
// range: 50-200
gen Stratum = 0 if Size <= 65 & RandGroup == 0
replace Stratum = 1 if Size > 65 & Size <= 90 & RandGroup == 0
replace Stratum = 2 if Size > 90 & Size <= 125 & RandGroup == 0
replace Stratum = 3 if Size > 125 & Size <= 175 & RandGroup == 0
replace Stratum = 4 if Size > 175 & Size <. & RandGroup == 0
label define Stratum 0 "<= 65" 1 "66-90" 2 "91-125" 3 "126-175" 4 "176+"
label values Stratum Stratum
tab Stratum, matcell(A)
putexcel B2 = matrix(A)

sort Stratum Size

* tot
bysort Stratum: egen StratumSize = sum(Size) if Stratum < .
egen SizeTot = sum(Size) if Stratum < .

* k
bysort Stratum: gen StratumK = _N if Stratum < .
tab Stratum StratumK, m
// OK

* mean
bysort Stratum: egen StratumMean = mean(Size) if Stratum < .

* SD
bysort Stratum: egen StratumSD = sd(Size) if Stratum < .

* CV^2
gen StratumCV2 = (StratumSD/StratumMean)^2 if Stratum < .

* VIF
gen StratumVIF = 1 + (((StratumCV2 * (StratumK - 1)/StratumK + 1)*StratumMean) - 1)* 0.025 ///
	if Stratum < .
// ICC = 0.025 pre-defined

* Equivalent size
gen StratumEquiv = StratumSize/StratumVIF if Stratum < .

* Total equivalent size
bysort Stratum: gen counter = _n if Stratum < .
bysort Stratum: gen temp = StratumEquiv if counter == _N
egen EquivTot = total(temp)

* VIF
gen VIF = SizeTot/EquivTot
// VIF = 3.7

********
* Weighted average follow-up

gen FUyr = FUdays/365.25
replace StratumVIF = 1 if StratumVIF == .
gen EquiFUSize = (FUyr * Size)/StratumVIF
egen AvgFU = sum(EquiFUSize)
// 7433.088 > 6740 sample size
// Good!

*** EXPORT
keep Stratum-StratumEquiv EquivTot VIF AvgFU

duplicates drop
replace Stratum = 6 if Stratum == .
label define Stratum 6 "PLR", modify

***
export excel using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("Power") sheetmodify firstrow(variables) keepcellfmt
***

********************************************************************************
* COUNTING/PREPARE DATASET FOR PRIMARY ENDPOINT ANALYSIS
********************************************************************************
use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT_clean.dta", ///
	clear

* Baseline date
count if BASELINE_DATA_LOGGED_DATE == ""
// 170 missing --> to be fixed directly in the database
gen temp = substr(BASELINE_DATA_LOGGED_DATE, 1, 9)
gen BaseDate = date(temp, "DM20Y")
format BaseDate %tdDD/NN/CCYY
drop temp BASELINE_DATA_LOGGED_DATE

* Fix missing baseline dates
sort Site BaseDate
bysort Site: replace BaseDate = BaseDate[1] if BaseDate == .
tab Site if BaseDate == .
// this site does not have a BaselineDate yet
label var BaseDate BEST3_PATIENT

* Research endoscopy schedule date (not date endoscopy performed)
gen ResEndScheduled = 0
replace ResEndScheduled = 1 if R_END_SCHEDULE_DATE != ""
label define resend 0 "No res. end. scheduled" 1 "Res. end. scheduled"
label values ResEndScheduled resend
tab ResEndScheduled, m
// 131
tab STUDY_ARM ResEndScheduled, m

keep PATIENT_ID Site STUDY_ARM BaseDate ResEndScheduled

* Add CLR/PLR
merge m:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SiteArm.dta"

tab StudyArm STUDY_ARM
drop _merge Size StudyArm

tab RandGroup, m
label var RandGroup "CLR/PLR"

gen StudyArm = 0 if STUDY_ARM == "U"
replace StudyArm = 1 if STUDY_ARM == "I"
label define Armlab 0 "Usual care" 1 "Intervention"
label values StudyArm Armlab
tab StudyArm
drop STUDY_ARM
label var StudyArm "Usual/Intervention"

* Add Cytosponge result
merge m:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF_final.dta"
drop CRF_ID-exclude
drop _merge

tab CytoResult StudyArm
gen PatientType = 0 if StudyArm == 0
replace PatientType = 1 if StudyArm == 1
replace PatientType = 2 if StudyArm == 1 & ///
	(CytoResult == 0 | CytoResult == 1 | CytoResult == 2 | CytoResult == 3)
replace PatientType = 3 if StudyArm == 1 & ///
	(CytoResult == 4 | CytoResult == 5)
label define typelab 0 "Usual care" ///
	1 "Non-responder/non-attender/unsuccessful swallow" ///
	2 "Negative/Equivocal" ///
	3 "Positive"
label values PatientType typelab
tab PatientType, m

*** MERGE WITH CODED SEARCH CRF
merge m:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CODED_SEARCH_CRF.dta"
drop _merge

drop CRF_ID-LAST_UPDATED_BY FUdays-_merge
label var BaselineDate "CODED_SEARCH_CRF"
label var EndpointDate "CODED_SEARCH_CRF"

rename PATIENT_ID PatientID

*** MERGE WITH BE/CANCER DIAGNOSES
merge m:m PatientID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryBE.dta"

replace PrimaryEndpt = 0 if PrimaryEndpt == .
tab PrimaryEndpt StudyArm, m

drop _merge

*** MERGE WITH ENDOSCOPY DATES
merge m:1 PatientID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/EndoscopyDate.dta"
drop _merge

*** CHECK ENDOSCOPY DATES WITH RESEARCH ENDOSCOPY DATES
tab ResEndScheduled if EndoscopyDate != .
// 115 research endoscopy performed
gen ResEndDate = EndoscopyDate if ResEndScheduled == 1
format ResEndDate %tdDD/NN/CCYY
count if ResEndDate != .
// 115: OK
replace EndoscopyDate = . if ResEndScheduled == 1

drop ResEndScheduled

*** TO DO:
// Which one to rely on? BaseDate or BaselineDate?
// Also check EndpointDate with Beth's spreadsheet
// Do we have BE diagnoses dates? If so, merge them to this dataset

********************************************************************************
* PRIMARY ENDPOINT ANALYSIS

**********************************************************************
*** NOTE: If we want to include only BEs in primary endpoint analysis,
*** use this line of code before running the rest:
replace PrimaryEndpt = 0 if DiagDetail >= 5 & DiagDetail < .
**********************************************************************

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("PrimaryEndpoint") modify
***

tab Site, m
tab StudyArm, m
tab RandGroup, m
tab PrimaryEndpt, m

tab RandGroup StudyArm if PrimaryEndpt == 1, matcell(A)
// 145 BEs/OACs in intervention, 18 BEs/OACs in usual care
matrix rownames A = "CLR" "PLR"
matrix colnames A = "Usual care" "Intervention"
putexcel A1 = matrix(A), names

* TO DO: decide which one is the right EndpointDate
* TO DO: define right baseline dates
* TO DO: update dataset with 2 missing sites

count if EndoscopyDate < .
// 231 Trial endoscopies
tab PrimaryEndpt if EndoscopyDate < .
// 120 trial BEs/OACs
tab PrimaryEndpt if EndoscopyDate == .
// 43 BEs/OACs do not have Trial Endoscopy date
tab StudyArm if PrimaryEndpt == 1 & EndoscopyDate == .
// 18 of these are usual care, 25 intervention
tab RandGroup if StudyArm == 1 & PrimaryEndpt == 1 & EndoscopyDate == .
// probably negative Cytosponges or non-responders

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("Diagnoses") modify
***

tab PatientType StudyArm if PrimaryEndpt == 1
tab DiagDetail PatientType if PrimaryEndpt == 1 | DiagDetail == 0 ///
	| (DiagDetail >= 5 & DiagDetail < .), m matcell(A)
// IMPORTANT: if using only BEs in primary endpoint analysis, the line above
// should be uncommented
putexcel B3 = matrix(A)

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("PrimaryEndpoint") modify
***

*** DEFINE END DATES OF FU

tab Site if EndpointDate == .
// 0: OK
// drop if EndpointDate == .

* Site's FU
gen FUmonths = (EndpointDate - BaselineDate)/30.4375
tabstat FUmonths, s(min max) save
putexcel B22 = matrix(r(StatTotal)')

* 1) In general, set end date = EndpointDate
gen EndDate = EndpointDate

* 2) BE diagnoses within the Trial: end date = date of endoscopy
count if PrimaryEndpt == 1 & EndoscopyDate > EndpointDate & EndoscopyDate < .
// 0: OK
replace EndDate = min(EndDate, EndoscopyDate) if PrimaryEndpt == 1

* 3) BE diagnoses outside the Trial = end date = halfway through FU
replace EndDate = (BaselineDate + EndDate)/2 if PrimaryEndpt == 1 ///
	& EndoscopyDate == .

* 4) Research endoscopies before end of follow-up: end date = research endoscopy - 1
replace EndDate = ResEndDate - 1 if ResEndDate <= EndpointDate & EndpointDate < .

format EndDate %tdDD/NN/CCYY
label var EndDate "End of FU"
summ EndDate, de format
// July 2017 to November 2019

*** CALCULATE LENGTH OF FU
// TO DO: copy and fix weighted average FU into this file

gen FUdays = EndDate - BaselineDate
summ FUdays, de
// 46 to 548
count if FUdays < 120
// 66 have less than 120 days of FU
count if EndoscopyDate < . & FUdays < 120
// OK: 66. These are all patients who had a BE/OAC diagnosed within the Trial

gen FUyears = FUdays/365.25
summ FUyears, de
// 0.1 to 1.5 years of FU

*** CRUDE ESTIMATE OF RATE RATIOS
* NOT ADJUSTING FOR 4 MONTHS CUT-OFF IN INTERVENTION ARM
ir PrimaryEndpt StudyArm FUyear
ir PrimaryEndpt StudyArm FUyear, by(Site)

*** CALCULATE RATES OF FU OUT OF 1000 PERSON-YEARS

* USUAL CARE ARM (this gives the same results as the rate ratio calculated above)

* Follow-up
sort StudyArm
bysort StudyArm: egen FUarm = total(FUyears)
replace FUarm = FUarm/1000
tab FUarm
// 6.497632 1000 person-years for usual care arm
tabstat FUarm, by(StudyArm) save
return list
matrix A = r(Stat1)
matrix B = r(Stat2)
putexcel B8 = matrix(A)
putexcel C8 = matrix(B)

* Number of BEs/EACs
bysort StudyArm: egen BEcount = total(PrimaryEndpt)
tab BEcount if StudyArm == 0
// 18 BEs

* Rate
gen BErate = BEcount/FUarm
tab BErate
// rate: 2.77

replace FUarm = . if StudyArm == 1
replace BEcount = . if StudyArm == 1
replace BErate = . if StudyArm == 1

tab BErate, matcell(A)
putexcel B9 = BErate

* INTERVENTION ARM

* A) UP TO 4 MONTHS
* --> TO DO: use right BaselineDate

* Generate cut-off date after 4 months
gen CutOff4 = ceil(BaselineDate + 4*30.44) if StudyArm == 1 // adding 122 days = 4 months
format CutOff4 %tdDD/NN/CCYY

count if EndDate <= CutOff4 & StudyArm == 1
// 71 obs
summ FUdays if EndDate <= CutOff4 & StudyArm == 1
// FU: <= 122 days --> OK
summ FUdays if EndDate > CutOff4 & StudyArm == 1
// FU: > 122 days --> OK

replace CutOff4 = EndDate if EndDate <= CutOff4 & StudyArm == 1
// 68 changes

gen FU4 = (CutOff4 - BaselineDate) if StudyArm == 1
summ FU4, de
// 46-122
gen FU4years = FU4/365.25 if StudyArm == 1
summ FU4years, de
// 0.1-0.3 years

egen FU4arm = total(FU4years) if StudyArm == 1
replace FU4arm = FU4arm/1000
tab FU4arm if StudyArm == 1
// 2.23 1000 person-years for intervention arm up to 4 months
tabstat FU4arm, save
return list
matrix A = r(StatTotal)
putexcel D8 = matrix(A)

* Number of BEs
egen BE4count = total(PrimaryEndpt) if EndDate <= CutOff4 & StudyArm == 1
tab BE4count if StudyArm == 1
// 71 BEs/EACs
sort StudyArm BE4count
bysort StudyArm: replace BE4count = BE4count[1] if StudyArm == 1

* Rate: intervention arm up to 4 months
gen BE4rate = BE4count/FU4arm
tab BE4rate
// rate: 31.7
tabstat BE4rate, save
return list
matrix A = r(StatTotal)
putexcel D9 = matrix(A)

* B) AFTER 4 MONTHS

gen FU12 = EndDate - CutOff4 if EndDate > CutOff4 & StudyArm == 1
summ FU12, de
// 2-366 days
gen FU12years = FU12/365.25 if StudyArm == 1
summ FU12years, de
// 0.01-1.0 years

egen FU12arm = total(FU12years) if StudyArm == 1
replace FU12arm = FU12arm/1000
tab FU12arm if StudyArm == 1
// 4.6 1000 person-years for intervention arm after 4 months
tabstat FU12arm, save
return list
matrix A = r(StatTotal)
putexcel E8 = matrix(A)

* Number of BEs
egen BE12count = total(PrimaryEndpt) if EndDate > CutOff4 & StudyArm == 1
tab BE12count if StudyArm == 1
// 70 BEs/EACs
sort StudyArm BE12count
bysort StudyArm: replace BE12count = BE12count[1] if StudyArm == 1

* Rate: intervention arm after 4 months
gen BE12rate = BE12count/FU12arm
tab BE12rate
// rate: 15.1
tabstat BE12rate, save
return list
matrix A = r(StatTotal)
putexcel E9 = matrix(A)

* C) WEIGHTED AVERAGE RATE FOR INTERVENTION ARM ON 12 MONTHS
gen avgBErate = (BE4rate + 2*BE12rate)/3
tab avgBErate
// average rate for intervention arm: 20.6
tabstat avgBErate, save
return list
matrix A = r(StatTotal)
putexcel C9 = matrix(A)

********************************************************************************
*** UNADJUSTED ANALYSIS
*** 1) CLR group - individual-level data
*** 2) CLR group - cluster-level data
*** 3) Permutation test
*** 4) PLR group
*** 5) Combined analysis: CLR+PLR group

* Define size
bysort Site : gen Size = _N
tab Site
duplicates examples Site Size

* 1) CLR group - individual-level data

tab RandGroup, m
// 7841

* Define strata
summ Size if RandGroup == 0
// range: 48-198
gen Stratum = 0 if Size <= 65 & RandGroup == 0
replace Stratum = 1 if Size > 65 & Size <= 90 & RandGroup == 0
replace Stratum = 2 if Size > 90 & Size <= 125 & RandGroup == 0
replace Stratum = 3 if Size > 125 & Size <= 175 & RandGroup == 0
replace Stratum = 4 if Size > 175 & Size <. & RandGroup == 0
label define Stratum 0 "50-65" 1 "66-90" 2 "91-125" 3 "126-175" 4 "176-225"
label values Stratum Stratum
tab Stratum RandGroup, m

*** TO DO: calculate BE rate by stratum and study arm, and overall

/*
*** save final dataset before analysis (for Marcel)
drop RepeatTest CytoResult MacroCytoResult EndpointDate EndoscopyDate ///
	ResEndDate FUmonths FUyears-avgBErate
save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryEndppoint_Marcel", replace
*/

*** PREPARE DATASET

// The following needs to be improved: we do not need cutoff date for usual care
// We have to make sure that there is only 1 observation per usual care patient
// before running the mepoisson regression.
// Is it right?

* Calculate FU before and after 4 months for usual care
replace CutOff4 = ceil(BaselineDate + 4*30.44) if StudyArm == 0

count if EndDate <= CutOff4 & StudyArm == 0
// 0 BEs in the first 4 months of FU in usual care
summ FUdays if StudyArm == 0
// FU: > 122 days --> OK

replace CutOff4 = EndDate if EndDate <= CutOff4 & StudyArm == 0
// 0 changes

replace FU4 = (CutOff4 - BaselineDate) if StudyArm == 0
summ FU4 if StudyArm == 0, de
// 122 for all
replace FU4years = FU4/365.25 if StudyArm == 0
summ FU4years if StudyArm == 0, de
// 0.3 years for all

replace FU12 = EndDate - CutOff4 if EndDate > CutOff4 & StudyArm == 0
summ FU12 if StudyArm == 0, de
// 121-426 days
replace FU12years = FU12/365.25 if StudyArm == 0
summ FU12years if StudyArm == 0, de
// 0.3-1.2 years

* convert FUyears in 1000s
replace FU4years = FU4years/1000
replace FU12years = FU12years/1000
rename FU4years npy1
rename FU12years npy2

* BE indicator up to 4 months and after 4 months
gen nbe1 = 0
replace nbe1 = 1 if PrimaryEndpt == 1 & FUdays <= 122
tab nbe1 StudyArm
// 71 BEs/EACs in intervention

gen nbe2 = 0
replace nbe2 = 1 if PrimaryEndpt == 1 & FUdays > 122
tab nbe2 StudyArm
// 18 BEs/EACs in usual care, 70 BEs/EACs in intervention

* Change dataset format from wide to long
reshape long npy nbe, i(PatientID) j(Period)

* This gives us overall rate ratios (adjusted and not)
egen GP_period = group(Site Period)
ir nbe Study npy, by(GP_period)

* Interaction variables for study arm and period
gen Cyto1 = 0
replace Cyto1 = 1 if StudyArm == 1 & Period == 1
tab Cyto1 StudyArm

gen Cyto2 = 0
replace Cyto2 = 1 if StudyArm == 1 & Period == 2
tab Cyto2 StudyArm

* Site counter
encode Site, gen(gpid)

//drop if StudyArm == 0 & Period == 1
// NO: the above modifies follow-up times in usual care

* Mixed-effect Poisson regression (random effects follow log-gamma distribution)
mepoisson nbe Cyto1 Cyto2 i.Stratum if RandGroup == 0, exposure(npy) || gpid:

//xi: xtpoisson nbe Cyto1 Cyto2 i.Stratum if RandGroup == 0, exp(npy) i(gpid) re
// OK, same results

* Rate ratio with 95% CI
nlcom (exp(_b[Cyto1])+2*exp(_b[Cyto2]))/3, post
putexcel B17 = matrix(r(b))
putexcel C17 = matrix(r(V))
// TO DO: output p-value and CI

********
*** 4) PLR group

// TO DO: calculate rates before and after 4 months

*drop if Period == 1
replace FUyears = FUyears/1000
poisson PrimaryEndpt StudyArm if RandGroup == 1, irr exposure(FUyears)

// TO DO: FINISH PLR ANALYSIS

*********
*** 5) CLR+PLR group:
* The PLR group is a separate stratum of 2 clusters:
* 1 for intervention, 1 for usual care

// TO DO: do not divide PLR sites into 2 clusters + add them to strata definition
// as normal sites
gen GPidCombined = gpid
replace GPidCombined = 998 if RandGroup == 1 & StudyArm == 0
replace GPidCombined = 999 if RandGroup == 1 & StudyArm == 1

tab Stratum, nolab
replace Stratum = 5 if RandGroup == 1

mepoisson nbe Cyto1 Cyto2 i.Stratum, exposure(npy) || GPidCombined:
nlcom (exp(_b[Cyto1])+2*exp(_b[Cyto2]))/3, post
putexcel B16 = matrix(r(b))
putexcel C16 = matrix(r(V))
// TO DO: output p-value

test _b[_nl_1] = 1
help test

/*
*** TO DO: Test: RR > 1 with a two-sided alpha of 0.05
ttest _b[_nl_1] == 1
*/

est tab, p(%12.10g)

log close
