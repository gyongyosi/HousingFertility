* load first crosswalk
use "${temp}/crosswalk_9_10", clear

* loop over merges (8) of adjacent crosswalks (9)
forval kk = 1(1)8 {
	
	* set of locals to descend appripriately
	local late = 11 - `kk' // 10 9 8 7 6 5 4 3
	local mid = `late' - 1 //  9 8 7 6 5 4 3 2
	local early = `late' - 2 //8 7 6 5 4 3 2 1

	* merge later crosswalk with earlier one, using shared baby ID 
	* IMPORTANT: keep the using version of ??_prev_MID (see merge documentation notes for why)
	* ... this is "undoing" our previous renaming of earlier dataset's current birth variable
	merge 1:1 id_baby_`mid' using "${temp}/crosswalk_`early'_`mid'", update replace
	
	* save master observations that did NOT merge ("fragments") in a separate file 
	* theoretically, these all should find a match bc those who had a 9th and 10th should have had an eighth. 
	* but, for whatever reason, they don't. So I save them as fragement to append back in later.	
	preserve
	* restrict to fragments
	keep if _merge==1
	
	* drop variables that, for fragments, did not get filled in by merge
	drop _merge *_`early' *_mother_`early'_`mid'
	* drop another variable that did not get filled in merge...
	* ...but the data that did not get filled in for this DB`mid'-KID`mid' is already stored in ??_prev_`mid' 
	drop *_baby_`mid' 
	* rename that variable that already stores DB`mid'-KID`mid' to reflect that...
	* ... this is "undoing" our previous renaming of earlier dataset's current birth variable
	rename td_prev_`mid' td_baby_`mid' 
	rename tm_prev_`mid' tm_baby_`mid' 
	rename ty_prev_`mid' ty_baby_`mid' 
	rename d_prev_`mid' d_baby_`mid' 
	rename m_prev_`mid' m_baby_`mid'
	rename y_prev_`mid' y_baby_`mid'	
	* save fragments and restore
	save "${temp}/fragments_`mid'_`late'", replace
	* go back from fragments to full sample
	restore
	* delete master observations that did NOT merge ("fragments") to enable next merge
	drop if _merge==1
	drop _merge
	* but keep all "using" observations because among women who had an 8th kid, we only expect women who had a 9th to match
}

* loop over merges to append files containing fragments
forval kk = 1(1)8 {
	
	local late = 11 - `kk' // 10 9 8 7 6 5 4 3
	local mid = `late' - 1 //  9 8 7 6 5 4 3 2
	* append here
	append using "${temp}/fragments_`mid'_`late'"
}

* IMPT: undo renaming of earlier dataset's current birth variable for 1st births
* for later birth parities, this gets rewritten by merge OR fixed for fragments
* have 1-10 for all vars EXCEPT missing _1 for the 6 baby date vars and m_prev_1 and y_prev_1... 
rename td_prev_1 td_baby_1
rename tm_prev_1 tm_baby_1
rename ty_prev_1 ty_baby_1
rename d_prev_1 d_baby_1
* also do this fix
gen m_baby_1 = month(dofm(tm_baby_1))
gen y_baby_1 = ty_baby_1
* ... now missing 1 for all 6 prev date vars
* ??_baby: 1-10 -- should match each other on month: td_baby_X vs. td_prev_X+1
* ??_prev: 2-10 -- should match each other on month: td_baby_X vs. td_prev_X+1
* checking kid birthday matches via td_baby_X vs. td_prev_X+1
* need to generate a couple variables for 10th kid
* gen m_prev_10 = month(dofm(tm_prev_10))
* gen y_prev_10 = ty_prev_10
forval start = 1(1)9 {
	
	local next = `start' + 1

	gen noMatchY = (y_baby_`start'!=y_prev_`next' & y_baby_`start'!=. & y_prev_`next'!=.)
	gen noMatchM = (m_baby_`start'!=m_prev_`next' & m_baby_`start'!=. & m_prev_`next'!=.)
	gen noMatchD = (d_baby_`start'!=d_prev_`next' & d_baby_`start'!=. & d_prev_`next'!=.)
	
	tab noMatchY noMatchM
	tab noMatchD
	** what to drop? just month mismatch
	drop if (noMatchY==1 | noMatchM==1)
	drop noMatchY noMatchM noMatchD

}

* id_baby: 1-10 -- save to associate with mother
* for loc_mother, loc_father, edu_mother, edu_father, father 6 dates, and marriage 6 dates...
*... identify one version to keep: consensus, or from birth closest to 2022
local varsToCollapse loc_mother loc_father edu_mother edu_father ///
	d_father m_father y_father td_father tm_father ty_father ///
	d_marriage m_marriage y_marriage td_marriage tm_marriage ty_marriage
foreach X in `varsToCollapse' {
	display("`X'") 


egen check1 = rowmin(`X'_*)
egen check2 = rowmax(`X'_*)
gen allSame = (check1==check2)
tab allSame
* create 1 composite variable
gen `X' = .
* fill in easy cases where variable is always the same
replace `X' = check1 if allSame==1
* fill in tougher cases by taking year closest to 2022: 2022, 2023, 2021, 2024, 2020, 2019,...
forval nn = 1(1)10 {
	gen diffFrom2022_`nn' = y_baby_`nn' - 2022.33
	gen distTo2022_`nn' = abs(diffFrom2022_`nn')
}
egen min = rowmin(distTo2022_*)
forval nn = 1(1)10 {
	gen flag_`nn' = (distTo2022_`nn'==min)
}
forval nn = 1(1)10 {
	local reverse = 11 - `nn'
	replace `X' = `X'_`reverse' if flag_`reverse'==1
}
drop check1 check2 allSame diffFrom2022_* distTo2022_* min flag_*
drop `X'_* 
}
format td_father %td
format tm_father %tm
format td_marriage %td
format tm_marriage %tm

* checking mom birth month (not day)--should be perfect because we required to match
egen check_y_mother1 = rowmin(y_mother_*)
egen check_y_mother2 = rowmax(y_mother_*)
egen check_m_mother1 = rowmin(m_mother_*)
egen check_m_mother2 = rowmax(m_mother_*)
gen checkingMom = (check_y_mother1==check_y_mother2) & (check_m_mother1==check_m_mother2)
tab checkingMom, m
* should not have to drop any because we required to match
drop if checkingMom==0
drop y_mother* m_mother* 
gen y_mother = check_y_mother1
gen m_mother = check_m_mother1
drop checkingMom check_y_mother1 check_y_mother2 check_m_mother1 check_m_mother2

* get one consensus day for each mom: for the <1 percent with inconsistent day, take (minimum) mode
gen tempCount = _n
reshape long d_mother_, i(tempCount) j(numVar) string
destring(numVar), replace
egen d_motherMode = mode(d_mother_), minmode by(tempCount)
* fill in missing dates that appear to be leap days
replace d_motherMode = 29 if d_motherMode==. & m_mother==2 & inlist(y_mother,1964,1968,1972,1976,1980,1984,1988)
* luckily, this leap year fix seems to be the only one needed
count if d_motherMode==.
* reshape back again
reshape wide d_mother_, i(tempCount) j(numVar)
* clean out variables
drop tempCount d_mother_* td_mother_* tm_mother_* ty_mother_*
* rename to match month and year for mother
rename d_motherMode d_mother 
* re-generate t-time variables
gen td_mother = mdy(m_mother,d_mother,y_mother)
format td_mother %td
gen tm_mother = ym(y_mother,m_mother)
format tm_mother %tm
gen ty_mother = y_mother

* rename to match census for matching
rename ??_mother ??_mother_birth
rename ?_mother ?_mother_birth
rename ty_baby_* ty_child_*
rename tm_baby_* tm_child_*
rename td_baby_* td_child_*
rename y_baby_* y_child_*
rename m_baby_* m_child_*
rename d_baby_* d_child_*

* save fragments separately
preserve
keep if id_baby_1==.
save "${temp}/lb_onlyFragments", replace
restore
* save non-fragments separately
preserve
drop if id_baby_1==.
save "${temp}/lb_noFragments", replace
restore
* save, including both fragments and non-fragments
save "${temp}/lb_pre", replace

******************************************************************************************************************
*** add in moms who only had one kid in LB
* load all first births in LB data
use "${temp}/LB_for_matching_001_elve1_1", clear

* rename to match my variable conventions in LB panel
rename id_baby id_baby_1
rename nem nem_1
rename d_baby d_child_1
rename m_baby m_child_1
rename y_baby y_child_1
rename td_baby td_child_1
rename tm_baby tm_child_1
rename ty_baby ty_child_1
rename d_mother d_mother_birth
rename m_mother m_mother_birth
rename y_mother y_mother_birth
rename td_mother td_mother_birth
rename tm_mother tm_mother_birth
rename ty_mother ty_mother_birth
* father date variables are already named correctly
* marriage date variables are already named correctly
* edu_mother and edu_father are already named correctly
rename notart loc_mother
rename fitart loc_father
* rename nocsal marr_mother_1

* fix moms leap year dates
replace d_mother = 29 if d_mother==. & m_mother==2 & inlist(y_mother,1964,1968,1972,1976,1980,1984,1988,1992,1996)
* re-generate t-time variables
drop td_mother_birth
drop tm_mother_birth
drop ty_mother_birth
gen td_mother_birth = mdy(m_mother,d_mother,y_mother)
format td_mother_birth %td
gen tm_mother_birth = ym(y_mother,m_mother)
format tm_mother_birth %tm
gen ty_mother_birth = y_mother

* keep variables that are contained in final LB panel
keep id_baby_* nem_* ?_child_* ??_child_* ///
	?_mother_birth ??_mother_birth ?_father ??_father ?_marriage ??_marriage ///
	edu_father edu_mother loc_father loc_mother

* merge using 1st baby ID with non-fragment portion of live birth panel
merge 1:1 id_baby_1 using "${temp}/lb_noFragments"
* I only want to add moms who do NOT already show up in live birth panel
keep if _merge==1
drop _merge
* save
save "${temp}/lb_momsWithOnlyOne", replace

* final append
use "${temp}/lb_pre", clear
append using "${temp}/lb_momsWithOnlyOne"

* housekeeping - crop
drop ?_prev_* ??_prev_*
* housekeeping - sort
sort y_mother_birth m_mother_birth d_mother_birth tm_child_1 td_child_1 tm_child_2 td_child_2 tm_child_3 td_child_3 tm_child_4 td_child_4 tm_child_5 td_child_5 tm_child_6 td_child_6 tm_child_7 td_child_7 tm_child_8 td_child_8 tm_child_9 td_child_9 tm_child_10 td_child_10
* generate mom ID
gen momID = _n
* housekeeping - order
order ?_mother_birth ??_mother_birth ///
	id_baby_* nem_* ?_child_* ??_child_* ///
	?_father ??_father ?_marriage ??_marriage ///
	edu_father edu_mother loc_father loc_mother
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
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8!=. & `checkVar'_9!=. & `checkVar'_10==.)
replace numK = 10 if (`checkVar'_1!=. & `checkVar'_2!=.  & `checkVar'_3!=. & `checkVar'_4!=. & `checkVar'_5!=. ///
	& `checkVar'_6!=. & `checkVar'_7!=. & `checkVar'_8!=. & `checkVar'_9!=. & `checkVar'_10!=.)	
tab numK, m
* for now, do NOT drop fragments
* drop if numK==0

* save
save "${temp}/lb_all", replace
* save version for merging that contains only momID and date of children birth
keep momID tm_child_*
rename tm_child_* tm_child_LB_*
save "${temp}/lb_forMerge", replace