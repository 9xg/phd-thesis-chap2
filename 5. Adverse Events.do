version 15
log using "5", replace

use "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/AE_SAE_CRF.dta", clear
set more off

****
putexcel set "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Results/StatisticalReport.xlsx", sheet("AEs") modify
****

describe

duplicates tag PATIENT_ID, gen(dup)
tab dup
drop dup
// 0: OK

tab MEDDRA_CODE, m
br if MEDDRA_CODE == .
// 2 missing --> but MEDDRA_TERM non missing, so OK

tab MEDDRA_TERM, m

* Are these all patients who received the Cytosponge?
merge 1:m PATIENT_ID using "/Users/gehrun01/Desktop/best3-analysis/26.1 Final analysis/Working/CYTOSPONGE_PROCEDURE_CRF_clean.dta"
// Yes, they all received the Cytosponge
// Some have AEs registered even if they failed to swallow
sort PATIENT_ID
br PATIENT_ID SuccessfulSwallow if _merge == 3
br if PATIENT_ID == "B3GBCP0007" // SAE: Cytosponge detachment
br if PATIENT_ID == "B3GBHE0095" // Unable to swallow --> delete from AEs
br if PATIENT_ID == "B3GBPE0091" // 2 tests
br if PATIENT_ID == "B3GBQJ0062" // Unable to swallow --> delete from AEs

***
* AEs were collected only from patients unable to swallow, except for the cases
* above
drop if PATIENT_ID == "B3GBHE0095" | PATIENT_ID == "B3GBQJ0062"
***

drop if _merge == 2
drop _merge

// let's drop repeat tests
duplicates drop PATIENT_ID, force

* Group adverse events
gen AE = 0 if ///
	MEDDRA_TERM == "Dry and sore throat" | ///
	MEDDRA_TERM == "Local throat irritation" | ///
	MEDDRA_TERM == "Sore throat NOS" | ///
	MEDDRA_TERM == "uncomfortable throat" | ///
	MEDDRA_TERM == "Laryngeal discomfort" | ///
	MEDDRA_TERM == "Sore throat" | ///
	MEDDRA_TERM == "Dysphagia" | ///
	MEDDRA_TERM == "Swallowing impaired." | ///
	MEDDRA_TERM == "Neck stiffness"
replace AE = 1 if ///
	MEDDRA_TERM == "Acid indigestion" | ///
	MEDDRA_TERM == "Acid reflux (oesophageal)" | ///
	MEDDRA_TERM == "Character change in dyspepsia" | ///
	MEDDRA_TERM == "Heartburn aggravated" | ///
	MEDDRA_TERM == "Heartburn-like dyspepsia" | ///
	MEDDRA_TERM == "Increased Indigestion symptoms" | ///
	MEDDRA_TERM == "Oesophageal reflux aggravated"
replace AE = 2 if ///
	MEDDRA_TERM == "Abdo pain" | ///
	MEDDRA_TERM == "Abdominal discomfort" | ///
	MEDDRA_TERM == "Abdominal pain upper" | ///
	MEDDRA_TERM == "Abdominal pain" | ///
	MEDDRA_TERM == "Ache stomach" | ///
	MEDDRA_TERM == "Stomach cramps" | ///
	MEDDRA_TERM == "Sore oesophagus" | ///
	MEDDRA_TERM == "Epigastric pain" | ///
	MEDDRA_TERM == "Epigastric pain not food-related" | ///
	MEDDRA_TERM == "Oesophageal or gastric pain" | ///
	MEDDRA_TERM == "Foreign body feeling of oesophagus" | ///
	MEDDRA_TERM == "Oesophageal discomfort" | ///
	MEDDRA_TERM == "Hiatus hernia"
replace AE = 3 if ///
	MEDDRA_TERM == "Adverse event" | ///
	MEDDRA_TERM == "Adverse event NOS" | ///
	MEDDRA_TERM == "Feeling unwell" | ///
	MEDDRA_TERM == "Feelings of weakness" | ///
	MEDDRA_TERM == "Fever chills" | ///
	MEDDRA_TERM == "Felt vague"
replace AE = 4 if ///
	MEDDRA_TERM == "Vomited" | ///
	MEDDRA_TERM == "Vomiting" | ///
	MEDDRA_TERM == "Gagging" | ///
	MEDDRA_TERM == "Nausea" | ///
	MEDDRA_TERM == "Nausea alone" | ///
	MEDDRA_TERM == "Nausea/vomiting" | ///
	MEDDRA_TERM == "Nauseated" | ///
	MEDDRA_TERM == "Regurgitation"
replace AE = 5 if ///
	MEDDRA_TERM == "Voice alteration" | ///
	MEDDRA_TERM == "Hoarse voice" | ///
	MEDDRA_TERM == "Other voice disturbance" | ///
	MEDDRA_TERM == "Voice disturbance"
replace AE = 6 if ///
	MEDDRA_TERM == "Upset stomach" | ///
	MEDDRA_TERM == "Acute diarrhea" | ///
	MEDDRA_TERM == "Diarrhea" | ///
	MEDDRA_TERM == "Abdominal wind" | ///
	MEDDRA_TERM == "Gas in stomach"
replace AE = 7 if ///
	MEDDRA_TERM == "Chest discomfort" | ///
	MEDDRA_TERM == "Pain chest"
replace AE = 8 if ///
	MEDDRA_TERM == "Allergic reaction"
replace AE = 9 if ///
	MEDDRA_TERM == "Anxiety"
replace AE = 10 if ///
	MEDDRA_TERM == "Bad taste"
replace AE = 11 if ///
	MEDDRA_TERM == "Benign paroxysmal positional vertigo"
replace AE = 12 if ///
	MEDDRA_TERM == "Blood clot excretion"
replace AE = 13 if ///
	MEDDRA_TERM == "Vaso vagal attack"
replace AE = 14 if ///
	MEDDRA_TERM == "Nose bleed"
replace AE = 15 if ///
	MEDDRA_TERM == "Headache" | ///
	MEDDRA_TERM == "Persistent headache"
replace AE = 16 if ///
	MEDDRA_TERM == "Bloodshot eye"
replace AE = 17 if ///
	MEDDRA_TERM == "Chest infection"
replace AE = 18 if ///
	MEDDRA_TERM == "Abrasion NOS"
replace AE = 19 if ///
	MEDDRA_TERM == "Fall"
replace AE = 20 if ///
	MEDDRA_TERM == "Hospitalisation"
replace AE = 21 if ///
	MEDDRA_TERM == "Hospitalisation" & strpos(EVENT_NARRATIVE, "Detachment") != 0
replace AE = 22 if ///
	MEDDRA_TERM == "Abdo pain" & IS_SAE == "Y"
replace AE = 23 if ///
	MEDDRA_TERM == "Acute myocardial infarction, unspecified site"
label define AElab ///
	0 "Sore throat" ///
	1 "Dyspepsia/indigestion/reflux/acid reflux" ///
	2 "Oesophageal or gastric pain/discomfort" ///
	3 "Not otherwise specified" ///
	4 "Nausea/vomiting" ///
	5 "Voice disturbance" ///
	6 "Diarrhea/upset stomach" ///
	7 "Chest pain or discomfort" ///
	8 "Allergic reaction" ///
	9 "Anxiety" ///
	10 "Bad taste" ///
	11 "Benign paroxysmal positional vertigo" ///
	12 "Blood clot excretion" ///
	13 "Vasovagal attack" ///
	14 "Nose bleed" ///
	15 "Headache" ///
	16 "Bloodshot eye" ///
	17 "Chest infection" ///
	18 "Abrasion" ///
	19 "Fall" ///
	20 "Loss of consciousness following minor accident (Day 3)" ///
	21 "Detachment (Day of procedure)" ///
	22 "Hernia repair (Pain day 3, surgery day 5)" ///
	23 "Myocardial infarction (Day 3)"
label values AE AElab
tab AE, m

tab SEVERITY, m
tab AE SEVERITY, m

* SAEs
tab IS_SAE, m
// 4 SAEs
tab IS_SAE SEVERITY, m
tab AE SEVERITY if IS_SAE == "Y"
replace SEVERITY = 3 if IS_SAE == "Y"
tab AE SEVERITY if IS_SAE == "Y"

tab AE SEVERITY, matcell(A)
matrix rownames A = ///
	"Sore throat" ///
	"Dyspepsia indigestion reflux" ///
	"Oesophageal or gastric pain" ///
	"Not otherwise specified" ///
	"Nausea/vomiting" ///
	"Voice disturbance" ///
	"Diarrhea/upset stomach" ///
	"Chest pain or discomfort" ///
	"Allergic reaction" ///
	"Anxiety" ///
	"Bad taste" ///
	"Paroxysmal positional vertigo" ///
	"Blood clot excretion" ///
	"Vasovagal attack" ///
	"Nose bleed" ///
	"Headache" ///
	"Bloodshot eye" ///
	"Chest infection" ///
	"Abrasion" ///
	"Fall" ///
	"Unconscious after minor accident" ///
	"Detachment (Day of procedure)" ///
	"Hernia repair (surgery day 5)" ///
	"Myocardial infarction (Day 3)"
matrix colnames A = "Low" "Moderate" "High"
putexcel A2 = matrix(A), names

log close
