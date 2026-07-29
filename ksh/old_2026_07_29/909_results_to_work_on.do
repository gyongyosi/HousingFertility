


/*------------------------------------------------------------------------------
	OTHER OUTCOMES -- marriage
------------------------------------------------------------------------------*/


/*
use "${temp}/census_002_trim_updated", clear




keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .


collapse (mean) married, by(ty)
line married ty


use "${temp}/census_002_trim_updated", clear


collapse (mean) married, by(ty CSOK_0000)
reshape wide married, i(ty) j(CSOK)
line married* ty


use "${temp}/census_002_trim_updated", clear
keep if inrange(ty, 2014, 2024)
keep if CSOK_15000 != .

reghdfe married i.CSOK_0000##i.POST_2019 if inrange(ty, 2014, 2024),  vce("cluster ksh4")

reghdfe married i.CSOK_0000##i.POST_2019 if inrange(ty, 2014, 2024), absorb(ksh4_bpker ty) vce("cluster ksh4")

reghdfe married i.CSOK_0000##i.POST_2019 if inrange(ty, 2014, 2024), absorb(ksh4_bpker ty i.ty_mother_birth##i.POST i.eduCatg##i.POST) vce("cluster ksh4")
*/


/*------------------------------------------------------------------------------
	Propensity score matching
------------------------------------------------------------------------------*/

/*
foreach BW in "0000" /* 5000 15000 */ {

	foreach caliper in 10 /* 5 1 */ {

		use "${temp}/census_002_trim_updated", clear
		keep if ty == 2018
		keep if inrange(de01, 0, 20000)
		keep if CSOK_`BW' != .

		local CALIPER = `caliper' / 1000


		cap drop TREATMENT
		gen TREATMENT = .
		replace TREATMENT = 0 if CSOK_`BW' == 0
		replace TREATMENT = 1 if CSOK_`BW' == 1
		
		* keep obs where distance is small
		cap teffects psmatch (C_childrenNEW) (TREATMENT  $x1 $x2) , vce(robust) caliper(`CALIPER') osample(OSAMPLE)
		keep if OSAMPLE == 0

		* determine TREATMENT-CONTROL matches
		cap teffects psmatch (C_childrenNEW) (TREATMENT  $x1 $x2) , vce(robust)  gen(match)
		gen ob = _n
		tempfile fulldata
		save `fulldata'
		
		keep if TREATMENT == 1 /* keep treated */
		keep match1  /* keep the observation number of matched control observation */
		bysort match : gen WEIGHT_`caliper' = _N  /* count how many times each control observation serves as control */
		by match: keep if _n == 1  /* keep just one row per control observation */
		ren match ob
		
		merge 1:m ob using `fulldata'
		replace WEIGHT = 1 if TREATMENT == 1  /* replace weight to 1 for treated */
		gen WW_`caliper' = weight * WEIGHT  /* create the proper weight: some controls serve as control multiple times; take this into account */
		
		ren TREATMENT TREATMENT_`caliper'
		keep szemazon TREATMENT_`caliper' WEIGHT_`caliper' WW_`caliper'
		save "${temp}/psmatch_`caliper'" , replace


	}
}

*/

