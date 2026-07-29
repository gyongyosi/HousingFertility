cls
clear
** do the sae for diff bandwidths

* define which bandwidth (seems robust, though)
local bw 10000
local indVars c.ty_mother_birth i.cohort5 i.eduCatg i.marriedBy2019 i.kidsBy2019 i.relCatg i.ethCatg
local setVars i.OP_U_2018_bin3 i.OP_ln_income_2018_bin3 i.OP_kinderSpots_bin3 i.OP_shareWomen_15_49_bin3

* load data
use "${temp}/census_002_unbal_filled_moreTSTAR", clear

* keep if ty==2018
* restrict to relevant bandwidth
keep if P_CSOK_`bw'!=.

collapse (firstnm) P_CSOK_`bw' ty_mother_birth cohort5 eduCatg marriedBy2019 kidsBy2019 relCatg ethCatg ///
	OP_U_2018_bin3 OP_ln_income_2018_bin3 OP_kinderSpots_bin3 OP_shareWomen_15_49_bin3, by(szemazon)

dtable `indVars' `setVars', by(P_CSOK_`bw', tests) ///
	export("${output}/summStats.xlsx", replace)