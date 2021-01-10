version 15
log using "4", replace

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/ENDOSCOPY_PROCEDURE_CRF.dta", clear
set more off

********************************************************************************
* CLEANING
********************************************************************************

tab CRF_ID, m
count if CRF_ID == .

tab PATIENT_ID, m
count if PATIENT_ID == ""
duplicates list PATIENT_ID
// 0 duplicates

tab CRF_VERSION, m
// 1 or 2

tab EDIT_STATUS, m
// C or L

tab EVENT, m
// all 1st events --> this makes sense as no one should have had > 1 endoscopy
//						within the Trial
drop EVENT

tab CREATED_BY, m

tab CREATED_DATE, m

tab PROCEDURE_DATE, m
gen EndoscopyDate = date(PROCEDURE_DATE, "DM20Y")
format EndoscopyDate %tdDD/NN/CCYY
summ EndoscopyDate, de format
// 5 missing

br if EndoscopyDate == . | year(EndoscopyDate ) > 2019
// Queried with Beth (13/01):
/* PATIENT_ID
B3GBNQ0027 --> all blanks
B3GBCE0079 --> all blanks
B3GBCV0090 --> all blanks
B3GBML0081 --> all blanks
B3GBPM0102 --> all blanks
*/
// These 5 did not have endoscopy
// 3 more did not have endoscopy (not shown here)

tab CYTOSPONGE_RESULT_POS, m
// probably not recorded very well
tab CYTOSPONGE_RESULT_NEG, m
// probably not recorded very well

// TO DO: finish cleaning

********************************************************************************
* ANALYSIS
********************************************************************************

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("ResearchEndoscopies") modify
***

merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF_final.dta"
drop _merge
merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PatientArm.dta"
drop _merge
merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT_clean.dta", gen(merge)
drop merge

tab CytoResult, m
tab CytoResult if EndoscopyDate != ., m
// 223 confirmatory endoscopies
// 65 research endoscopies to negative patients

tab STUDY_ARM if EndoscopyDate != ., m
// 55 research endoscopies in usual care

gen EndoscopyType = 0 if EndoscopyDate != . & (CytoResult == 4 | CytoResult == 5)
replace EndoscopyType = 1 if EndoscopyDate != . & CytoResult == 3
replace EndoscopyType = 2 if EndoscopyDate != . & STUDY_ARM == "U"
label define Endlab 0 "Confirmatory" 1 "Negative patients" 2 "Usual care patients"
label values EndoscopyType Endlab
label variable EndoscopyType "Type of Endoscopy"
tab INVITE_R_ENDOSCOPY_SENT
// 697 invite to research endoscopies
tab EndoscopyType if INVITE_R_ENDOSCOPY_SENT == "Y"
tab EndoscopyType
// OK, they correspond

/*
* Checking 4 patients not appearing in Research Endoscopy Report
* downloadable from App
br PATIENT_ID if EndoscopyType == 1
br if PATIENT_ID == "B3GBCP0074" | ///
	PATIENT_ID == "B3GBDM0058" | ///
	PATIENT_ID == "B3GBPE0105" | ///
	PATIENT_ID == "B3GBPR0007"
count if CLINICAL_LETTER_LOGGED_DATE != ""
*/

count if EndoscopyDate != . & CytoResult == . & STUDY_ARM == "I"
// 3 non-responders had research endoscopy
putexcel B19 = (r(N))

tab EndoscopyType, matcell(A)
putexcel B6 = matrix(A[2,1])
putexcel C6 = matrix(A[3,1])

* CHI SQUARE TEST TO COMPARE CYTOSPONGE ATTENDANCE
* VS USUAL CARE RESEARCH ENDOSCOPY ATTENDANCE

***
merge 1:m PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF_clean.dta"
***

duplicates drop PATIENT_ID, force
tab SuccessfulSwallow
//1750

gen Attendance = .
replace Attendance = 0 if STUDY_ARM == "I"
replace Attendance = 0 if STUDY_ARM == "U" & INVITE_R_ENDOSCOPY_SENT == "Y"
replace Attendance = 1 if EndoscopyType == 2
replace Attendance = 1 if SuccessfulSwallow != .
tab STUDY_ARM Attendance, chi2
putexcel B22 = (r(chi2))
putexcel B23 = (r(p))

* If we use successful swallows for Cyto attendance:
drop Attendance
gen Attendance = .
replace Attendance = 0 if STUDY_ARM == "I"
replace Attendance = 0 if STUDY_ARM == "U" & INVITE_R_ENDOSCOPY_SENT == "Y"
replace Attendance = 1 if EndoscopyType == 2
replace Attendance = 1 if CytoResult != .
tab STUDY_ARM Attendance, chi2
putexcel E22 = (r(chi2))
putexcel E23 = (r(p))

* BE suspected at confirmatory endoscopy or research endoscopy ONLY
tab EndoscopyType BARRETTS_OESOPHAGUS if BARRETTS_OESOPHAGUS == "Y", matcell(B)
putexcel B10 = matrix(B[2,1])
putexcel C10 = matrix(B[3,1])

br PATIENT_ID BARRETTS_OESOPHAGUS EndoscopyType if BARRETTS_OESOPHAGUS == "Y"
***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("TrialEndoscopies") modify
***

putexcel B2 = matrix(A[1,1])
putexcel B6 = matrix(B[1,1])

********************************************************************************
* ANALYSE ENDOSCOPY PATHOLOGY DATA

merge 1:1 PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/ENDOSCOPY_PATH_CRF.dta", gen(merge)
// all endoscopy pathology records matched
drop merge

* BE with IM
tab WITH_INTESTINAL_METAPLASIA if EndoscopyType == 0
// 98

* BE with GM
tab WITH_GASTRIC_METAPLASIA if EndoscopyType == 0
// 19
// 98+19 = 117 BEs with IM or GM from confirmatory endoscopies ?

* Check that these are the same ones identified in Endpoint data spreadsheet
rename PATIENT_ID PatientID
merge 1:1 PatientID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryBE.dta", gen(merge)
drop merge

tab WITH_INTESTINAL_METAPLASIA PrimaryEndpt if EndoscopyType == 0, m
// 94 BEs instead of 98
tab WITH_INTESTINAL_METAPLASIA DiagDetail ///
	if EndoscopyType == 0 & PrimaryEndpt == ., m
// 2 have cancers, 2 do not appear in Beth's spreadsheet
br if WITH_INTESTINAL_METAPLASIA == "Y" & PrimaryEndpt == . & ///
	DiagDetail == . & EndoscopyType == 0
// --> 2 patients queried with Beth on 7/2/2020:
// B3GBFW0012 --> CRF wrongly filled out
// B3GBPW0118 --> similar issue

gen TrialBE = 0
replace TrialBE = 1 if WITH_INTESTINAL_METAPLASIA == "Y" & PrimaryEndpt == 1 & ///
	EndoscopyType == 0

tab WITH_GASTRIC_METAPLASIA PrimaryEndpt if EndoscopyType == 0, m
// 18 BEs instead of 19
tab WITH_GASTRIC_METAPLASIA DiagDetail ///
	if EndoscopyType == 0 & PrimaryEndpt == ., m
// 1 cancer

replace TrialBE = 1 if WITH_GASTRIC_METAPLASIA == "Y" & PrimaryEndpt == 1 & ///
	EndoscopyType == 0
tab TrialBE
// 112 BEs diagnosed following a confirmatory endoscopy
tab DiagDetail if PrimaryEndpt == 1 & EndoscopyType == 0

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("Diagnoses") modify
***

* Count IM at the GOJunction for positive patients with no other diagnoses
tab INTESTINAL_METAPLASIA_GOJ if STUDY_ARM == "I"
// 42
tab INTESTINAL_METAPLASIA_GOJ if (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0
// 38
count if INTESTINAL_METAPLASIA_GOJ == "Y" & (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .
// 17
putexcel E27 = (r(N))
putexcel A27 = "IM of the GOJ (no worse)"
gen IM = 1 ///
	if INTESTINAL_METAPLASIA_GOJ == "Y" & (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .

* Count IM gastric cardia for positive patients
tab INTESTINAL_METAPLASIA_PRESENT if STUDY_ARM == "I"
// 27
tab INTESTINAL_METAPLASIA_PRESENT ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0
// 25
count if INTESTINAL_METAPLASIA_PRESENT == "Y" ///
	& (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .
// 8
putexcel E28 = (r(N))
putexcel A28 = "IM of the gastric cardia (no worse)"
replace IM = 1 ///
	if INTESTINAL_METAPLASIA_PRESENT == "Y" & (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .
// 7 changes only

* Count gastric IM (outside gastric cardia) for positive patients
tab STOMACH_INTESTINAL_METAPLASIA if STUDY_ARM == "I"
// 22
tab STOMACH_INTESTINAL_METAPLASIA ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0
// 21
count if STOMACH_INTESTINAL_METAPLASIA == "Y" ///
	& (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .
// 13
putexcel E29 = (r(N))
putexcel A29 = "IM of the stomach outside gastric cardia (no worse)"
replace IM = 1 ///
	if STOMACH_INTESTINAL_METAPLASIA == "Y" & (CytoResult == 4 | CytoResult == 5) & ///
	EndoscopyType == 0 & DiagDetail == . & PrimaryEndpt == .
// 10 changes only

* Total of patients with IM only and no worse
count if IM == 1
putexcel E30 = (r(N))

/*
* Count gastric metaplasia outside gastric cardia for positive patients
tab STOMACH_INTESTINAL_METAPLASIA if STUDY_ARM == "I"
tab STOMACH_INTESTINAL_METAPLASIA ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0
// 21
tab STOMACH_INTESTINAL_METAPLASIA BARRETTS_OESOPHAGUS ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0

* Dysplasia
tab DYSPLASIA_PRESENT ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0
tab DYSPLASIA_PRESENT_GOJ ///
	if (CytoResult == 4 | CytoResult == 5) & EndoscopyType == 0
tab DYSPLASIA_PRESENT_DEGREE
*/

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("ResearchEndoscopies") modify
***

*** RESEARCH ENDOSCOPIES

* BE with IM
tab EndoscopyType WITH_INTESTINAL_METAPLASIA

* BE with GM
tab EndoscopyType WITH_GASTRIC_METAPLASIA

gen ResEndBE = 0
replace ResEndBE = 1 if (EndoscopyType == 1 | EndoscopyType == 2) & ///
	(WITH_INTESTINAL_METAPLASIA == "Y" | WITH_GASTRIC_METAPLASIA == "Y")
tab EndoscopyType ResEndBE, matcell(A)
putexcel B14 = matrix(A[2,2])
putexcel C14 = matrix(A[3,2])

********************************************************************************
* BE length
********************************************************************************

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("Diagnoses") modify
***

* FOR POSITIVE PATIENTS, PRIMARY BEs

count if CytoResult == 4 | CytoResult == 5 // 231 positive patients

tab BARRETTS_OESOPHAGUS_DISTANCE if PrimaryEndpt == 1
// 106
tab BARRETTS_OESOPHAGUS_DISTANCE if PrimaryEndpt == 1 & ///
	(CytoResult == 4 | CytoResult == 5)
// 106 records
tabstat BARRETTS_OESOPHAGUS_DISTANCE if PrimaryEndpt == 1, ///
	s(mean median min max p25 p75) save
return list
matrix A = r(StatTotal)'
putexcel B32 = matrix(A)

tab CIRCUMFERENTIAL_LENGTH if PrimaryEndpt == 1 & ///
	(CytoResult == 4 | CytoResult == 5)
// 107 records
br if CIRCUMFERENTIAL_LENGTH == 13
// 1 outlier: B3GBSK0091
tabstat CIRCUMFERENTIAL_LENGTH if PrimaryEndpt == 1, ///
	s(mean median min max p25 p75) save
return list
matrix A = r(StatTotal)'
putexcel B33 = matrix(A)
tab CIRCUMFERENTIAL_LENGTH if PrimaryEndpt == 1 & ///
	(CytoResult == 4 | CytoResult == 5), m ///
	matcell(A) matrow(B)
putexcel A38 = matrix(B)
putexcel B38 = matrix(A)

tab MAXIMAL_LENGTH if PrimaryEndpt == 1 & ///
	(CytoResult == 4 | CytoResult == 5)
// 107 records
tabstat MAXIMAL_LENGTH if PrimaryEndpt == 1, ///
	s(mean median min max p25 p75) save
return list
matrix A = r(StatTotal)'
putexcel B34 = matrix(A)
tab MAXIMAL_LENGTH if PrimaryEndpt == 1 & ///
	(CytoResult == 4 | CytoResult == 5), m ///
	matcell(A) matrow(B)
putexcel D38 = matrix(B)
putexcel E38 = matrix(A)
putexcel A48 = "missing"
putexcel D49 = "missing"

* ADD DATA FOR OTHER PATIENTS
* (these are manually curated, emails saved in Data Query folder)



log close
