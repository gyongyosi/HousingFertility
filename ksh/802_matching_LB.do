* load merged dataset
local start = 1 // 1 thru 9
local next = `start' + 1
use "${temp}/cross_`start'_`next'", clear

* compute dummies for comparing which variables (beyond baby and mom's birth year and month) are matched
foreach X in d_prev d_mother y_father m_father d_father y_marriage m_marriage d_marriage edu_mother edu_father notart fitart {
	gen match_`X' = 0
	* when determining whether two date parts match, any missing value precludes a match
	* but matching "not married" 0s in marriage variable count as exact match
	replace match_`X' = 1  if (`X'_`next' == `X'_`start') & (`X'_`next' != .) & (`X'_`start' != .)
}
* exact (day) or approximate (month) match for four main dates
gen exactBaby = (match_d_prev==1)
gen exactMother = (match_d_mother==1)
gen approxFather = (match_y_father==1 & match_m_father==1)
gen exactFather = (match_y_father==1 & match_m_father==1 & match_d_father==1)
gen approxMarriage = (match_y_marriage==1 & match_m_marriage==1)
gen exactMarriage = (match_y_marriage==1 & match_m_marriage==1 & match_d_marriage==1)

* for education tiebreaker, flag matches where mother education regressed
gen flagMotherEdu = 0
replace flagMotherEdu = (edu_mother_`start' > edu_mother_`next') & edu_mother_`start'!=. & edu_mother_`next'!=.
* for education tiebreaker, flag matches where father education regressed (only flag if approx same father bday, too)
gen flagFatherEdu = 0
replace flagFatherEdu = (edu_father_`start' > edu_father_`next') & approxFather==1 & edu_father_`start'!=. & edu_father_`next'!=.

* construct first component of composite similiarity score from inputs of matched date dummies
gen bucket = 0
* sufficient condition: exact birthday of baby and exact birthday of mother
replace bucket = 4 if (exactBaby==1 & exactMother==1)
* either one of baby and mother exact: need both father and marriage to be approx, and at least one to be exact
replace bucket = 3 if (exactBaby + exactMother == 1) & (approxFather==1 & approxMarriage==1) & (exactFather==1 | exactMarriage==1)
* relax here: one of baby and mother exact, none of father and marriage exact, but moms education and location
replace bucket = 2 if (exactBaby + exactMother == 1) & (approxFather==1 & approxMarriage==1) & match_notart==1 & match_edu_mother==1
* sufficient condition: only month for both baby and mother, but exact birthday for father and exact day for marriage
replace bucket = 1 if (exactBaby + exactMother == 0) & (exactFather==1 & exactMarriage==1)

* create composite match variable for education variables: takes values 0, 0.6, or 1.1
gen eduTiebreakerMother = (1.2 + match_edu_mother - 1.2*flagMotherEdu) / 2
gen eduTiebreakerFather = (1.2 + match_edu_father - 1.2*flagFatherEdu) / 2
* tiebreaker 1: combine 2 educations and 2 locations: takes values, 0-9.5 at 0.5 intervals AND 0.1 and 9.9 
gen allTiebreaker = (4*match_notart + 3*match_fitart + 2*eduTiebreakerMother + eduTiebreakerFather) / 10.3

* tiebreaker 2: create composite match variable for the "negotiable" subset of dates (father > marriage bc not married idiosyncrasies)
gen bonus = 3*approxFather + 3*exactFather + 2*approxMarriage + 2*exactMarriage
replace bonus = 1 if bonus==0
replace bonus = 9 if bonus==10
replace bonus = bonus / 10


* generate score with tiebreakers
gen score = 0
replace score = 100*bucket + 10*allTiebreaker + 1*bonus
* check scores
tab score
* acceptable matches are 100 or above
keep if score >= 100

********************************************************************************
** summer2026: better adjudicate when 2 later IDs are matching best to same earlier ID
********************************************************************************
local proceed = 1

forvalues ii=1(1)3 {

** identifying later IDs who have competitors for their fav earlier ID ("worried suitors")

preserve // preserve all acceptable matches
* within 2nd baby ID: compute best match
egen max_score = max(score), by(id_baby_`next')
* keep only best acceptable match within later baby ID 
keep if score==max_score
* identify earlier IDs that are claimed by 2 different later IDs
duplicates tag id_baby_`start', gen(gotMultSuitors)
* generate list of later IDs who are worried suitors
keep if gotMultSuitors==1

if _N==0 {
	local proceed = 0
}

if `proceed'==1 {
keep id_baby_`next'
duplicates drop id_baby_`next', force
tempfile worriedSuitors
save `worriedSuitors'
}
restore

if `proceed'==1 {
* identify whether these later IDs ("worried suitors") have other acceptable matches
merge m:1 id_baby_`next' using `worriedSuitors'
* flag these worried suitors with worriedSuitor variable
gen worriedSuitor = 0
replace worriedSuitor = 1 if _merge==3
drop _merge
* identify later IDs that have multiple acceptable matches
duplicates tag id_baby_`next', gen(otherOptions)
* cross-tab to see how many of these "worried suitors" have other acceptable matches
tab worriedSuitor otherOptions

********************************************************************************
* step 1: let later IDs with competition but no other acceptable matches claim their best score(s)

preserve
* identify step 1 winners
keep if (worriedSuitor==1 & otherOptions==0)
* identify earlier IDs who will accept step 1 winners
keep id_baby_`start'
duplicates drop id_baby_`start', force
tempfile acceptsStep1
save `acceptsStep1'
restore

* then, merge to identify competition for step 1 winners
merge m:1 id_baby_`start' using `acceptsStep1'
* flag these competitors with wasCompeting variable
gen wasCompeting = 0
replace wasCompeting = 1 if _merge==3
drop _merge
* step 1 really happens here: drop competition who had other acceptable options
drop if (worriedSuitor==1 & wasCompeting==1 & otherOptions > 0)
* re-cross-tab to see who dropped in step 1
tab worriedSuitor otherOptions

drop worriedSuitor otherOptions wasCompeting
}
}
********************************************************************************

local proceed = 1
forvalues jj=1(1)3 {

** identifying later IDs who have competitors for their fav earlier ID ("worried suitors")

preserve // preserve all acceptable matches
* within 2nd baby ID: compute best match
egen max_score = max(score), by(id_baby_`next')
* keep only best acceptable match within later baby ID 
keep if score==max_score
* identify earlier IDs that are claimed by 2 different later IDs
duplicates tag id_baby_`start', gen(gotMultSuitors)
* generate list of later IDs who are worried suitors
keep if gotMultSuitors==1

if _N==0 {
	local proceed = 0
}
if `proceed'==1 {
keep id_baby_`next'
duplicates drop id_baby_`next', force
tempfile worriedSuitors
save `worriedSuitors'
}
restore

if `proceed'==1 {
* identify whether these later IDs ("worried suitors") have other acceptable matches
merge m:1 id_baby_`next' using `worriedSuitors'
* flag these worried suitors with worriedSuitor variable
gen worriedSuitor = 0
replace worriedSuitor = 1 if _merge==3
drop _merge
* identify later IDs that have multiple acceptable matches
duplicates tag id_baby_`next', gen(otherOptions)
* cross-tab to see how many of these "worried suitors" have other acceptable matches
tab worriedSuitor otherOptions

********************************************************************************
* step 2: let later IDs with no other acceptable matches claim their best score(s)

preserve
* identify step 2 winners
keep if (otherOptions==0)
* identify earlier IDs who will accept step 2 winners
keep id_baby_`start'
duplicates drop id_baby_`start', force
tempfile acceptsStep2
save `acceptsStep2'
restore

* then, merge to identify competition for step 2 winners
merge m:1 id_baby_`start' using `acceptsStep2'
* flag these competitors with wasCompeting variable
gen wasCompeting = 0
replace wasCompeting = 1 if _merge==3
drop _merge
* step 2 really happens here: drop competition who had other acceptable options
drop if (wasCompeting==1 & otherOptions > 0)
* re-cross-tab to see who dropped in step 2
tab worriedSuitor otherOptions

drop worriedSuitor otherOptions wasCompeting
}
}

*************************************************************************

forvalues kk=1(1)3 {

	* step 3: when both later IDs have other acceptable matches, give earlier ID to its best suitor
	duplicates tag id_baby_`next', gen(otherOptions)

	* let earlier ID pick their best score
	egen max_suitor_score = max(score), by(id_baby_`start')
	drop if (score < max_suitor_score & otherOptions > 0)

	drop otherOptions max_suitor_score
}

* step 4: when neither later ID has other options: give earlier ID to its best suitor
egen max_score = max(score), by(id_baby_`next')
gen fav = (score==max_score)
egen max_suitor_score = max(score), by(id_baby_`start')
gen bestSuitor = (score==max_suitor_score)
tab fav bestSuitor
drop if (score < max_suitor_score) 
tab fav bestSuitor
drop max_score fav max_suitor_score bestSuitor

* step 5: let later IDs pick their favorite
egen max_score = max(score), by(id_baby_`next')
drop if score < max_score
drop max_score

** last: have to drop genuine ties that have same fundamental match structure
local allMatchVars exactBaby exactMother approxFather exactFather approxMarriage exactMarriage match_notart match_fitart match_edu_mother match_edu_father flagMotherEdu flagFatherEdu

* genuine ties within LATER IDs
local proceed = 1
* give each match a unqiue ID called tempCount
sort id_baby_`next' id_baby_`start' score
gen tempCount = _n
* identify remaining non-unique matches
duplicates tag id_baby_`next', gen(otherOptions)
duplicates tag id_baby_`start', gen(otherSuitors)
* remove duplicates within non-unique LATER IDs
preserve 
keep if otherOptions > 0
if _N==0 {
	local proceed = 0
}
if `proceed'==1 {
duplicates tag id_baby_`next' `allMatchVars', gen(haveToDrop)
keep if haveToDrop > 0
keep tempCount
tempfile haveToDrop1
save `haveToDrop1'
}
restore
if `proceed'==1 {
* merge back in
merge m:1 tempCount using `haveToDrop1'
* remove duplicates here
drop if _merge==3
drop _merge
}
drop tempCount otherOptions otherSuitors

* genuine ties within EARLIER IDs
local proceed = 1
* give each match a unqiue ID called tempCount
sort id_baby_`next' id_baby_`start' score
gen tempCount = _n
* identify remaining non-unique matches
duplicates tag id_baby_`next', gen(otherOptions)
duplicates tag id_baby_`start', gen(otherSuitors)
* remove duplicates within non-unique EARLIER IDs
preserve 
keep if otherSuitors > 0
if _N==0 {
	local proceed = 0
}
if `proceed'==1 {
duplicates tag id_baby_`start' `allMatchVars', gen(haveToDrop)
keep if haveToDrop > 0
keep tempCount
tempfile haveToDrop2
save `haveToDrop2'
}
restore
if `proceed'==1 {
* merge back in
merge m:1 tempCount using `haveToDrop2'
* remove duplicates here
drop if _merge==3
drop _merge
}
drop tempCount otherOptions otherSuitors 

* last check, should be all good though
duplicates tag id_baby_`next', gen(otherOptions)
tab otherOptions
drop if otherOptions > 0
duplicates tag id_baby_`start', gen(otherSuitors)
tab otherSuitors
drop if otherSuitors > 0

* clean up
rename notart* loc_mother*
rename fitart* loc_father*
rename m_mother m_mother_`start'_`next'
rename y_mother y_mother_`start'_`next'
* rename these 2 variables to match d_prev, tho they are data for `next' kid
rename m_prev m_prev_`next'
rename y_prev y_prev_`next'

keep id_baby_* ///
	d_prev* d_mother* d_father* d_marriage* d_baby_`next' ///
	m_prev* m_mother* m_father* m_marriage* m_baby_`next' ///
	y_prev* y_mother* y_father* y_marriage* y_baby_`next' ///
	td_prev* td_mother* td_father* td_marriage* td_baby_`next' ///
	tm_prev* tm_mother* tm_father* tm_marriage* tm_baby_`next' ///
	ty_prev* ty_mother* ty_father* ty_marriage* ty_baby_`next' ///
	loc_mother* edu_mother* loc_father* edu_father*  ///
	nem* 
order id_baby_`start' id_baby_`next' ?_prev* ??_prev* ///
	?_mother* ??_mother* ?_father* ??_father* ?_marriage* ??_marriage* *baby_`next' ///
	???_mother* ???_father* nem*
* save
count
save "${temp}/crosswalk_`start'_`next'", replace