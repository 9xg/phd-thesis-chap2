version 15
set more off

log using "1", replace

********************************************************************************
*** IMPORT
********************************************************************************

* BEST3_PATIENT
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/BEST3_PATIENT.xlsx", ///
	sheet("BEST3_PATIENT") firstrow clear

count if PATIENT_ID == ""

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT.dta", ///
	replace

* BASELINE_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/BASELINE_CRF.xlsx", ///
	sheet("BASELINE_CRF") firstrow clear

count if PATIENT_ID == ""

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BASELINE_CRF.dta", ///
	replace

* MEDICATION_SUBFORM
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/MEDICATION_SUBFORM.xlsx", ///
	sheet("MEDICATION_SUBFORM") firstrow clear

duplicates report RECORD_ID // unique --> 1 line per medication taken?
duplicates report CRF_ID // patientID?

merge m:1 CRF_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BASELINE_CRF.dta"
drop if _merge == 1
drop CRF_VERSION-_merge

order PATIENT_ID RECORD_ID
	
save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/MEDICATION_SUBFORM.dta", ///
	replace

* CYTOSPONGE_PROCEDURE_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/CYTOSPONGE_PROCEDURE_CRF.xlsx", ///
	sheet("CYTOSPONGE_PROCEDURE_CRF") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF.dta", ///
	replace

* PATH_REPORTH_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/PATH_REPORT_CRF.xlsx", ///
	sheet("PATH_REPORT_CRF") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PATH_REPORT_CRF.dta", ///
	replace

* ENDOSCOPY_PATH_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/ENDOSCOPY_PATH_CRF.xlsx", ///
	sheet("ENDOSCOPY_PATH_CRF") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/ENDOSCOPY_PATH_CRF.dta", ///
	replace

* ENDOSCOPY_PROCEDURE_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/ENDOSCOPY_PROCEDURE_CRF.xlsx", ///
	sheet("ENDOSCOPY_PROCEDURE_CRF") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/ENDOSCOPY_PROCEDURE_CRF.dta", ///
	replace

* Cytosponge Results Excel Report
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/Cytosponge Results Excel Report.xls", ///
	sheet("Cytoponge Results Excel Report") firstrow clear

gen Site = substr(PatientID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/Cytosponge Results Excel.dta", ///
	replace	

* AE_SAE_CRF
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/AE_SAE_CRF.xlsx", ///
	sheet("AE_SAE_CRF") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/AE_SAE_CRF.dta", ///
	replace	

* deprivation index
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/2019-deprivation-by-postcode.xlsx", ///
	sheet("Sheet1") firstrow clear

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/2019-deprivation-by-postcode.dta", ///
	replace

* ENDPOINT DATA: OVERVIEW - GP
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/Endpoint data v1.3 - 17 February 2020.xlsx", sheet("Overview - GP sites") firstrow clear

rename SiteID Site
tab Site, m
drop if Site == ""
drop U-AZ

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/OverviewGPsites.dta", ///
	replace

* ENDPOINT DATA: PRIMARY ENDPOINT
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/Endpoint data v1.3 - 17 February 2020.xlsx", sheet("BE diagnoses") firstrow clear
set more off

drop L

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEdiagnoses.dta", ///
	replace

* FOLLOWUP QUESTIONNAIRE
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/FOLLOWUP_QUESTIONNAIRE.xlsx", sheet("FOLLOWUP_QUESTIONNAIRE") firstrow clear

gen Site = substr(PATIENT_ID, 5, 2)
tab Site, m
drop if Site == "XX" | Site == "YK"

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/FOLLOWUP_QUESTIONNAIRE.dta", ///
	replace

* DYSPLASIA AND CANCER STAGING
import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/Data for Nick - 18 February 2020 (2).xlsx", sheet("Sheet1") firstrow clear

gen ID = Site
replace ID = "B3GBBG0144" if Site == "B3GBBG" & Months == 12
replace ID = "B3GBBG0194" if Site == "B3GBBG" & Months == 11

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/DysplasiaCancerStage.dta", ///
	replace
	
********************************************************************************
*** CREATE DATASETS
********************************************************************************

* LIST OF PATIENTS WITH STUDY ARM (USUAL OR INTERVENTION)
use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT.dta", ///
	clear
set more off

tab INTRO_LETTER_RESPONSE, m
tab Site if INTRO_LETTER_RESPONSE == "O"

*** OPT-OUTS
drop if INTRO_LETTER_RESPONSE == "O"
***

keep PATIENT_ID STUDY_ARM

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/PatientArm.dta", ///
	replace

********************************************************************************
* WITH SITE AND TYPE OF RANDOMISATION (CLR or PLR)
use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT.dta", ///
	clear
set more off

tab INTRO_LETTER_RESPONSE, m
tab Site if INTRO_LETTER_RESPONSE == "O"

*** OPT-OUTS
drop if INTRO_LETTER_RESPONSE == "O"
***

sort Site
bysort Site: gen Size = _N

keep Site STUDY_ARM Size
drop if STUDY_ARM == ""
duplicates drop Site STUDY_ARM, force
duplicates tag Site, gen(dup)
tab dup

gen RandGroup = 0 if dup == 0
replace RandGroup = 1 if dup == 1
label define RandGroup 0 "CLR" 1 "PLR"
label values RandGroup RandGroup

keep Site RandGroup STUDY_ARM Size
duplicates drop Site RandGroup, force

gen StudyArm = 0 if STUDY_ARM == "U" & RandGroup == 0
replace StudyArm = 1 if STUDY_ARM == "I" & RandGroup == 0
replace StudyArm = 2 if RandGroup == 1
label define StudyArm 0 "Usual care" 1 "Intervention" 2 "PLR"
label values StudyArm StudyArm

drop STUDY_ARM

tab RandGroup, m
// 75 CLR, 34 PLR sites

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SiteArm.dta", ///
	replace

********************************************************************************
* WITH SC_ID and SITE NAMES

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/BEST3_PATIENT.dta", ///
	clear
set more off

tab Site, m
//drop if Site == "XX" | Site == "YK"

keep SC_ID Site
duplicates drop SC_ID Site, force

* Check correspondence between SC_ID and Site
duplicates report SC_ID
duplicates report Site
// OK

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SCID_Site.dta", ///
	replace

********************************************************************************
* ENDOSCOPY DATES

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/ENDOSCOPY_PROCEDURE_CRF.dta", clear
set more off

tab PROCEDURE_DATE, m
gen EndoscopyDate = date(PROCEDURE_DATE, "DM20Y")
format EndoscopyDate %tdDD/NN/CCYY
summ EndoscopyDate, de format
// 5 missing and 1 date in 2040???

rename PATIENT_ID PatientID
keep PatientID EndoscopyDate

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/EndoscopyDate.dta", replace

********************************************************************************
* FOLLOW-UP LENGTHS BY SITE

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/OverviewGPsites.dta", ///
	clear
set more off

keep Site Datesitepassedoptoutperiod NumberofmonthsofFollowup Followupperiod

tab Site, m
br if Site == ""
drop if Site == ""

save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/FUspreadsheet.dta", replace

********************************************************************************
* CODED_SEARCH_CRF - IMPORT and CLEAN

import excel "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Datasets/CODED_SEARCH_CRF.xlsx", sheet("CODED_SEARCH_CRF") firstrow clear
set more off

tab CRF_ID, m
duplicates report CRF_ID
// all codes of CRF_ID appear once

tab PATIENT_ID, m
duplicates report PATIENT_ID
// all codes of PATIENT_ID appear once

* Is PATIENT_ID = SC_ID?
describe PATIENT_ID
destring PATIENT_ID, gen(SC_ID)
drop PATIENT_ID
merge 1:1 SC_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/SCID_Site.dta"

br if _merge == 1
// This is the test site
drop if _merge == 1
drop _merge

tab CRF_VERSION, m
count if CRF_VERSION != 1
// 0: OK

tab EDIT_STATUS, m
// What is the meaning of EDIT_STATUS = C or O? --> queried with Beth (03/01)
// --> She opens and closes them 

tab EVENT, m
// all missing
drop EVENT

tab BASELINE_DATE, m
describe BASELINE_DATE
gen BaselineDate = date(BASELINE_DATE, "DM20Y")
format BaselineDate %tdDD/NN/CCYY
drop BASELINE_DATE
summ BaselineDate, de format
// April 2017 to March 2019
count if BaselineDate == .
// 0 missing

tab ENDPOINT_DATE, m
describe ENDPOINT_DATE
gen EndpointDate = date(ENDPOINT_DATE, "DM20Y")
format EndpointDate %tdDD/NN/CCYY
drop ENDPOINT_DATE
summ EndpointDate, de format
// April 2018 to November 2019
count if EndpointDate == .
// 0 missing

gen FUdays = (EndpointDate - BaselineDate)
tab FUdays, m
gen FUmths = FUdays/30.44
tab FUmths, m

// Note: sites SM and CT did not perform coded search
// However, CT performed a manual review of their notes

*** SAVE DATASET ***
save "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CODED_SEARCH_CRF.dta", ///
	replace
********************

log close
