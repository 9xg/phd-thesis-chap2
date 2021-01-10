version 15
log using "2", replace

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT.dta", ///
	clear
set more off

********************************************************************************
* CLEANING
********************************************************************************
describe PATIENT_ID
// string
duplicates report PATIENT_ID
// 0 duplicates
count if PATIENT_ID == ""
// 0

describe SC_ID
// int
tab SC_ID, m
// 0 missing

describe DATE_LOADED
// string
gen temp = substr(DATE_LOADED, 1, 9)
gen DateLoaded = date(temp, "DM20Y")
format DateLoaded %tdDD/NN/CCYY
drop temp DATE_LOADED
summ DateLoaded, format
// 0 missing

describe STATUS
tab STATUS, m
// A2: did not opt out of study within 14 days
// A3: Cytosponge invitation letter
// A4: interested in Cytosponge
// A6: pathology report CRF validated and saved
// X1: opted-out after intro letter
// X2: not interested in Cytosponge/non-responder
// X3: ineligible to Cyto (after interest expressed)
// X4: withdrawn from Cytosponge procedure

describe INTRO_LETTER_SENT
tab INTRO_LETTER_SENT, m
// 0 missing
drop INTRO_LETTER_SENT

describe INTRO_LETTER_SENT_DATE
gen temp = substr(INTRO_LETTER_SENT_DATE, 1, 9)
gen IntroLetterSentDate = date(temp, "DM20Y")
format IntroLetterSentDate %tdDD/NN/CCYY
drop temp INTRO_LETTER_SENT_DATE
summ IntroLetterSentDate , format
// 0 missing

describe INTRO_LETTER_LOGGED_BY
tab INTRO_LETTER_LOGGED_BY, m
drop INTRO_LETTER_LOGGED_BY

describe INTRO_LETTER_RESPONSE
tab INTRO_LETTER_RESPONSE, m
// 410 opt-outs
tab INTRO_LETTER_RESPONSE STATUS
// OK: all opt-outs have status X1

merge m:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SiteArm.dta"
drop Size _merge
// this is site size after drop-outs

tab INTRO_LETTER_RESPONSE RandGroup
tab INTRO_LETTER_RESPONSE STUDY_ARM, m
gen OptOut = 0
replace OptOut = 1 if INTRO_LETTER_RESPONSE == "O"

describe INTRO_LETTER_RESPONSE_DATE 
gen temp = substr(INTRO_LETTER_RESPONSE_DATE, 1, 9)
gen IntroLetterResponseDate = date(temp, "DM20Y")
format IntroLetterResponseDate %tdDD/NN/CCYY
drop temp INTRO_LETTER_RESPONSE_DATE
summ IntroLetterResponseDate, format

count if IntroLetterResponseDate < . & INTRO_LETTER_RESPONSE == ""
// 2: they must have replied to the letter to say they were interested
count if IntroLetterResponseDate < IntroLetterSentDate
// 0: OK

*** TO DO: CONTINUE CLEANING FROM HERE
/*
describe
INTRO_LETTER_RESPONSE_LOG_BY SPONGE_LETTER_SENT SPONGE_LETTER_SENT_DATE SPONGE_LETTER_LOGGED_BY INTRO_LETTER_LOGGED_DATE SPONGE_LETTER_LOGGED_DATE STUDY_ARM SPONGE_LETTER_RESPONSE SPONGE_RESPONSE_LOGGED_BY SPONGE_RESPONSE_LOGGED_DATE SPONGE_DECLINED_REASON SPONGE_DECLINED_COMMENTS SPONGE_DECLINED_LOGGED_BY SPONGE_DECLINED_LOGGED_DATE ELIGIBLE ELIGIBLE_LOGGED_BY ELIGIBLE_LOGGED_DATE BASELINE_DATA_AGG_COMPLETED BASELINE_DATA_LOGGED_BY BASELINE_DATA_LOGGED_DATE ALLOW_RESEARCH_ENDOSCOPY ALLOW_RESEARCH_END_LOGGED_BY ALLOW_RESEARCH_END_LOGGED_DATE CLINICAL_LETTER_LOGGED_BY CLINICAL_LETTER_LOGGED_DATE CLINICAL_LETTER_SENT CLINICAL_LETTER_SENT_DATE ELIGIBLE_RESEARCH ELIGIBLE_R_LOGGED_BY ELIGIBLE_R_LOGGED_DATE END_LETTER_RESPONSE END_LETTER_RES_LOGGED_BY END_LETTER_RES_LOGGED_DATE INVITE_C_ENDOSCOPY_LOGGED_BY INVITE_C_ENDOSCOPY_LOGGED_DATE INVITE_C_ENDOSCOPY_SENT INVITE_C_ENDOSCOPY_SENT_DATE INVITE_R_ENDOSCOPY_LOGGED_BY INVITE_R_ENDOSCOPY_LOGGED_DATE INVITE_R_ENDOSCOPY_SENT INVITE_R_ENDOSCOPY_SENT_DATE R_END_SCHEDULE R_END_SCHEDULE_DATE R_END_SCHEDULE_LOGGED_BY R_END_SCHEDULE_LOGGED_DATE APP_BOOKED APP_BOOKED_BY APP_BOOKED_DATE APP_LAST_UPDATED APP_LAST_UPDATED_BY REVIEW REVIEW_DATE REVIEW_LOGGED_BY REVIEW_LOGGED_DATE REVIEW_REASON ELIGIBLE_REASON REP_APP_BOOKED REP_APP_BOOKED_BY REP_APP_BOOKED_DATE REP_APP_LAST_UPDATED REP_APP_LAST_UPDATED_BY REP_CLINICAL_LETTER_LOG_BY REP_CLINICAL_LETTER_LOG_DATE REP_CLINICAL_LETTER_SENT REP_CLINICAL_LETTER_SENT_DATE REP_ELIGIBLE REP_INV_C_ENDOSCOPY_LOG_BY REP_INV_C_ENDOSCOPY_LOG_DATE REP_INV_C_ENDOSCOPY_SENT REP_INV_C_ENDOSCOPY_SENT_DATE SPONGE_REPEAT SPONGE_REPEAT_LOGGED_BY SPONGE_REPEAT_LOGGED_DATE INTENTION_TO_TREAT INTENTION_TO_TREAT_LOGGED_BY INTENTION_TO_TREAT_LOGGED_DATE RANDOMISATION_DATE RANDOMISED_BY SPONGE_REP_NOT_INT_OTHER SPONGE_REP_NOT_INT_REASON

// Check statuses
br if STUDY_ARM == ""
drop OptOuts?
*/

describe SPONGE_LETTER_RESPONSE
tab SPONGE_LETTER_RESPONSE STUDY_ARM, m
// 1 = interested; 2 = not interested; 0 = no response
gen SpongeLetterResponse = 0 ////
	if (SPONGE_LETTER_RESPONSE == 0 | SPONGE_LETTER_RESPONSE == .) & ////
	STUDY_ARM == "I"
replace SpongeLetterResponse = 1 if SPONGE_LETTER_RESPONSE == 2
replace SpongeLetterResponse = 2 if SPONGE_LETTER_RESPONSE == 1
label define Spongelab 0 "No response" 1 "Not interested" 2 "Interested"
label values SpongeLetterResponse Spongelab
tab SpongeLetterResponse STUDY_ARM, m
drop SPONGE_LETTER_RESPONSE

describe ELIGIBLE
tab ELIGIBLE STUDY_ARM, m
// Y: Eligible; N: Ineligible; X: Not Screened
gen EligiblePhoneScreen = 0 if (ELIGIBLE == "" | ELIGIBLE == "X") & ///
	STUDY_ARM == "I"
replace EligiblePhoneScreen = 1 if ELIGIBLE == "N"
replace EligiblePhoneScreen = 2 if ELIGIBLE == "Y"
label define Elilab 0 "Not screened" 1 "Not eligible" 2 "Eligible"
label values EligiblePhoneScreen Elilab
tab EligiblePhoneScreen STUDY_ARM, m
drop ELIGIBLE

tab ELIGIBLE_REASON STUDY_ARM, m
// Reason for not eligible at phone screening:
// '0':'--select--','1':'Under the age of 50''
// '2':'Does not have record of at least 6 months of prescription for acid-suppressant medication in the last year'
// '3':'Objection to BEST3 data collection'
// '4':'Meeting the guidelines for an urgent endoscopy referral according to NICE guidelines'
// '5':'Recorded diagnosis of an oro-pharynx, oesophageal or gastro-oesophageal tumour (T2 staging and above), or symptoms of dysphagia'
// '6':'Difficulty in swallowing due to a known cerebrovascular accident or neurological disorder '
// '7':'Recorded oesophageal varices, cirrhosis of the liver'
// '8':'Unable to temporarily discontinue anti-thrombotic medication prior to procedure'
// '9':'Eaten and drank within the previous 4 hours'
// '10':'Received prior surgical intervention to the oesophagus'
// '11':'Known pregnancy'
// '12':'Unwilling to swallow beef gelatine capsule as part of dietary preferences'
// '13':'Other'
count if ELIGIBLE_REASON != .
// 307 not eligible
count if ELIGIBLE_REASON != . & APP_BOOKED != ""
// 0: OK

********************************************************************************
* FLOWCHART DATA
********************************************************************************

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("BaselineAll") modify
***

* patients by site
tab Site OptOut, matcell(A) m
levelsof Site, local(sitelabel)
matrix rownames A = `sitelabel'
matrix colnames A = "No. patients after opt-out" "No. Opt-outs"
putexcel A5 = matrix(A), names

drop if OptOut == 1

* number of patients by type of group
tab RandGroup, matcell(A) m
matrix rownames A = "CLR" "PLR"
matrix colnames A = "No. patients after opt-out"
putexcel G7 = matrix(A'), names

* number of patients by type of randomisation
tab STUDY_ARM, matcell(A) m
matrix rownames A = "Intervention" "Usual care"
matrix colnames A = "No. patients after opt-out"
putexcel L7 = matrix(A'), names

* patients per site size category
bysort Site: gen Size = _N
gen SizeCat = 0 if Size <= 90
replace SizeCat = 1 if Size > 90 & Size <= 160
replace SizeCat = 2 if Size > 160 & Size < .
label define sizelab 0 "<=90" 1 "91-160" 2 "161+"
label values SizeCat sizelab
tab SizeCat STUDY_ARM, matcell(A)
matrix rownames A = "<=90" "91-160" "161+"
matrix colnames A = "Intervention" "Usual care"
putexcel G14 = matrix(A), names

* IMD
merge m:1 Site using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/OverviewGPsites.dta"
drop _merge
merge m:1 Postcode using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/2019-deprivation-by-postcode.dta"

drop PostcodeStatus-IndexofMultipleDeprivationRa IncomeRank-_merge
describe IndexofMultipleDeprivationDe
rename IndexofMultipleDeprivationDe IMD

* IMD by patient (after assigning practice IMD to each of its patients)
tab IMD STUDY_ARM, m matcell(A)
putexcel M27 = matrix(A)
tabstat IMD, by(STUDY_ARM) s(median p25 p75) save
return list
matrix A = r(Stat1)
matrix B = r(Stat2)
matrix D = r(StatTotal)
putexcel M21 = matrix(A)
putexcel N21 = matrix(B)
putexcel O21 = matrix(D)

* IMD by site
bysort Site: gen sitecounter = _n
tab IMD if sitecounter == 1, m matcell(A)
putexcel H27 = matrix(A)
tabstat IMD, s(median p25 p75) save
matrix D = r(StatTotal)
putexcel H21 = matrix(D)
drop sitecounter

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("BaselineIntervention") modify
***

* Intervention: responses to Cytosponge invitation letter
tab SpongeLetterResponse STUDY_ARM, m
tab SpongeLetterResponse, matcell(A)
matrix rownames A = "No response" "Not interested" "Interested"
matrix colnames A = "Cytosponge invitation letter"
putexcel A1 = matrix(A), names

* Intervention: telephone screened
tab Eligible STUDY_ARM, m
tab Eligible, matcell(A)
matrix rownames A = "Not screened" "Not eligible" "Eligible"
matrix colnames A = "Phone screened"
putexcel A7 = matrix(A), names

* TO DO: show breakdown of reasons for being ineligible
// tab ELIGIBLE_REASON, m

* Intervention: Cytosponge appointment booked
count if APP_BOOKED != "" & STUDY_ARM == "I"
count if APP_BOOKED != ""
putexcel B14 = (r(N))
putexcel B13 = "Cytosponge appointments booked"

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("TrialEndoscopies") modify
***

* Endoscopies
tab INVITE_C_ENDOSCOPY_SENT STUDY_ARM, m
tab INVITE_C_ENDOSCOPY_SENT if INVITE_C_ENDOSCOPY_SENT != "", matcell(A)
//putexcel B2 = matrix(A)

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("ResearchEndoscopies") modify
***

****
* Research endoscopies
****

* INVITES
tab INVITE_R_ENDOSCOPY_SENT STUDY_ARM, m
tab INVITE_R_ENDOSCOPY_SENT STUDY_ARM if SpongeLetterResponse == 0, m
// Cyto non-responders --> ignore
tab INVITE_R_ENDOSCOPY_SENT STUDY_ARM if SpongeLetterResponse == 1, m
// Cyto not interested --> ignore
tab INVITE_R_ENDOSCOPY_SENT STUDY_ARM if SpongeLetterResponse == 2, m
// Cyto interested --> negative patients	
tab INVITE_R_ENDOSCOPY_SENT STUDY_ARM ///
	if (SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U", ///
	matcell(A)
matrix colnames A = "Intervention Negative Cytosponge" "Usual care"
matrix rownames A = "Research endoscopy invites"
putexcel A1 = matrix(A), names

* INTEREST
tab END_LETTER_RESPONSE STUDY_ARM, m
tab END_LETTER_RESPONSE STUDY_ARM ///
	if (SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U"
// 'Happy to attent' = '1'; 'Does not want to attend': '2'; 'No response': '3'
gen ResEndInterest = 0 if END_LETTER_RESPONSE == 2 & ///
	((SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U")
replace ResEndInterest = 1 if END_LETTER_RESPONSE == 1 & ///
	((SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U")
replace ResEndInterest = 2 if (END_LETTER_RESPONSE == 3 & ///
	((SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U")) | ///
	(INVITE_R_ENDOSCOPY_SENT != "" & END_LETTER_RESPONSE == . & ///
	((SpongeLetterResponse == 2 & STUDY_ARM == "I") | STUDY_ARM == "U"))
tab ResEndInterest STUDY_ARM, m
label define reslab 0 "Not interested" 1 "Interested" 2 "No response"
label values ResEndInterest reslab
tab ResEndInterest STUDY_ARM, matcell(A)
putexcel B3 = matrix(A)

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT_clean.dta", ///
	replace

********************************************************************************

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SiteArm.dta", clear

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("BaselineAll") modify
***

* Number of sites by type of group
tab RandGroup, matcell(A) m
matrix rownames A = "CLR" "PLR"
putexcel G10 = matrix(A'), names
putexcel G11 = "No. sites"

* Number of sites by type of randomisation
tab StudyArm if StudyArm != 2, matcell(A) m
matrix rownames A = "Intervention" "Usual care"
putexcel L10 = matrix(A'), names
putexcel L11 = "No. sites in CLR group"

* Site size
tabstat Size, s(median min max p25 p75) save
return list
/*matrix A = r(Stat1)
matrix B = r(Stat2)
matrix C = r(Stat3)
matrix D = r(StatTotal)*/

********************************************************************************

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF.dta", clear

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("BaselineIntervention") modify
***

* Intervention: undergoing Cyto procedure
count if PROCEDURE_DATE != ""
// TO DO: understand why one date is missing
tab EVENT if PROCEDURE_DATE != "", matcell(A) m
matrix rownames A = "Baseline Cytosponge" "Repeat Cytosponge"
putexcel A16 = matrix(A), names
putexcel B16 = "Undergoing Cytosponge"

* Intervention: unable to swallow/successful swallows
tab EVENT NOF, m
br if NOF == .
// queried with Beth (25/11): patient was stopped having the procedure by GP
drop if NOF == .
gen Sw = 0 if NOF == 2
replace Sw = 1 if NOF == 0 | NOF == 1
label define Swlab 0 "Unable to swallow" 1 "Successful swallow"
label values Sw Swlab
// unreliable
drop Sw
gen Sw2 = 1
replace Sw2 = 0 if SPONGE_NOT_COLLECTED != ""
label values Sw2 Swlab
tab Sw2 if EVENT == 1, matcell(A)
putexcel C21 = matrix(A)
tab Sw2 if EVENT == 2, matcell(A)
putexcel C25 = matrix(A)
rename Sw2 SuccessfulSwallow

***
save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF_clean.dta", ///
	replace
***

***
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("BaselineAll") modify
***

keep if SuccessfulSwallow == 1
duplicates drop PATIENT_ID, force

* IMD for successful swallows only
merge 1:1 PATIENT_ID using ////
	"/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT_clean.dta"
drop if _merge == 2

tab IMD, m matcell(A)
putexcel R27 = matrix(A)
tabstat IMD, s(median p25 p75) save
matrix D = r(StatTotal)
putexcel R21 = matrix(D)

********************************************************************************
* REPORT ON BE DIAGNOSES
********************************************************************************

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEdiagnoses.dta", ///
	clear
set more off

*** CLEANING

tab Site, m
replace Site = "B3GBAD" if Site == "B3GBAD "
br if Site == ""
drop if Site == ""

tab CAPAID, m

tab PatientID, m
br if PatientID == "B3BGY0074" | PatientID == "B3BYM0037"
replace PatientID = "B3GBGY0074" if PatientID == "B3BGY0074"
replace PatientID = "B3GBYM0037" if PatientID == "B3BYM0037"

tab Typeofpatient, m
replace Typeofpatient = "Intervention (Atypia)" ///
	if Typeofpatient == "Intervention  (Atypia)"
replace Typeofpatient = "Intervention (Equivocal result)" ///
	if Typeofpatient == "Intervention  (Equivocal result)"

tab Diagnosis, m

tab GM, m // ?
drop GM

tab Codedrecord, m
replace Codedrecord = "No - missed" if Codedrecord == "No missed"

tab Foundvia, m
replace Foundvia = "N/A - CS only" if Foundvia == "N/A- CS only"

tab Matched, m

tab Diagnosed, m

tab Comments, m

*** REPORT

* Macro-categories for Diagnosis
tab Diagnosis, m
br if Diagnosis == "Barretts mucosa"
// Queried with Beth (10/01): This should be counted as a BE
br if Diagnosis == "BE (Misc)"

* This patient has a GAC diagnosis
* (see Beth and Rebecca's update on staging 18/02)
replace Diagnosis = "GAC" if PatientID == "B3GBGR0057"

* This patient has BE and no basal crypt
* (see Beth and Rebecca's update on staging 18/02)
replace Diagnosis = "BE (Indefinite)" if PatientID == "B3GBHE0060"

gen Diag = 0
replace Diag = 1 if Diagnosis == "BE" | Diagnosis == "BE (Indefinite)" | ///
	Diagnosis == "BE (Misc)" | Diagnosis == "BE with HGD" | ///
	Diagnosis == "BE with LGD" | Diagnosis == "BE with LGD (Basal crypt)" ///
	| Diagnosis == "Barretts mucosa" | Diagnosis == "OAC" | ///
	Diagnosis == "OAC RIP"
label define Diag 0 "GAC" 1 "BE/OAC"
label values Diag Diag
tab Diag, m
// 164 BEs/OACs

gen DiagDetail = 0 if Diag == 0
replace DiagDetail = 1 if Diagnosis == "BE" | Diagnosis == "BE (Misc)" | ///
	Diagnosis == "Barretts mucosa"
replace DiagDetail = 2 if Diagnosis == "BE (Indefinite)"
//replace DiagDetail = 3 if Diagnosis == "BE with LGD (Basal crypt)"
replace DiagDetail = 3 if Diagnosis == "BE with LGD"
replace DiagDetail = 4 if Diagnosis == "BE with HGD"
replace DiagDetail = 5 if Diagnosis == "OAC" | Diagnosis == "OAC RIP"
label define diaglab 0 "GAC" 1 "BE - no dysplasia" ///
	2 "BE - indef. dysplasia" ///
	/*3 "BE with LGD - basal crypt"*/	3 "BE with LGD" 4 "BE with HGD" 5 "OAC"
label values DiagDetail diaglab
tab DiagDetail
	
* REPORT ON DATA COLLECTION METHODS

tab Codedrecord if Diag == 1

gen CodedSearch = 0
replace CodedSearch = 1 if Diag == 1 & (Codedrecord == "Yes" | ///
	Codedrecord == "Yes via OGD  code only")
replace CodedSearch = 2 if Diag == 1 & Codedrecord == "TBC"
label define Coded 0 "No" 1 "Yes" 2 "TBC"
label values CodedSearch Coded
tab CodedSearch, m
drop Codedrecord

tab Foundvia if Diag == 1

gen CNR = 0 if Diag == 1
replace CNR = 1 if Diag == 1 & (Foundvia == "Yes" | Foundvia == "Yes - Misc")
replace CNR = 2 if Diag == 1 & (Foundvia == "N/A" | Foundvia == "N/A - CS only")
// "N/A not reported as BE"  counts as a NO
label define CNR 0 "No" 1 "Yes" 2 "N/A"
label values CNR CNR
tab CNR, m

tab CodedSearch CNR, m

gen Method1 = 0 if Diag == 1
replace Method1 = 1 if Diag == 1 & (CodedSearch == 1 | CNR == 1)
replace Method1 = . if CodedSearch == 2 & CNR == 2
tab Method1
// 6.7% missed with CodedSearch + CNR

tab Matched, m

gen NHSlinkage = .
replace NHSlinkage = 1 if Diag == 1 & (Matched == "Yes" | ///
	Matched == "Yes but as Z line" | ///
	Matched == "Yes as GM only")
replace NHSlinkage = 0 if Diag == 1 & Matched == "No"
label define NHSlab 0 "No" 1 "Yes"
label values NHSlinkage NHSlab
tab NHSlinkage
// 17.4% missed with NHSlinkage

tab Method1 NHSlinkage, m
gen Method12 = 0 if Diag == 1
replace Method12 = 1 if Diag == 1 & (Method1 == 1 | NHSlinkage == 1)
replace Method12 = . if (Method1 == . & NHSlinkage == .)
tab Method12
// 0.6% missed with CodedSearch + CNR + NHSlinkage (1 record only)

tab Diagnosed, m
gen TrialDiagnosis = 0 if Diag == 1
replace TrialDiagnosis = 1 if Diag == 1 & ///
	(Diagnosed == "Yes" | Diagnosed == "Yes (Misc)")
label values TrialDiagnosis NHSlab
tab TrialDiagnosis
// B3GBCW0058 does not count as a Trial diagnosis
// B3GBSK0099 not counted as a Trial diagnosis

tab Method12 TrialDiagnosis, m
list PatientID if Method12 == 0 & TrialDiagnosis == 1
// B3GBBY0079 will not contribute to primary endpoint analysis

*** CREATE DATASET WITH BEs and CANCERS FOR PRIMARY ENDPOINT ANALYSIS

keep PatientID Method12 DiagDetail
rename Method12 PrimaryEndpt
//drop if PrimaryEndpt == 0

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryBE.dta", ///
	replace

********************************************************************************
* ADD REBECCA's UPDATE ON STAGING (18/02)

drop if DiagDetail == 1 | DiagDetail == 2

gen ID = substr(PatientID, 1, 6)
replace ID = PatientID if ID == "B3GBBG"

merge 1:1 ID using ///
	"/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/DysplasiaCancerStage.dta"
// 1 not used from master

br PatientID DiagDetail Staging Stage

replace DiagDetail = 6 if DiagDetail == 5 & Stage == "Stage 2"
replace DiagDetail = 7 if DiagDetail == 5 & Stage == "Stage 3"
replace DiagDetail = 8 if DiagDetail == 5 & Stage == "Stage 4" | ///
	Stage == "Stage 4 "
label define diaglab 5 "Stage 1" 6 "Stage 2" ///
	7 "Stage 3" 8 "Stage 4", modify

drop ID Site-Routine Stage-_merge Patient

merge 1:1 PatientID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryBE.dta"

drop _merge

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PrimaryBE.dta", ///
	replace

log close
