/*==============================================================================
	matching census 2022 with live birth data
	
	what should be consistent?
		mother panel only from LB
	
	variables to be used
		number of kids
		date of birth of kids
		mother's birth date
		mother's education
		father's education
		location
		nationality
	
==============================================================================*/

/*------------------------------------------------------------------------------
	improve kids birth date data in census
		idea: 
			although from mothers' data, we only know kid's birth date at month precision
			if the kid still lives in the same family/household, then we should get the day as well
			this approach also allows us to determine the gender of the kids
			
------------------------------------------------------------------------------*/

use "${census}/szemely", clear
* we are looking for children's exact birthdays so label this _child to prepare for merge 
gen tm_child = ym(szev,ho)
format tm_child %tm
gen td_child = mdy(ho,nap,szev)
format td_child %td

keep if lcstip != 12 /* drop non-families  */
duplicates drop cimazon tm_child, force /* drop people with same birth date (month) living at the same address  */
keep szemazon cimazon lcssor tm_child td_child neme terul

tempfile kids_nontwins
save `kids_nontwins'

use "${census}/szemely", clear
keep if lcstip != 12 /* drop non-families  */
keep if neme == 2
* keep moms born 1965 before or after to match LB for matching
keep if szev >= 1965 

* mother's birth date
gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td
gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm
gen ty_mother_birth = yofd(dofm(tm_mother_birth))
* children's birth month
gen tm_child_1 = ym(elszev, elszho)
gen tm_child_2 = ym(maszev, maszho)
gen tm_child_3 = ym(haszev, haszho)
gen tm_child_4 = ym(neszev, neszho)
gen tm_child_5 = ym(otszev, otszho)
gen tm_child_6 = ym(szev6, ho6)
gen tm_child_7 = ym(szev7, ho7)
gen tm_child_8 = ym(szev8, ho8)
gen tm_child_9 = ym(szev9, ho9)
gen tm_child_10 = ym(uszev, uszho)
foreach X of varlist tm_child* {
	format `X' %tm
}
* mothers education as of 2022 census
gen edu_mother = 0
replace edu_mother = 1 if inlist(irelsz,0,1)
replace edu_mother = 2 if inlist(irelsz,2,3,4)
replace edu_mother = 3 if inlist(irelsz,5,6,7)
replace edu_mother = 4 if inlist(irelsz,8,9,10)
* location as of 2022 census
gen loc_mother = floor(terul / 10)
* marital status as of 2022 census
gen marr_mother = cspot
* month of marriage as of 2022 census
gen tm_marriage = ym(hazev,hazho)
format tm_marriage %tm


* keep variables, especially mom bday and kid bdays
keep szemazon cimazon lcssor td_mother_birth tm_mother_birth ty_mother_birth ///
	tm_child* edu_mother loc_mother marr_mother tm_marriage

** this is where Gyozo fills in exact birthday for kids still living w/ parents
forval i = 1(1)10 {
	
	* adjust variable name for merge
	ren tm_child_`i' tm_child
	* merge here using szemazon instead of cimazon
	merge m:1 cimazon tm_child using `kids_nontwins', nogen keep(1 3)
	* rename variables by birth order 
	ren td_child td_child_`i'
	ren neme nem_`i'
	ren tm_child tm_child_`i'	
	* drop 5th digit of census settlement code to match 4-digit LB version
	gen terul4 = floor(terul / 10)
	drop terul
	ren terul4 terul_`i'
}

* for now, drop these variables but might want neme eventually
drop lcssor cimazon

save "${temp}/census_for_matching_001", replace

/*------------------------------------------------------------------------------
	focusing on live birth data
		what identifies an observation?
		
		drop twins
		
------------------------------------------------------------------------------*/
use "${temp}/LB_002", clear

keep if iker == 1 /* drop twins */
keep if inrange(y_mother, 1965, .) /* keep only cohorts of women who are 49 or younger in 2014 */
* drop if td_baby == .
* drop if td_mother == .
/*
duplicates tag td_baby td_mother, gen(tag_1) /* date of mother, date of birth */
tab tag_1
duplicates tag td_baby td_mother nem, gen(tag_2) /* + gender */ 
tab tag_2
duplicates tag td_baby td_mother nem elve1, gen(tag_3) /* + total number of kids  */
tab tag_3
duplicates tag td_baby td_mother nem elve1 eduCat, gen(tag_4) /* + mother education */
tab tag_4
*/

save "${temp}/LB_for_matching_001", replace

/*==============================================================================
	try to build a mother panel from LB
==============================================================================*/

/*------------------------------------------------------------------------------
	slice the data based on number of kids
------------------------------------------------------------------------------*/

use "${temp}/LB_for_matching_001", clear

summ elve1, d
local max_kids = `r(max)'
forval number_of_kids = 1(1)`max_kids' {
	use "${temp}/LB_for_matching_001", clear
	keep if elve1 == `number_of_kids'
	count
	save "${temp}/LB_for_matching_001_elve1_`number_of_kids'", replace
}

/*------------------------------------------------------------------------------
	approach 1: merging 1:1 on exact birthday of mom and baby
------------------------------------------------------------------------------*/
local start = 9 // fill this in!
local next = `start' + 1
local vars_used_for_matching "td_mother td_prev" /* eduCat */

* load earlier (1/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`start'", clear
count 
* drop birthday of previous baby, and rename earlier birth to match for merging
drop td_prev
ren td_baby td_prev
* drop duplicates on the 1:1 merge variables
duplicates tag `vars_used_for_matching', gen(tag)
tab tag
* duplicates drop `vars_used_for_matching', force
drop if tag>0
drop tag
* save
count
tempfile Q1 
save `Q1'

* load later (2/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`next'", clear

* drop if previous birth birthday is missing
drop if td_prev == .
* drop duplicates on the 1:1 merge variables
duplicates tag `vars_used_for_matching', gen(tag)
tab tag
* duplicates drop `vars_used_for_matching', force
drop if tag>0
drop tag

* merge here!
merge 1:1 `vars_used_for_matching' using `Q1', keep(1 3)
tab _

/*------------------------------------------------------------------------------
approach 2: m:m merge that takes the best one
------------------------------------------------------------------------------*/
local start = 1
local next = `start' + 1
local matching_variables "y_prev m_prev y_mother m_mother"

* load earlier (1/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`start'", clear
* drop previous baby birth day, rename this baby birthday as prev baby birthday
drop tm_prev td_prev d_prev m_prev y_prev
ren tm_baby tm_prev
ren td_baby td_prev
ren d_baby d_prev
ren m_baby m_prev
ren y_baby y_prev

* keep baby ID, birth day, education, and marriage info and location infos
keep id_baby td_* tm_* y_* d_* m_* edu_* nem notart fitart
* rename all variables with _1
foreach X of varlist * {
	ren `X' `X'_`start'
}
* keep matching variables without _X subscript
foreach X of local matching_variables {
	ren `X'_`start'  `X'
}
* save 
count
tempfile Q`start'
save `Q`start''

* load later (2/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`next'", clear

* keep baby ID, birth day, education, and marriage info
keep id_baby td_* tm_* y_* d_* m_* edu_* nem notart fitart
* rename all variables with _2
foreach X of varlist * {
	ren `X' `X'_`next'
}
* keep matching variables without _X subscript
foreach X of local matching_variables {
	ren `X'_`next'  `X'
}
* save 
count
tempfile Q`next'
save `Q`next''

* merge here! via joinby instead of m:m
use `Q`next'', clear
joinby `matching_variables' using `Q`start''
count 
* save joined dataset
save "${temp}/cross_`start'_`next'", replace
* results:
* 1-2: 23,376,190 (set start=1)
* 2-3: 5,066,603 (set start=2)
* 3-4: 546,531 (set start=3)
* 4-5: 90,048 (set start...)
* 5-6: 26,751
* 6-7: 10,013
* 7-8: 4,324
* 8-9: 1,894
* 9-10: 880

********************************************************************************
* load merged dataset
local start = 1
local next = `start' + 1
use "${temp}/cross_`start'_`next'", clear

* compute dummies for which variables are matched
foreach X in d_prev d_mother y_father m_father d_father y_marriage m_marriage d_marriage edu_mother edu_father {
	gen match_`X' = 0
	replace match_`X' = 1  if (`X'_`next' == `X'_`start') & (`X'_`next' != .) & (`X'_`start' != .)
}
* exact (day) or approximate (month) match for four main dates
gen exactBaby = (match_d_prev==1)
gen exactMother = (match_d_mother==1)
gen exactFather = (match_y_father==1 & match_m_father==1 & match_d_father==1)
gen exactMarriage = (match_y_marriage==1 & match_m_marriage==1 & match_d_marriage==1)
gen approxFather = (match_y_father==1 & match_m_father==1)
gen approxMarriage = (match_y_marriage==1 & match_m_marriage==1)
* for education tiebreaker, flag matches where mother education regressed
gen flagMotherEdu = 0
replace flagMotherEdu = (edu_mother_`start' > edu_mother_`next') & edu_mother_`start'!=. & edu_mother_`next'!=.
* flag matches where father education regressed (only concerning if approx same father bday, too)
gen flagFatherEdu = 0
replace flagFatherEdu = (edu_father_`start' > edu_father_`next') & approxFather==1 & edu_father_`start'!=. & edu_father_`next'!=.

* construct first component of composite similiarity score from inputs of matched date dummies
gen bucket = 0
* sufficient condition: exact birthday of baby and exact birthday of mother
replace bucket = 101 if (exactBaby==1 & exactMother==1)
* ONE of baby and mother exact: need both father and marriage to be approx, and at least one to be exact
replace bucket = 100 if (exactBaby + exactMother == 1) & (approxFather==1 & approxMarriage==1) & (exactFather==1 | exactMarriage==1)
* sufficient condition: only month for both baby and mother, but exact birthday for father and exact day for marriage
replace bucket = 99 if (exactBaby + exactMother == 0) & (exactFather==1 & exactMarriage==1)

* tiebreaker 1: create composite match variable for the "negotiable" subset of dates
gen bonus = 1 + 1.1*approxFather + 1.1*exactFather + approxMarriage + exactMarriage
* tiebreaker 2: create composite match variable for education variables
gen eduTiebreaker = 1 + 3*(1 + match_edu_mother - flagMotherEdu) + (1 + match_edu_father - flagFatherEdu) 
* generate score with tiebreakers
gen score = 0
replace score = bucket + 0.1*bonus + 0.01*eduTiebreaker
* check scores
tab score

* within 2nd baby ID: compute best match
egen max_score = max(score), by(id_baby_`next')
* keep only matches, and, if multiple matches, only best match within 2nd baby ID 
keep if (score > 99 & score==max_score)

/**
* these two should match up
duplicates report bonus
duplicates report approxFather exactFather approxMarriage exactMarriage
duplicates report eduTiebreaker
duplicates report match_edu_mother flagMotherEdu match_edu_father flagFatherEdu
* OK if these two do not match up
duplicates report bucket
duplicates report exactBaby exactMother approxFather exactFather approxMarriage exactMarriage
duplicates report score
duplicates report exactBaby exactMother approxFather exactFather approxMarriage exactMarriage match_edu_mother flagMotherEdu match_edu_father flagFatherEdu
**/
* drop duplicates that we cannot identify--Q: will we use the unmatched vars on census merge?
* if not, can keep one version of these?
duplicates report id_baby_`next'
duplicates tag id_baby_`next', gen(isDup_`next')
tab bucket isDup_`next'
drop if isDup_`next' > 0
duplicates report id_baby_`start'
duplicates tag id_baby_`start', gen(isDup_`start')
tab bucket isDup_`start'
drop if isDup_`start' > 0

* clean up
keep id_baby_`next' id_baby_`start' td_baby_`next' td_prev_`next' td_prev_`start' td_mother_`next' td_mother_`start' ///
	edu_mother_`next' edu_father_`next' notart_`next' fitart_`next' nem_`next' td_father_`next' td_marriage_`next'  tm_father_`next' tm_marriage_`next' ///
	edu_mother_`start' edu_father_`start' notart_`start' fitart_`start' nem_`start' td_father_`start' td_marriage_`start'  tm_father_`start' tm_marriage_`start'
order id_baby_`next' id_baby_`start' td_baby_`next' td_prev_`next' td_prev_`start' td_mother_`next' td_mother_`start' ///
	edu_mother_`next' edu_father_`next' notart_`next' fitart_`next' nem_`next' td_father_`next' td_marriage_`next'  tm_father_`next' tm_marriage_`next' ///
	edu_mother_`start' edu_father_`start' notart_`start' fitart_`start' nem_`start' td_father_`start' td_marriage_`start'  tm_father_`start' tm_marriage_`start'
count
* save
save "${temp}/crosswalk_`start'_`next'", replace

*******************************************************************************

* load first crosswalk
use "${temp}/crosswalk_9_10", clear

* loop over merges (8) of adjacent crosswalks (9)
forval kk = 1(1)8 {
	
	* set of locals to descend appripriately
	local late = 11 - `kk' // 10 9 8 7 6 5 4 3
	local mid = `late' - 1 //  9 8 7 6 5 4 3 2
	local early = `late' - 2 //8 7 6 5 4 3 2 1

	* merge later crosswalk with earlier one, using shared baby ID
	* IMPORTANT: keep the usings version of td_prev_MID...
	*... this is "undoing" our previous renaming of earlier dataset's current birth variable
	merge 1:1 id_baby_`mid' using "${temp}/crosswalk_`early'_`mid'", update replace
	* save master observations that did NOT merge in a separate file ("fragments"). theoretically, this all should find a 	match bc those who had a 9th and 10th should have had an eighth. But they don't so will save them as fragements to use in merge somehow. Keep all "using" observations because out of this pool of women who had an 8th kid, we only expect women who had an 9th to match.
	preserve
	keep if _merge==1
	* drop variables that did not get filled in by merge
	drop _merge id_baby_`early' td_mother_`early' td_prev_`early' 
	* drop another variable that did not get filled in merge...
	* ...but the data that did not get filled in for this (DB`mid' -td_baby-KID`mid') is already stored in td_prev_`mid' 
	drop td_baby_`mid' 
	* rename that variable that already stores DB`mid' -td_baby-KID`mid' to reflect that
	rename td_prev_`mid' td_baby_`mid' 
	* save fragment
	save "${temp}/fragments_`mid'_`late'", replace
	restore
	* delete master observations that did NOT merge to enable next merge
	drop if _merge==1
	drop _merge
}

* loop over merges to append files containing fragments
forval kk = 1(1)8 {
	
	local late = 11 - `kk' // 10 9 8 7 6 5 4 3
	local mid = `late' - 1 //  9 8 7 6 5 4 3 2
	* append here
	append using "${temp}/fragments_`mid'_`late'"
}
* undo renaming of earlier dataset's current birth variable for 1st births
rename td_prev_1 td_baby_1

** moms exact birthday, but only care about month for kid bc census doesnt have exact kids bday
* td_mother: 1-10 -- should be all the same, check within dist and collapse into 1
* td_baby: 1-10 -- should match each other on month: td_baby_X vs. td_prev_X+1
* td_prev: 2-10 -- should match each other on month: td_baby_X vs. td_prev_X+1
* id_baby: 1-10 -- save to associate with mother, merge back onto live birth?
* checking mom birthday matches
egen mombday1 = rowmin(td_mother*)
egen mombday2 = rowmax(td_mother*)
gen checkmombday = mombday1==mombday2
tab checkmombday
drop if checkmombday==0
* for these one percent, take mode. but save alternative (esp for only two datapoints for extra merge help)
* br td_mother* if checkmombday==0
rename mombday1 td_mother_birth
format td_mother_birth %td
* create and adjust mom birth date formatting to match census for matching
gen ty_mother_birth = year(td_mother_birth)
gen tm_mother_birth = ym(ty_mother_birth,month(td_mother_birth))
format tm_mother_birth %tm
* clean out variables
drop mombday2 checkmombday td_mother_1 td_mother_2 td_mother_3 td_mother_4 td_mother_5 td_mother_6 td_mother_7 td_mother_8 td_mother_9 td_mother_10

* checking kid birthday matches via td_baby_X vs. td_prev_X+1
forval start = 1(1)10 {
	
	local next = `start' + 1

	* break up dates
	gen y_baby_st = year(td_baby_`start')
	gen m_baby_st = month(td_baby_`start')
	gen d_baby_st = day(td_baby_`start')
	gen tm_baby_`start' = ym(y_baby_st,m_baby_st)
	format tm_baby_`start' %tm
	drop *_st
	
	if `start'!=10 {
	
	gen y_baby_nx = year(td_prev_`next')
	gen m_baby_nx = month(td_prev_`next')
	gen d_baby_nx = day(td_prev_`next')
	gen tm_prev_`next' = ym(y_baby_nx,m_baby_nx)
	drop *_nx

gen flag = 0
replace flag = 1 if (td_baby_`start'!=td_prev_`next' & td_baby_`start'!=. & td_prev_`next'!=.)
tab flag
drop flag

gen flagging = 0
replace flagging = 1 if (tm_baby_`start'!=tm_prev_`next' & tm_baby_`start'!=. & tm_prev_`next'!=.)
tab flagging
drop if flagging==1
drop flagging
}
}
* rename to match census for matching
rename tm_baby_* tm_child_*
rename td_baby_* td_child_*
rename notart_* terul_*
rename fitart_* fatherTerul_*

* save fragments separately
preserve
keep if id_baby_1==.
save "${temp}/lb_panel_onlyFragments", replace
restore
* save non-fragments separately
preserve
drop if id_baby_1==.
save "${temp}/lb_panel_noFragments", replace
restore
* save, including both fragments and non-fragments
save "${temp}/lb_panel", replace


*** add in moms who only had one kid in LB
* load all first births in LB data
use "${temp}/LB_for_matching_001_elve1_1", clear
* rename to match my variable conventions in LB panel
rename td_mother td_mother_birth
rename tm_mother tm_mother_birth
rename y_mother ty_mother_birth
rename id_baby id_baby_1
rename td_baby td_child_1
rename tm_baby tm_child_1
rename edu_mother edu_mother_1 
rename edu_father edu_father_1 
rename notart terul_1 
rename fitart fatherTerul_1 
rename nem nem_1 
rename td_father td_father_1 
rename td_marriage td_marriage_1
rename tm_father tm_father_1 
rename tm_marriage tm_marriage_1
rename nocsal marr_mother_1

* merge using 1st baby ID with non-fragment portion of live birth panel
merge 1:1 id_baby_1 using "${temp}/lb_panel_noFragments"
* I only want to add moms who do NOT show up in live birth panel
keep if _merge==1
* keep variables that are contained in final LB panel
keep td_mother_birth tm_mother_birth ty_mother_birth tm_child_1 td_child_1 id_baby_1 ///
	edu_mother_1 edu_father_1 terul_1 fatherTerul_1 nem_1 td_father_1 td_marriage_1 ///
	tm_father_1 tm_marriage_1 marr_mother_1
* save 
save "${temp}/lb_momsWithOnlyOne", replace

* final append
use "${temp}/lb_panel", clear
append using "${temp}/lb_momsWithOnlyOne"

* housekeeping - crop
drop td_prev_* tm_prev_*
* housekeeping - sort
sort td_mother_birth tm_child_1 td_child_1 tm_child_2 td_child_2 tm_child_3 td_child_3 tm_child_4 td_child_4 tm_child_5 td_child_5 tm_child_6 td_child_6 tm_child_7 td_child_7 tm_child_8 td_child_8 tm_child_9 td_child_9 tm_child_10 td_child_10
* generate mom ID
gen momID = _n
* housekeeping - order
order momID td_mother_birth tm_mother_birth ty_mother_birth tm_child_1 td_child_1 tm_child_2 td_child_2 tm_child_3 td_child_3 tm_child_4 td_child_4 tm_child_5 td_child_5 tm_child_6 td_child_6 tm_child_7 td_child_7 tm_child_8 td_child_8 tm_child_9 td_child_9 tm_child_10 td_child_10
** how many kids **
local checkVar id_baby
gen numK = 0
replace numK = 1 if (`checkVar'_1!=. & `checkVar'_2==.  & `checkVar'_3==. & `checkVar'_4==. & `checkVar'_5==. ///
	& `checkVar'_6==. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 2 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3==. & `checkVar'_4==. & `checkVar'_5==. ///
	& `checkVar'_6==. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 3 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4==. & `checkVar'_5==. ///
	& `checkVar'_6==. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 4 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5==. ///
	& `checkVar'_6==. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 5 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6==. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 6 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7==. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 7 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 8 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8!=. & `checkVar'_9==. & `checkVar'_10==.)
replace numK = 9 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8==. & `checkVar'_9!=. & `checkVar'_10==.)
replace numK = 10 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8==. & `checkVar'_9==. & `checkVar'_10!=.)	
tab numK
* for now, drop fragments
drop if numK==0

* save
save "${temp}/lb_panel_all", replace