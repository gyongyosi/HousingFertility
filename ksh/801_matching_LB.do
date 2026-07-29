/*------------------------------------------------------------------------------
	slice the data based on number of kids
------------------------------------------------------------------------------*/

use "${temp}/LB_for_matching_001", clear

* summarize birth parity number
histogram(elve1), width(1)
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
/**
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
**/

/*------------------------------------------------------------------------------
approach 2: m:m merge that takes the best one
------------------------------------------------------------------------------*/
local start = 1
local next = `start' + 1
local matching_variables "y_prev m_prev y_mother m_mother"

* load earlier (1/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`start'", clear
* IMPT: drop previous baby birth day, and rename this baby birthday as prev baby birthday
drop td_prev tm_prev ty_prev d_prev m_prev y_prev
ren td_baby td_prev
ren tm_baby tm_prev
ren ty_baby ty_prev
ren d_baby d_prev
ren m_baby m_prev
ren y_baby y_prev

* keep baby ID, sex, 3 birthdates, marriage date, 2 educations, and 2 locations
keep id_baby nem td_* tm_* ty_* d_* m_* y_* edu_* notart fitart
* rename all variables with _1
foreach X of varlist * {
	ren `X' `X'_`start'
}
* IMPT: keep matching variables without _X subscript
foreach X of local matching_variables {
	ren `X'_`start'  `X'
}
* save
count
tempfile Q`start'
save `Q`start''

* load later (2/2) birth dataset
use "${temp}/LB_for_matching_001_elve1_`next'", clear

* keep baby ID, sex, 3 birthdates, marriage date, 2 educations, and 2 locations
keep id_baby nem td_* tm_* ty_* d_* m_* y_* edu_* notart fitart
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
* 1-2: 28,875,126 (set start=1)
* 2-3: 6,216,387 (set start=2)
* 3-4: 650,634 (set start=3)
* 4-5: 106,189 (set start...)
* 5-6: 31,227
* 6-7: 11,633
* 7-8: 4,985
* 8-9: 2,227
* 9-10: 1,028