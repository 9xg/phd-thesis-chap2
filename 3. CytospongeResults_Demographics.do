version 15
log using "3", replace

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF.dta", clear
set more off

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("CytospongeResults") modify
***

describe LAST_UPDATED
// LAST_UPDATED_DATE was used as a proxy to "date reported to GP" in the report
// within the App
list LAST_UPDATED if PATIENT_ID == "B3GBBI0066"
replace LAST_UPDATED = "26-MAR-2019" if PATIENT_ID == "B3GBBI0066"
// following Beth's email (10/02/2020)

tab EVENT, m
// TO DO: understand why there are missing pathology results

* Processing/technical failure
tab CYTOSPONGE_OPTION_1 EVENT if CYTOSPONGE_OPTION_1 == "Y", matcell(A)
putexcel C1 = matrix(A[1,1])
putexcel C9 = 0

* Negative - squamous cells only
tab CYTOSPONGE_OPTION_2 EVENT if CYTOSPONGE_OPTION_2 == "Y", matcell(A)
putexcel C2 = matrix(A[1,1])
putexcel C10 = matrix(A[1,2])

* Equivocal
tab CYTOSPONGE_OPTION_6 EVENT if CYTOSPONGE_OPTION_6 == "Y", matcell(A)
putexcel C3 = matrix(A[1,1])
putexcel C11 = matrix(A[1,2])

* NEGATIVE high-confidence
tab CYTOSPONGE_OPTION_3 EVENT if CYTOSPONGE_OPTION_3 == "Y", matcell(A)
putexcel C4 = matrix(A[1,1])
putexcel C12 = matrix(A[1,2])

* POSITIVE
tab CYTOSPONGE_OPTION_4, m
tab CYTOSPONGE_OPTION_4A, m
tab CYTOSPONGE_OPTION_4B, m
gen POSITIVE_4 = 1 if CYTOSPONGE_OPTION_4 == "Y" | CYTOSPONGE_OPTION_4A == "Y" | ///
                CYTOSPONGE_OPTION_4B == "Y"
tab POSITIVE_4 EVENT if POSITIVE_4 == 1, matcell(A)
putexcel C5 = matrix(A[1,1])
putexcel C13 = matrix(A[1,2])

* POSITIVE WITH CELLULAR ATYPIA
tab CYTOSPONGE_OPTION_5, m
tab CYTOSPONGE_OPTION_5A, m
tab CYTOSPONGE_OPTION_5B, m
gen POSITIVE_5 = 1 if CYTOSPONGE_OPTION_5 == "Y" | CYTOSPONGE_OPTION_5A == "Y" | ///
                CYTOSPONGE_OPTION_5B == "Y"
tab POSITIVE_5 EVENT if POSITIVE_5 == 1, matcell(A)
putexcel C6 = matrix(A[1,1])
putexcel C14 = 0

********************************************************************************
* Not counting baseline results when repeat results are available

gen exclude = 0
sort PATIENT_ID EVENT
bysort PATIENT_ID: replace exclude = 1 if EVENT[_n] == 1 & EVENT[_N] == 2
tab exclude EVENT

duplicates tag PATIENT_ID, gen(RepeatTest)
tab RepeatTest

***
drop if exclude == 1
***

* Processing/technical failure
tab CYTOSPONGE_OPTION_1 if CYTOSPONGE_OPTION_1 == "Y", matcell(A)
putexcel C25 = matrix(A[1,1])

* Negative - squamous cells only
tab CYTOSPONGE_OPTION_2 if CYTOSPONGE_OPTION_2 == "Y", matcell(A)
putexcel C26 = matrix(A[1,1])

* Equivocal result
tab CYTOSPONGE_OPTION_6 if CYTOSPONGE_OPTION_6 == "Y", matcell(A)
putexcel C27 = matrix(A[1,1])

* NEGATIVE high-confidence
tab CYTOSPONGE_OPTION_3 if CYTOSPONGE_OPTION_3 == "Y", matcell(A)
putexcel C28 = matrix(A[1,1])

* POSITIVE
tab POSITIVE_4 if POSITIVE_4 == 1, matcell(A)
putexcel C29 = matrix(A[1,1])

* POSITIVE WITH CELLULAR ATYPIA
tab POSITIVE_5 EVENT if POSITIVE_5 == 1, matcell(A)
putexcel C30 = matrix(A[1,1])

********************************************************************************
* SAVE FINAL DATASET

// TO DO: check that only one Y per observation
gen CytoResult = 0 if CYTOSPONGE_OPTION_1 == "Y"
replace CytoResult = 1 if CYTOSPONGE_OPTION_2 == "Y"
replace CytoResult = 2 if CYTOSPONGE_OPTION_6 == "Y"
replace CytoResult = 3 if CYTOSPONGE_OPTION_3 == "Y"
replace CytoResult = 4 if POSITIVE_4 == 1
replace CytoResult = 5 if POSITIVE_5 == 1
label define Cytolab 0 "Processing/technical failure" ///
                1 "Negative - squamous only" 2 "Equivocal" 3 "Negative high-confidence" ///
                4 "Positive" 5 "Positive with cellular atypia"
label values CytoResult Cytolab
tab CytoResult, m

gen MacroCytoResult = 0 if CytoResult == 0 | CytoResult == 1 | CytoResult == 2
replace MacroCytoResult = 1 if CytoResult == 3
replace MacroCytoResult = 2 if CytoResult == 4 | CytoResult == 5
label define Macrocytolab 0 "Failure/equivocal/low-con neg" ///
                1 "Negative" ///
                2 "Positive"
label values MacroCytoResult Macrocytolab
tab MacroCytoResult, m

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF_final.dta", replace

********************************************************************************
* DEMOGRAPHICS

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/Cytosponge Results Excel.dta", clear
set more off

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("CytospongeDemographics") modify
***

duplicates report PatientID
// 378 duplicates
duplicates report PatientID YearOfBirth
// 378 duplicates

bysort PatientID: gen counter = _n
tab counter
drop if counter == 2

* date of collection
gen DateCollection = date(DateOfCollection, "DMY")
format DateCollection %tddd/nn/ccyy
summ DateCollection, format

gen yearcollection = year(DateCollection)
gen yob = real(YearOfBirth)
gen age = yearcollection - yob
summ age

gen agegroup = 0 if age >= 50 & age <= 59
replace agegroup = 1 if age >= 60 & age <= 69
replace agegroup = 2 if age >= 70 & age <= 79
replace agegroup = 3 if age >= 80 & age <= 89
replace agegroup = 4 if age >= 90 & age <= 99
label define agelab 0 "50-59" 1 "60-69" 2 "70-79" 3 "80-89" 4 "90-99"
label values agegroup agelab
tab agegroup, m
tab agegroup Sex, matcell(A)
matrix rownames A = "50-59" "60-69" "70-79" "80-89" "90-99"
matrix colnames A = "F" "M"
putexcel A2 = matrix(A), names

rename PatientID PATIENT_ID
merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF_final.dta"

tabstat age, s(mean median min max p25 p75) save
putexcel B20 = matrix(r(StatTotal)')
tabstat age, by(MacroCytoResult) s(mean median min max p25 p75) save
putexcel B21 = matrix(r(Stat3)')
putexcel B22 = matrix(r(Stat2)')
putexcel B23 = matrix(r(Stat1)')
tabstat age, by(RepeatTest) s(mean median min max p25 p75) save
putexcel B24 = matrix(r(Stat2)')
putexcel B25 = matrix(r(Stat1)')

********************************************************************************
* CYTOSPONGE ACCEPTABILITY

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/FOLLOWUP_QUESTIONNAIRE.dta", clear
set more off

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("CytospongeQuestionnaire") modify
***

duplicates list PATIENT_ID

* Are these all patients who received the Cytosponge?
merge 1:m PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF_clean.dta"
// Yes, they all received the Cytosponge
sort PATIENT_ID
duplicates tag PATIENT_ID, gen(dup)
list PATIENT_ID if _merge == 3 & SuccessfulSwallow == 0 & dup == 0
/*
 122. | B3GBBE0151 |
 123. | B3GBBE0162 |
1728. | B3GBST0041 |
*/
// These 3 patients appear in this CRF if they had
// an unsuccessful swallow --> however, they have missing Cytosponge score
br if PATIENT_ID == "B3GBBE0151"
br if PATIENT_ID == "B3GBBE0162"
br if PATIENT_ID == "B3GBST0041"

drop if PATIENT_ID == "B3GBBE0151" | ///
	PATIENT_ID == "B3GBBE0162" | ///
	PATIENT_ID == "B3GBST0041"

drop if _merge == 2
drop _merge dup

// let's drop repeat tests
duplicates drop PATIENT_ID, force

***
* Beth (23/10/2019):
* this patient should be excluded because of language difficulties
drop if PATIENT_ID == "B3GBBB0005"
***

tab SPONGE_PROCEDURE_EXPERIENCE, matcell(A)
putexcel B5 = matrix(A)
summ SPONGE_PROCEDURE_EXPERIENCE, de
tabstat SPONGE_PROCEDURE_EXPERIENCE, s(mean min max p50 p25 p75) save
return list
matrix A = r(StatTotal)'
putexcel B2 = matrix(A)

********************************************************************************
* MEDICATION

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/MEDICATION_SUBFORM.dta", clear
set more off

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("CytospongeDemographics") modify
***

describe MEDICATION_NAME
tab MEDICATION_NAME, m
// 1 = H2 receptor Antagonists;
// 2 = Proton Pump Inhibitor;
// 3 = Over the counter anti-acids;
// 4 = Other
replace MEDICATION_NAME = MEDICATION_NAME - 1
label define Medlab 0 "H2RA" 1 "PPI" 2 "Over the counter" 3 "Other"
label values MEDICATION_NAME Medlab
rename MEDICATION_NAME Medication
tab Medication, m

drop if Medication == 2 | Medication == 3 // not interesting for now
sort PATIENT_ID Medication
keep PATIENT_ID Medication STARTED
duplicates drop PATIENT_ID Medication, force

bysort PATIENT_ID: egen Medsum = total(Medication)
bysort PATIENT_ID: gen counter = _n

count if Medsum == 0
putexcel B14 = (r(N))
count if Medsum == 1 & counter == 1
putexcel B15 = (r(N))
count if Medsum == 1 & counter == 2
putexcel B16 = (r(N))

tab STARTED, m
// Month/Year started;
// 0 = 0 - 1 year; 1 = 1 - 2 years; 2 = 2 -3 years; 3 = 3 - 4 years;
// 4 = 4 - 5 years; 5 = 5 - 6 years; 6 = 6+ years
bysort PATIENT_ID: egen Length = max(STARTED)
tab Length
count if STARTED >= 3 & counter == 1
// 1448/1654 = this should be added to Excel output

********************************************************************************
* BMI data
********************************************************************************
use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BASELINE_CRF.dta", clear

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("CytospongeDemographics") modify
***

duplicates tag PATIENT_ID, gen(dup)
tab dup
// 202 duplicates --> these must be the repeat tests

duplicates tag PATIENT_ID HEIGHT WEIGHT, gen(dup2)
tab dup2
// less duplicates than before

count if dup == 1 & dup2 == 0

*** Add Cytosponge attendees
merge m:m PATIENT_ID EVENT using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF_clean.dta"
***
// 7 records not matched
count if _merge == 1
// Cytosponge attendees who did not have test

*** Add patient status
merge m:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT_clean.dta", gen(merge2)
***

tab STATUS if _merge == 1
// X4: withdrawn from Cytosponge procedure --> OK

drop if _merge == 1
drop if merge2 == 2

tab SuccessfulSwallow

//--> Consider only results from repeat test
drop if dup == 1 & EVENT == 1
drop dup dup2 _merge merge2

****
* Add Cytosponge results
merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF_final.dta"
****

* CYTOSPONGE ATTENDEES
tab HEIGHT, m
// 1 missing
tabstat HEIGHT, s(mean median min max p25 p75) save
putexcel B31 = matrix(r(StatTotal)')
tab WEIGHT, m
// 1 missing
tabstat WEIGHT, s(mean median min max p25 p75) save
putexcel B32 = matrix(r(StatTotal)')

gen BMI = WEIGHT/(HEIGHT/100)^2
tab BMI, m
tabstat BMI, s(mean median min max p25 p75) save
putexcel B33 = matrix(r(StatTotal)')

gen BMIcat = 0 if BMI < 18.5
replace BMIcat = 1 if BMI >= 18.5 & BMI < 25
replace BMIcat = 2 if BMI >= 25 & BMI < 30
replace BMIcat = 3 if BMI >= 30 & BMI < 35
replace BMIcat = 4 if BMI >= 35 & BMI < 40
replace BMIcat = 5 if BMI >= 40 & BMI < .
label define BMIlab 0 "Underweight <18.5" 1 "Normal 18.5-24.9" ///
	2 "Overweight 25.0-29.9" 3 "Obese 30.0-34.9" 4 "Severely obese 35.0-39.9" ///
	5 "Morbidly obese 40.0+"
label values BMIcat BMIlab
tab BMIcat, m matcell(A)
putexcel B41 = matrix(A)

* Patients with unsuccessful swallow at baseline
summ BMI if SuccessfulSwallow == 0 & EVENT == 1, de
tab BMIcat if SuccessfulSwallow == 0 & EVENT == 1, m

* Patients with successful swallow at baseline
tabstat HEIGHT if _merge == 3, s(mean median min max p25 p75) save
putexcel B36 = matrix(r(StatTotal)')
tabstat WEIGHT if _merge == 3, s(mean median min max p25 p75) save
putexcel B37 = matrix(r(StatTotal)')
tabstat BMI if _merge == 3, s(mean median min max p25 p75) save
putexcel B38 = matrix(r(StatTotal)')

bysort MacroCytoResult: summ BMI if _merge == 3, de
tab BMIcat if _merge == 3, m matcell(A)
tab BMIcat MacroCytoResult if _merge == 3, m matcell(A)
putexcel B51 = matrix(A)

log close
