********************************************************************************
******** matching for moms who report two or more kids in census
* two passes: first one using exact birth dates for the kids
* two passes: second one using only birth month for the kids
* within each of the two passes, split census by number of kids (2,3,4,5+)
* both of these measures (two passes and splitting census) reduce duplicates


*** PASS 1: using exact birth date for kids 

local matchingVars td_mother_birth td_child_1 td_child_2
** update live birth
use "${temp}/lb_panel_all", clear

* keep women with two or more childen in Live Birth (drops fragments)
keep if td_child_1!=. &  td_child_2!=.
* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'
duplicates tag `matchingVars'  , gen(tag)
keep if tag==0
drop tag
* check denominator again
count
*save 
save "${temp}/lb_panel_for_matching_2D", replace

** split census here
forval ii = 2(1)5 {

*** census 2 kids
local matchingVars td_mother_birth td_child_1 td_child_2
use "${temp}/census_for_matching_001", clear
* keep women with exactly two childen in 2022 census
if `ii'==2 { // exactly 2 kids
	keep if td_child_1!=. & td_child_2!=. & tm_child_3==.
}
else if `ii'==3 { // exactly 3 kids
	keep if td_child_1!=. & td_child_2!=. & td_child_3!=. & tm_child_4==.
}
else if `ii'==4 { // exactly 4 kids
	keep if td_child_1!=. & td_child_2!=. & td_child_3!=. & td_child_4!=.& tm_child_5==.

}
else if `ii'==5 { // exactly 5 kids OR MORE
	keep if td_child_1!=. & td_child_2!=. & td_child_3!=. & td_child_4!=.& td_child_5!=.
}

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'  
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count

* fill in LB fields for missing census ones--these are the births we're looking for! 
* but keep census versions of td_child variables, and tm_child for any third or after kids
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
tab _merge
drop if _merge==2
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
drop if _merge==1
keep szemazon momID
sort momID szemazon
save "${temp}/matches_`ii'D", replace

}
* aggregate across census splits within first pass
use "${temp}/matches_5D", clear
append using "${temp}/matches_4D"
append using "${temp}/matches_3D"
append using "${temp}/matches_2D"
count
* remove any LB momIDs that matches to multiple census entries within first pass
duplicates tag momID, gen(tag)
keep if tag==0
drop tag
* save matches from first pass
count
save "${temp}/matches_2plusD", replace


*** PASS 2: using only birth month for kids 

local matchingVars td_mother_birth tm_child_1 tm_child_2
** update live birth
use "${temp}/lb_panel_all", clear
* remove momID's that matched to census in first pass w/ exact dates
merge 1:1 momID using "${temp}/matches_2plusD"
keep if _merge==1
drop _merge

* keep women with two or more childen in Live Birth (drops fragments)
keep if tm_child_1!=. &  tm_child_2!=.
* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'
duplicates tag `matchingVars'  , gen(tag)
keep if tag==0
drop tag
* check denominator again
count
*save 
save "${temp}/lb_panel_for_matching_2M", replace

** split census here
forval ii = 2(1)5 {

*** census 2 kids
local matchingVars td_mother_birth tm_child_1 tm_child_2
use "${temp}/census_for_matching_001", clear
* remove szemazon's that matched to LB in first pass w/ exact dates
merge 1:1 szemazon using "${temp}/matches_2plusD"
keep if _merge==1
drop _merge
* keep women with exactly two childen in 2022 census
if `ii'==2 { // exactly 2 kids
	keep if tm_child_1!=. & tm_child_2!=. & tm_child_3==.
}
else if `ii'==3 { // exactly 3 kids
	keep if tm_child_1!=. & tm_child_2!=. & tm_child_3!=. & tm_child_4==.
}
else if `ii'==4 { // exactly 4 kids
	keep if tm_child_1!=. & tm_child_2!=. & tm_child_3!=. & tm_child_4!=.& tm_child_5==.

}
else if `ii'==5 { // exactly 5 kids OR MORE
	keep if tm_child_1!=. & tm_child_2!=. & tm_child_3!=. & tm_child_4!=.& tm_child_5!=.
}

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'  
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count

* fill in LB fields for missing census ones--these are the births we're looking for! 
* but keep census versions of td_child variables, and tm_child for any third or after kids
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2M", update
tab _merge
drop if _merge==2
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
drop if _merge==1
keep szemazon momID
sort momID szemazon
save "${temp}/matches_`ii'M", replace

}
* aggregate across census splits within second pass
use "${temp}/matches_5M", clear
append using "${temp}/matches_4M"
append using "${temp}/matches_3M"
append using "${temp}/matches_2M"
count
* remove any LB momIDs that matches to multiple census entries within second pass
duplicates tag momID, gen(tag)
keep if tag==0
drop tag
* save matches from second pass
count
save "${temp}/matches_2plusM", replace

* combine matches from first and second passes 
use "${temp}/matches_2plusD", clear
gen case = 1
append using "${temp}/matches_2plusM"
replace case = 2 if case==.
* check for duplicates (should be none, bc dropping LB and census based on first pass)
duplicates tag momID, gen(tag)
drop if tag==1 & case==1
drop case tag
* save
count
save "${temp}/matches_2plus", replace


********************************************************************************
* matching for moms who report ONE kid in census
local matchingVars td_mother_birth td_child_1
** update live birth
use "${temp}/lb_panel_all", clear

* keep women with one or more kids in Live Birth (just drops fragments, if still inlcuded)
keep if id_baby_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/matches_2plus"
keep if _merge==1
drop _merge

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count
save "${temp}/lb_panel_for_matching_1D", replace

local matchingVars td_mother_birth td_child_1
use "${temp}/census_for_matching_001", clear
* keep women with exactly one kid in 2022 census
keep if tm_child_1!=. & tm_child_2==.
* keep census entries that did not match before
* actually, not necessary bc census num of kids screens are mutually exclusive
merge 1:1 szemazon using "${temp}/matches_2plus"
keep if _merge==1
drop _merge
* add in screen for new moms
* gen y1 = year(dofm(tm_child_1))
* gen flag = 0
* replace flag = 1 if y1 > 2012
* keep if flag == 1

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'  
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count

* "update" = "update replace" because census will have missing vals for 2nd kid and on
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_1D", update
tab _merge
drop if _merge==2
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
drop if _merge==1
keep szemazon momID
sort momID szemazon
save "${temp}/matches_1D", replace

******************** 2nd pass                    *******************************
* matching for moms who report ONE kid in census
local matchingVars td_mother_birth tm_child_1
** update live birth
use "${temp}/lb_panel_all", clear

* keep women with one or more kids in Live Birth (just drops fragments?)
keep if id_baby_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/matches_2plus"
keep if _merge==1
drop _merge
merge 1:1 momID using "${temp}/matches_1D"
keep if _merge==1
drop _merge

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count
save "${temp}/lb_panel_for_matching_1M", replace

local matchingVars td_mother_birth tm_child_1
use "${temp}/census_for_matching_001", clear
* keep women with exactly one kid in 2022 census
keep if tm_child_1!=. & tm_child_2==.
* keep census entries that did not match before
* actually, not necessary bc census num of kids screens are mutually exclusive
merge 1:1 szemazon using "${temp}/matches_2plus"
keep if _merge==1
drop _merge
* this is necessary: keep census entries that did not match before
merge 1:1 szemazon using "${temp}/matches_1D"
keep if _merge==1
drop _merge

* add in screen for new moms
* gen y1 = year(dofm(tm_child_1))
* gen flag = 0
* replace flag = 1 if y1 > 2012
* keep if flag == 1

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'  
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count

* "update" = "update replace" because census will have missing vals for 2nd kid and on
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_1M", update
tab _merge
drop if _merge==2
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
drop if _merge==1
keep szemazon momID
sort momID szemazon
save "${temp}/matches_1M", replace

********************************************************************************
* matching for moms who report NO births in the census
local matchingVars td_mother_birth terul_1 marr_mother_1 tm_marriage_1
** update live birth
use "${temp}/lb_panel_all", clear

* keep women with one or more kids in Live Birth (just drops fragments?)
keep if id_baby_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/matches_2plus"
keep if _merge==1
drop _merge
merge 1:1 momID using "${temp}/matches_1D"
keep if _merge==1
drop _merge
merge 1:1 momID using "${temp}/matches_1M"
keep if _merge==1
drop _merge

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count
* keep only births post census
keep if (tm_child_1>=ym(2022,10))
count
save "${temp}/lb_panel_for_matching_0", replace

local matchingVars td_mother_birth terul_1 marr_mother_1 tm_marriage_1
use "${temp}/census_for_matching_001", clear
* keep women with no kids in 2022 census
keep if tm_child_1==.
rename tm_marriage tm_marriage_1
rename marr_mother marr_mother_1
rename edu_mother edu_mother_1X
drop terul_1 
rename loc_mother terul_1

* check denominator
count
* drop duplicates on matching variables
duplicates report `matchingVars'  
duplicates tag `matchingVars', gen(tag)
keep if tag==0
drop tag
* check denominator again
count

* "update" = "update replace" because census will have missing vals for 2nd kid and on
count if tm_child_1!=.
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_0", update
tab _merge
drop if _merge==2
count if tm_child_1!=.
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
drop if _merge==1
keep szemazon momID
sort momID szemazon
save "${temp}/matches_0", replace

********************************************************************************
* LAST: get list of live births that have not been paired

use "${temp}/matches_2plus", clear
append using "${temp}/matches_1D"
append using "${temp}/matches_1M"
append using "${temp}/matches_0"
save "${temp}/matchesAll", replace
 

use "${temp}/matchesAll", replace
merge m:1 momID using "${temp}/lb_panel_all"
keep if _merge==3
keep momID id_baby_*
reshape long id_baby_, i(momID) j(num)
rename id_baby_ id_baby
drop if id_baby==.

merge 1:1 id_baby using "${temp}/LB_for_matching_001"
gen match = 0 
replace match = 1 if _merge==3
drop _merge
save "${temp}/whichLBs", replace
 
 
use "${temp}/tstar_important", clear
keep if ty==2019
save "${temp}/tstar_important_2019", replace

use "${temp}/whichLBs", clear
rename ksh4_mother ksh4 
merge m:1 ksh4 using "${temp}/tstar_important_2019"
gen csok_mother = 0
replace csok_mother = 1 if CSOK_0000==1
rename ksh4 ksh4_mother



* include missing vals in regression, treat missing values as their own value
replace edu_father = 99 if edu_father==.
replace edu_mother = 99 if edu_mother==.
replace y_father = 99 if y_father==.

eststo clear
eststo q_1: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother
eststo q_2: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if tm_baby >= ym(2022,10)
* eststo q_3: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if y_baby > 2022 
* add restriction for bandwidth
eststo q_3: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if CSOK_5000!=.
eststo q_4: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if tm_baby >= ym(2022,10) & CSOK_5000!=.
* eststo q_6: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if y_baby > 2022 & CSOK_5000!=.
* save 
esttab using "${output}/checkingLBmatchBalance_update.rtf", replace 



 
merge m:1 momID using "${temp}/lb_panel_all"
keep if _merge==3
gen numKCutoff = 0
replace numKCutoff = numKCutoff + 1 if tm_child_1 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_2 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_3 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_4 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_5 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_6 < ym(2022,10)

duplicates tag momID, gen(tag)

keep szemazon momID numKCutoff
rename numKCutoff numKCutoff_lb

merge m:1 szemazon using "${temp}/census_for_matching_001"
gen numKCutoff = 0
replace numKCutoff = numKCutoff + 1 if tm_child_1 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_2 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_3 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_4 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_5 < ym(2022,10)
replace numKCutoff = numKCutoff + 1 if tm_child_6 < ym(2022,10)

* drop if census number of kids is bigger than LB
drop if numKCutoff

egen maxK = max(numKCutoff), by(momID)


* same live birth 
* how many lb kids by Oct 2022? take biggest census that is stil less than that many

gen case = 2
append using "${temp}/matches_1"
replace case = 1 if case==.
append using "${temp}/matches_1B"
replace case = 0.5 if case==.
append using "${temp}/matches_0"
replace case = 0.25 if case==.

duplicates tag momID, gen(tag)
tab tag
drop tag
merge 1:1 momID using "${temp}/lb_panel_all" 
tab numK _merge, row


gen mglBirth = 0
forval noKid = 1(1)10 {
	replace mglBirth = 1 if (mglBirth==1 | (tm_child_`noKid'!=. & tm_child_`noKid'>=ym(2022,10)))
}
tab mglBirth _merge, row
count if mglBirth==1


/**
use "${temp}/matchesTough1", clear
append using "${temp}/matchesTough2"
append using "${temp}/matchesTough3"
append using "${temp}/matchesTough4"
drop if tough==1
tab numK _merge, row
keep if (numK==1 & _merge==2)