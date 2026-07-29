
cls
capture log close

local tVarsToKeep ksh4 ksh4_bpker jaras175 mkod2018 rkod2018 CSOK_* SH_t_1 SH_t_2 SH_t_3 SH_t_4 de01 de01_2018 emp_sh_0 emp_sh_1 emp_sh_2 emp_sh_3 emp_sh_4 emp_sh_5 emp_sh_6 emp_sh_7 emp_sh_8 emp_sh_9 subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 U_2018* ln_income_2018* hsShare_2018* women_15_49* shareWomen_15_49* numHomes* homesPerCap* kinderSpots* 

* save 2018 pop in different temp file bc will merge on moving-adjusted settlement
use "${temp}/tstar_important", clear
* get 2018 snapshot (pre-treatment)
keep if ty == 2018

* create per capita housing variable
gen homesPerCap = numHomes / de01_2018
* create bins
local varsToBin shareWomen_15_49 homesPerCap kinderSpots //
foreach thisVar in `varsToBin' {
	xtile `thisVar'_bin5 = `thisVar', nq(5)
	xtile `thisVar'_bin4 = `thisVar', nq(4)
	xtile `thisVar'_bin3 = `thisVar', nq(3)
	xtile `thisVar'_bin2 = `thisVar', nq(2)
}

* vars that we want to attach
keep `tVarsToKeep'
* rename these variables with prefixes
ren * OP_*
* save into different temp file for merging soon
compress
save "${temp}/tstar_important_last", replace


use "${temp}/census_002_unbal_filled", clear
rename P_ksh4 OP_ksh4_bpker 
merge m:1 OP_ksh4_bpker using "${temp}/tstar_important_last"
drop if _merge==2
drop _merge
rename OP_ksh4_bpker P_ksh4
* rename continous variables
rename OP_ln_income_2018 OP_ln_income_2018_cts
rename OP_U_2018 OP_U_2018_cts
rename OP_hsShare_2018 OP_hsShare_2018_cts 
rename OP_homesPerCap OP_homesPerCap_cts 
rename OP_kinderSpots OP_kinderSpots_cts 
rename OP_shareWomen_15_49 OP_shareWomen_15_49_cts 
* gen check = P_ln_income_2018_cts==OP_ln_income_2018_cts
* gen check = P_hsShare_2018_cts==OP_hsShare_2018_cts 
* gen check = P_CSOK_10000==OP_CSOK_10000
drop Q_*
gen post = inlist(ty,2020,2021,2022,2023,2024)
compress
save "${temp}/census_002_unbal_filled_moreTSTAR", replace

** 5 versions of each of these: cts + bin2-5
* OP_U_2018
* OP_ln_income_2018
* OP_hsShare_2018
* OP_homesPerCap
* OP_kinderSpots
* OP_shareWomen_15_49
**/

*************************************************************

cls
capture log close
log using "${temp}/runRegs.log", replace

use "${temp}/census_002_unbal_filled_moreTSTAR", clear

* outcome (x2): N_childrenNEW OR C_childrenNEW
local outcomeVars C_childrenNEW
* SE (x2): "cluster P_ksh4" OR robust
local ses `" "cluster P_ksh4" "'
* bandwidth/treatment variable (x18)
local bws 10000 
* 9 ITT: all 25000 20000 15000 10000 5000 4000 3000 2000 
* 9 TOT: 0000_all 0000_25000 0000_20000 0000_15000 0000_10000 0000_5000 0000_4000 0000_3000 0000_2000
* T-STAR version
local tTypes bin3 //cts bin2 bin3
* T-STAR controls
local tControls OP_homesPerCap OP_hsShare_2018  

foreach outcomeVar of local outcomeVars {

********************************************************************************
** dynamic versions ************************************************************
********************************************************************************

foreach se of local ses {
foreach bw of local bws {
foreach tType of local tTypes {
foreach tControl of local tControls {
	
	disp("`se'")
	disp("`bw'")
	disp("`tType'")
	disp("`tControl'")
	
local tPre i 
if "`tType'"=="cts" {
	local tPre c
}

* controls: T-STAR (x2) + FE (x3)
local dynamic1 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.ethCatg#i.ty i.relCatg#i.ty `tPre'.OP_ln_income_2018_`tType'#i.ty `tPre'.OP_U_2018_`tType'#i.ty `tPre'.OP_kinderSpots_`tType'#i.ty `tPre'.OP_shareWomen_15_49_`tType'#i.ty `tPre'.`tControl'_`tType'#i.ty i.P_ksh4
local dynamic2 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.ethCatg#i.ty i.relCatg#i.ty `tPre'.OP_ln_income_2018_`tType'#i.ty `tPre'.OP_U_2018_`tType'#i.ty `tPre'.OP_kinderSpots_`tType'#i.ty `tPre'.OP_shareWomen_15_49_`tType'#i.ty `tPre'.`tControl'_`tType'#i.ty i.szemazon

eststo clear
eststo q_1: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic1') vce(`se') nosample
eststo q_2: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic2') vce(`se') nosample
* eststo q_3: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic3') vce(`se') nosample
* eststo q_4: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic4') vce(`se') nosample
* eststo q_5: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic5') vce(`se') nosample
* eststo q_6: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic6') vce(`se') nosample

*local seType = 0 
* if "`se'"=="cluster ksh4" {
*	local seType = 1
* }
esttab using "${output}/regs_dynamic_1_`bw'_`tType'_`tControl'_`outcomeVar'_tue2.rtf", replace

}
}
}
}
} // cut out static
