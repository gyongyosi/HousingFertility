********************************************************************************
** matching for moms who report TWO OR MORE kids in census *********************
********************************************************************************

** 1st pass: using exact birth dates for the kids ******************************

** 1 - define matching vars
local matchingVars td_mother_birth td_child_1 td_child_2

** 2 - save relevant part of live birth data
use "${temp}/lb_all", clear
* keep women with two or more childen in Live Birth (drops fragments)
* unlike census, no difference between td and tm coverage
keep if td_child_1!=. &  td_child_2!=.
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag
rename nem_2 nem_2_lb
rename nem_1 nem_1_lb
rename y_marriage y_marriage_lb
rename m_marriage m_marriage_lb
rename loc_mother loc_mother_lb
rename edu_mother edu_mother_lb
* save 
save "${temp}/microcensus_lbForMatch_2plus_D", replace

** 3 - load relevant part of census data
use "${temp}/microcensus_for_matching_001", clear
* keep women with two or more childen as of 2022 census
* unlike LB, there IS a difference between td and tm coverage
keep if td_child_1!=. &  td_child_2!=.
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag

** 4 - merge
* fill missing census fields via LB--these are the births we're looking for...
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* merge here, via joinby instead of old code (below) that uses '1:1'
* old code: merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
* for now, filling in only missing which keeps census as master
joinby `matchingVars' using "${temp}/microcensus_lbForMatch_2plus_D", unmatched(master) update
tab _merge

* compute dummies for comparing which variables (beyond matching vars) are matched
foreach X in nem_2 nem_1 y_marriage m_marriage loc_mother edu_mother {
	gen match_`X' = 0
	* when determining whether two date parts match, any missing value precludes a match
	* but matching "not married" 0s in marriage variable count as exact match
	replace match_`X' = 1  if (`X' == `X'_lb) & (`X' != .) & (`X'_lb != .)
}
* construct first component of composite similiarity score from inputs of matched date dummies
gen score = 0
replace score = score + 4 if match_loc_mother==1
replace score = score + 2 if match_nem_2==1
replace score = score + 2 if match_nem_1==1
replace score = score + 0.75 if match_y_marriage==1
replace score = score + 0.25 if (match_y_marriage==1 & match_m_marriage==1)
replace score = score + 0.50 if match_edu_mother==1

* algo for matching
forvalues ii=1(1)4 {

*let's look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag

* identify which census entries match to LBs with no other options
preserve 
keep if tag==0
keep szemazon
duplicates drop szemazon, force
tempfile acceptsStep1
save `acceptsStep1'
restore
* give those census entries to LBs with no other options...
merge m:1 szemazon using `acceptsStep1', generate(mergeStatus)
* ... by deleting claims of LBs with other options to the same census entries
disp("Have other options so yield to those with no options")
drop if mergeStatus==3 & tag > 0

* among momIDs with no other options, give census to their best LB suitor...
egen max_score1 = max(score), by(szemazon)
* ... by deleting LB entries who don't have other options but lose out to other LBs with no options
disp("Have no other options but lose to others with none")
drop if score<max_score1 & tag==0
tab tag

* among momIDs with other options, give census to their best LB suitor... 
egen max_score2 = max(score), by(szemazon)
* ... by deleting LB entries who have other options but lose out to other LBs
disp("Have other options and lose to others with some")
drop if score<max_score2 & tag>0
tab tag 

* clear out variables
drop tag mergeStatus max_score1 max_score2

}
* look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag
drop tag
* let momIDs choose their best
egen max_score = max(score), by(momID)
drop if score < max_score
drop max_score
* let census IDs choose their best
egen max_score = max(score), by(szemazon)
drop if score < max_score
drop max_score

* kill all ties via brute force
duplicates tag szemazon, gen(tagCn)
tab tagCn
drop if tagCn > 0
* before deletig LB ties, see (approx) how many new births we got
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* finish killing ties
duplicates tag momID, gen(tagLB)
tab tagLB
drop if tagLB > 0
* check that there are no duplicates
drop tagLB tagCn
duplicates tag momID, gen(tagLB)
tab tagLB
duplicates tag szemazon, gen(tagCn)
tab tagCn
* kill of joinby merge variable
drop if _merge==1
drop _merge

* 5 - save
keep szemazon momID
sort momID szemazon
save "${temp}/microcensus_matches_2plus_D", replace

* 2nd pass: using only birth month for the kids ********************************

** 1 - define matching vars
local matchingVars td_mother_birth tm_child_1 tm_child_2

** 2 - save relevant part of live birth data
use "${temp}/lb_all", clear
* keep women with two or more childen in Live Birth (drops fragments)
* unlike census, no difference between td and tm coverage
keep if tm_child_1!=. &  tm_child_2!=.
* remove momID's that matched to census in first pass w/ exact dates
merge 1:1 momID using "${temp}/microcensus_matches_2plus_D"
keep if _merge==1
drop _merge
* check duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag
* save
rename td_child_2 td_child_2_lb
rename nem_2 nem_2_lb
rename td_child_1 td_child_1_lb
rename nem_1 nem_1_lb
rename y_marriage y_marriage_lb
rename m_marriage m_marriage_lb
rename loc_mother loc_mother_lb
rename edu_mother edu_mother_lb
save "${temp}/microcensus_lbForMatch_2plus_M", replace

** 3 - load relevant part of census data
use "${temp}/microcensus_for_matching_001", clear
* keep women with two or more childen as of 2022 census
* unlike LB, there IS a difference between td and tm coverage
keep if tm_child_1!=. &  tm_child_2!=.
* remove szemazon's that matched to LB in first pass w/ exact dates
merge 1:1 szemazon using "${temp}/microcensus_matches_2plus_D"
keep if _merge==1
drop _merge
* check duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag

** 4 - merge
* fill missing census fields via LB--these are the births we're looking for...
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* merge here, via joinby instead of old code (below) that uses '1:1'
* old code: merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
* for now, filling in only missing which keeps census as master
joinby `matchingVars' using "${temp}/microcensus_lbForMatch_2plus_M", unmatched(master) update
tab _merge

* compute dummies for comparing which variables (beyond matching vars) are matched
foreach X in td_child_2 nem_2 td_child_1 nem_1 y_marriage m_marriage loc_mother edu_mother {
	gen match_`X' = 0
	* when determining whether two date parts match, any missing value precludes a match
	* but matching "not married" 0s in marriage variable count as exact match
	replace match_`X' = 1  if (`X' == `X'_lb) & (`X' != .) & (`X'_lb != .)
}
* construct first component of composite similiarity score from inputs of matched date dummies
gen score = 0
replace score = score + 5 if match_td_child_2==1
replace score = score + 5 if match_td_child_1==1
replace score = score + 4 if match_loc_mother==1
replace score = score + 2 if match_nem_2==1
replace score = score + 2 if match_nem_1==1
replace score = score + 0.75 if match_y_marriage==1
replace score = score + 0.25 if (match_y_marriage==1 & match_m_marriage==1)
replace score = score + 0.50 if match_edu_mother==1

* algo for matching
forvalues ii=1(1)4 {

*let's look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag

* identify which census entries match to LBs with no other options
preserve 
keep if tag==0
keep szemazon
duplicates drop szemazon, force
tempfile acceptsStep1
save `acceptsStep1'
restore
* give those census entries to LBs with no other options...
merge m:1 szemazon using `acceptsStep1', generate(mergeStatus)
* ... by deleting claims of LBs with other options to the same census entries
disp("Have other options so yield to those with no options")
drop if mergeStatus==3 & tag > 0

* among momIDs with no other options, give census to their best LB suitor...
egen max_score1 = max(score), by(szemazon)
* ... by deleting LB entries who don't have other options but lose out to other LBs with no options
disp("Have no other options but lose to others with none")
drop if score<max_score1 & tag==0
tab tag

* among momIDs with other options, give census to their best LB suitor... 
egen max_score2 = max(score), by(szemazon)
* ... by deleting LB entries who have other options but lose out to other LBs
disp("Have other options and lose to others with some")
drop if score<max_score2 & tag>0
tab tag 

* clear out variables
drop tag mergeStatus max_score1 max_score2

}
* look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag
drop tag
* let momIDs choose their best
egen max_score = max(score), by(momID)
drop if score < max_score
drop max_score
* let census IDs choose their best
egen max_score = max(score), by(szemazon)
drop if score < max_score
drop max_score

* kill all ties via brute force
duplicates tag szemazon, gen(tagCn)
tab tagCn
drop if tagCn > 0
* before deletig LB ties, see (approx) how many new births we got
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* finish killing ties
duplicates tag momID, gen(tagLB)
tab tagLB
drop if tagLB > 0
* check that there are no duplicates
drop tagLB tagCn
duplicates tag momID, gen(tagLB)
tab tagLB
duplicates tag szemazon, gen(tagCn)
tab tagCn
* kill of joinby merge variable
drop if _merge==1
drop _merge

* 5 - save
keep szemazon momID
sort momID szemazon
save "${temp}/microcensus_matches_2plus_M", replace

* combine matches from first and second passes  ********************************

use "${temp}/microcensus_matches_2plus_D", clear
gen case = 1
append using "${temp}/microcensus_matches_2plus_M"
replace case = 2 if case==.
* check for duplicates: should be none, bc dropping LB and census based on 1st pass
duplicates tag momID, gen(tag)
tab tag
drop tag
duplicates tag szemazon, gen(tag)
tab tag
drop tag
drop case 
* save
count
save "${temp}/microcensus_matches_2plus", replace


********************************************************************************
** matching for moms who report ONE kid in census ***************
********************************************************************************

** 1st pass: using exact birth dates for the kid *******************************

** 1 - define matching vars
local matchingVars td_mother_birth td_child_1

** 2 - save relevant part of live birth data
use "${temp}/lb_all", clear
* keep women with one or more in Live Birth (drops fragments)
* unlike census, no difference between td and tm coverage
keep if td_child_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/microcensus_matches_2plus"
keep if _merge==1
drop _merge
* check duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag
* save
rename nem_1 nem_1_lb
rename y_marriage y_marriage_lb
rename m_marriage m_marriage_lb
rename loc_mother loc_mother_lb
rename edu_mother edu_mother_lb
save "${temp}/microcensus_lbForMatch_1_D", replace

** 3 - load relevant part of census data
use "${temp}/microcensus_for_matching_001", clear
* keep women with exactly one child as of 2022 census
* unlike LB, there IS a difference between td and tm coverage
keep if td_child_1!=. &  tm_child_2==.
* check duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag

** 4 - merge
* fill missing census fields via LB--these are the births we're looking for...
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* merge here, via joinby instead of old code (below) that uses '1:1'
* old code: merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
* for now, filling in only missing which keeps census as master
joinby `matchingVars' using "${temp}/microcensus_lbForMatch_1_D", unmatched(master) update
tab _merge

* compute dummies for comparing which variables (beyond matching vars) are matched
foreach X in nem_1 y_marriage m_marriage loc_mother edu_mother {
	gen match_`X' = 0
	* when determining whether two date parts match, any missing value precludes a match
	* but matching "not married" 0s in marriage variable count as exact match
	replace match_`X' = 1  if (`X' == `X'_lb) & (`X' != .) & (`X'_lb != .)
}
* construct first component of composite similiarity score from inputs of matched date dummies
gen score = 0
replace score = score + 4 if match_loc_mother==1
replace score = score + 2 if match_nem_1==1
replace score = score + 0.75 if match_y_marriage==1
replace score = score + 0.25 if (match_y_marriage==1 & match_m_marriage==1)
replace score = score + 0.50 if match_edu_mother==1

* algo for matching
forvalues ii=1(1)4 {

*let's look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag

* identify which census entries match to LBs with no other options
preserve 
keep if tag==0
keep szemazon
duplicates drop szemazon, force
tempfile acceptsStep1
save `acceptsStep1'
restore
* give those census entries to LBs with no other options...
merge m:1 szemazon using `acceptsStep1', generate(mergeStatus)
* ... by deleting claims of LBs with other options to the same census entries
disp("Have other options so yield to those with no options")
drop if mergeStatus==3 & tag > 0

* among momIDs with no other options, give census to their best LB suitor...
egen max_score1 = max(score), by(szemazon)
* ... by deleting LB entries who don't have other options but lose out to other LBs with no options
disp("Have no other options but lose to others with none")
drop if score<max_score1 & tag==0
tab tag

* among momIDs with other options, give census to their best LB suitor... 
egen max_score2 = max(score), by(szemazon)
* ... by deleting LB entries who have other options but lose out to other LBs
disp("Have other options and lose to others with some")
drop if score<max_score2 & tag>0
tab tag 

* clear out variables
drop tag mergeStatus max_score1 max_score2

}
* look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag
drop tag
* let momIDs choose their best
egen max_score = max(score), by(momID)
drop if score < max_score
drop max_score
* let census IDs choose their best
egen max_score = max(score), by(szemazon)
drop if score < max_score
drop max_score

* kill all ties via brute force
duplicates tag szemazon, gen(tagCn)
tab tagCn
drop if tagCn > 0
* before deletig LB ties, see (approx) how many new births we got
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* finish killing ties
duplicates tag momID, gen(tagLB)
tab tagLB
drop if tagLB > 0
* check that there are no duplicates
drop tagLB tagCn
duplicates tag momID, gen(tagLB)
tab tagLB
duplicates tag szemazon, gen(tagCn)
tab tagCn
* kill of joinby merge variable
drop if _merge==1
drop _merge

* 5 - save
keep szemazon momID
sort momID szemazon
save "${temp}/microcensus_matches_1_D", replace






* 2nd pass: using only birth month for the kids ********************************

** 1 - define matching vars
local matchingVars td_mother_birth tm_child_1

** 2 - save relevant part of live birth data
use "${temp}/lb_all", clear
* keep women with one or more childen in Live Birth (drops fragments)
* unlike census, no difference between td and tm coverage
keep if tm_child_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/microcensus_matches_2plus"
keep if _merge==1
drop _merge
merge 1:1 momID using "${temp}/microcensus_matches_1_D"
keep if _merge==1
drop _merge
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag
* save
rename td_child_1 td_child_1_lb
rename nem_1 nem_1_lb
rename y_marriage y_marriage_lb
rename m_marriage m_marriage_lb
rename loc_mother loc_mother_lb
rename edu_mother edu_mother_lb
save "${temp}/microcensus_lbForMatch_1_M", replace

** 3 - load relevant part of census data
use "${temp}/microcensus_for_matching_001", clear
* keep women with two or more childen as of 2022 census
* unlike LB, there IS a difference between td and tm coverage
keep if tm_child_1!=. & tm_child_2==.
* remove szemazon's that matched to LB in first pass w/ exact dates
merge 1:1 szemazon using "${temp}/microcensus_matches_1_D"
keep if _merge==1
drop _merge
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag

** 4 - merge
* fill missing census fields via LB--these are the births we're looking for...
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* merge here, via joinby instead of old code (below) that uses '1:1'
* old code: merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
* for now, filling in only missing which keeps census as master
joinby `matchingVars' using "${temp}/microcensus_lbForMatch_1_M", unmatched(master) update
tab _merge

* compute dummies for comparing which variables (beyond matching vars) are matched
foreach X in td_child_1 nem_1 y_marriage m_marriage loc_mother edu_mother {
	gen match_`X' = 0
	* when determining whether two date parts match, any missing value precludes a match
	* but matching "not married" 0s in marriage variable count as exact match
	replace match_`X' = 1  if (`X' == `X'_lb) & (`X' != .) & (`X'_lb != .)
}
* construct first component of composite similiarity score from inputs of matched date dummies
gen score = 0
replace score = score + 5 if match_td_child_1==1
replace score = score + 4 if match_loc_mother==1
replace score = score + 2 if match_nem_1==1
replace score = score + 0.75 if match_y_marriage==1
replace score = score + 0.25 if (match_y_marriage==1 & match_m_marriage==1)
replace score = score + 0.50 if match_edu_mother==1

* algo for matching
forvalues ii=1(1)4 {

*let's look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag

* identify which census entries match to LBs with no other options
preserve 
keep if tag==0
keep szemazon
duplicates drop szemazon, force
tempfile acceptsStep1
save `acceptsStep1'
restore
* give those census entries to LBs with no other options...
merge m:1 szemazon using `acceptsStep1', generate(mergeStatus)
* ... by deleting claims of LBs with other options to the same census entries
disp("Have other options so yield to those with no options")
drop if mergeStatus==3 & tag > 0

* among momIDs with no other options, give census to their best LB suitor...
egen max_score1 = max(score), by(szemazon)
* ... by deleting LB entries who don't have other options but lose out to other LBs with no options
disp("Have no other options but lose to others with none")
drop if score<max_score1 & tag==0
tab tag

* among momIDs with other options, give census to their best LB suitor... 
egen max_score2 = max(score), by(szemazon)
* ... by deleting LB entries who have other options but lose out to other LBs
disp("Have other options and lose to others with some")
drop if score<max_score2 & tag>0
tab tag 

* clear out variables
drop tag mergeStatus max_score1 max_score2

}
* look at how many LB entries have other options
duplicates tag momID, gen(tag)
tab tag
drop tag
* let momIDs choose their best
egen max_score = max(score), by(momID)
drop if score < max_score
drop max_score
* let census IDs choose their best
egen max_score = max(score), by(szemazon)
drop if score < max_score
drop max_score

* kill all ties via brute force
duplicates tag szemazon, gen(tagCn)
tab tagCn
drop if tagCn > 0
* before deletig LB ties, see (approx) how many new births we got
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
count if tm_child_6!=.
count if tm_child_7!=.
count if tm_child_8!=.
count if tm_child_9!=.
* finish killing ties
duplicates tag momID, gen(tagLB)
tab tagLB
drop if tagLB > 0
* check that there are no duplicates
drop tagLB tagCn
duplicates tag momID, gen(tagLB)
tab tagLB
duplicates tag szemazon, gen(tagCn)
tab tagCn
* kill of joinby merge variable
drop if _merge==1
drop _merge

* 5 - save
keep szemazon momID
sort momID szemazon
save "${temp}/microcensus_matches_1_M", replace

* combine matches from first and second passes  ********************************
use "${temp}/microcensus_matches_1_D", clear
gen case = 1
append using "${temp}/microcensus_matches_1_M"
replace case = 2 if case==.
* check for duplicates: should be none, bc dropping LB and census based on 1st pass
duplicates tag momID, gen(tag)
tab tag
drop tag
duplicates tag szemazon, gen(tag)
tab tag
drop tag
drop case
* save
count
save "${temp}/microcensus_matches_1", replace


********************************************************************************
** matching for moms who report ZERO kids in census ***************
********************************************************************************

** 1 - define matching vars
local matchingVars td_mother_birth y_marriage m_marriage loc_mother

** 2 - save relevant part of live birth data
* live birth
use "${temp}/lb_all", clear
* keep women with one or more in Live Birth (drops fragments)
* unlike census, no difference between td and tm coverage
keep if tm_child_1!=.
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/microcensus_matches_2plus"
keep if _merge==1
drop _merge
* keep live birth entries that did not match before
merge 1:1 momID using "${temp}/microcensus_matches_1"
keep if _merge==1
drop _merge
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag
* keep only moms who have first birth after census
keep if (tm_child_1>=ym(2022,10))
* save 
save "${temp}/microcensus_lbForMatch_0", replace

** 3 - load relevant part of census data
use "${temp}/microcensus_for_matching_001", clear
* keep women with no kids in 2022 census
keep if tm_child_1==.
* check for duplicates
duplicates tag `matchingVars', gen(tag)
tab tag
drop tag

** 4 - merge
* fill missing census fields via LB--these are the births we're looking for...
count if tm_child_1!=.
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.
* merge here, via joinby instead of old code (below) that uses '1:1'
* old code: merge 1:1 `matchingVars' using "${temp}/lb_panel_for_matching_2D", update
* for now, filling in only missing which keeps census as master
joinby `matchingVars' using "${temp}/microcensus_lbForMatch_0", unmatched(master) update
tab _merge
* see (approx) how many new births we got
count if tm_child_1!=.
count if tm_child_2!=.
count if tm_child_3!=.
count if tm_child_4!=.
count if tm_child_5!=.

* kill off joinby merge variable
drop if _merge==1

* kill all ties via brute force - cannot break ties for moms reporting 0
duplicates tag szemazon, gen(tagCn)
tab tagCn
drop if tagCn > 0
duplicates tag momID, gen(tagLB)
tab tagLB
drop if tagLB > 0

* check that there are no duplicates
drop tagLB tagCn
duplicates tag momID, gen(tagLB)
tab tagLB
duplicates tag szemazon, gen(tagCn)
tab tagCn
count

* 5 - save
keep szemazon momID 
sort momID szemazon
save "${temp}/microcensus_matches_0", replace



********************************************************************************
** matching for moms who report ZERO kids in census ***************
********************************************************************************

use "${temp}/microcensus_matches_2plus", clear
append using "${temp}/microcensus_matches_1"
append using "${temp}/microcensus_matches_0"
count
save "${temp}/microcensus_matches_all", replace






********************************************************************************
** match evaluation ***************
********************************************************************************

use "${temp}/lb_all", clear
count
drop if numK==0
count

merge 1:1 momID using "${temp}/microcensus_matches_all"
keep if _merge==3







reshape long id_baby_, i(momID) j(id)

keep momID id_baby_*
drop if id_baby_==.
rename id_baby_ id_baby
merge 1:1 id_baby using "${temp}/LB_001"
keep if ty_baby > 2016

********************************************************************************
* evaluation via regression
****************************************************************************************
use "${temp}/microcensus_matches_all", replace
merge m:1 momID using "${temp}/lb_all"
keep if _merge==3
keep momID id_baby_*
reshape long id_baby_, i(momID) j(num)
rename id_baby_ id_baby
drop if id_baby==.
drop num

merge 1:1 id_baby using "${temp}/LB_for_matching_001"
gen match = 0 
replace match = 1 if _merge==3
drop _merge
save "${temp}/microcensus_whichLBs", replace
 
use "${temp}/tstar_important", clear
keep if ty==2016
save "${temp}/tstar_important_2016", replace

use "${temp}/microcensus_whichLBs", clear
merge m:1 ksh4_bpker using "${temp}/tstar_important_2016"
gen csok_mother = 0
* replace csok_mother = 1 if CSOK_0000_all==1 // eligible settlements ("TOT")
replace csok_mother = 1 if CSOK_all==1 // settlements less than 5K ("ITT")

* include missing vals in regression, treat missing values as their own value
replace edu_father = 99 if edu_father==.
replace edu_mother = 99 if edu_mother==.
replace y_father = 99 if y_father==.

eststo clear
* full sample
eststo q_1: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother
* post-census
eststo q_2: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if tm_baby >= ym(2016,10)

* treatment and control settlements
eststo q_3: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if CSOK_5000!=.
* post-census in treatment and control settlements
eststo q_4: reg match i.y_baby i.nocsal i.y_father i.y_mother i.edu_mother i.edu_father i.elve1 i.nem i.csok_mother if tm_baby >= ym(2022,10) & CSOK_5000!=.

* save 
esttab using "${output}/checkingLBmatchBalance_update_microcensus.rtf", replace 

**********************************************************************************************************






 
merge m:1 momID using "${temp}/lb_panel_all"
keep if _merge==3
gen numKCutoff = 0
replace numKCutoff = numKCutoff + 1 if tm_child_1 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_2 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_3 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_4 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_5 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_6 < ym(2016,10)

duplicates tag momID, gen(tag)

keep szemazon momID numKCutoff
rename numKCutoff numKCutoff_lb

merge m:1 szemazon using "${temp}/microcensus_for_matching_001"
gen numKCutoff = 0
replace numKCutoff = numKCutoff + 1 if tm_child_1 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_2 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_3 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_4 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_5 < ym(2016,10)
replace numKCutoff = numKCutoff + 1 if tm_child_6 < ym(2016,10)

* drop if census number of kids is bigger than LB
drop if numKCutoff

egen maxK = max(numKCutoff), by(momID)


* same live birth 
* how many lb kids by Oct 2022? take biggest census that is stil less than that many

gen case = 2
append using "${temp}/microcensus_matches_1"
replace case = 1 if case==.
append using "${temp}/microcensus_matches_1B"
replace case = 0.5 if case==.
append using "${temp}/microcensus_matches_0"
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