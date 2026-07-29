cls
capture log close

use "${temp}/census_002_unbal_filled_moreTSTAR", clear

*******************************************************************************
drop OP_*
rename ksh4 OP_ksh4_bpker 
* attach TSTAR variables to the 2022 (no prefix) settlement
merge m:1 OP_ksh4_bpker using "${temp}/tstar_important_last"
drop if _merge==2
drop _merge
rename OP_ksh4_bpker ksh4
* this makes OP_ vars equivalent to the original no-prefix vars
* so I can use the two new controls as attached to 2022 sett
rename OP_kinderSpots_* kinderSpots_*
rename OP_shareWomen_15_49_* shareWomen_15_49_*
*******************************************************************************

* outcome (x2):  OR C_childrenNEW
local outcomeVars C_childrenNEW N_childrenNEW //
* SE (x2): "cluster ksh4" OR robust
local ses `" "cluster ksh4" "'
* bandwidth/treatment variable (x18)
local bws 10000 0000_10000  
* 9 ITT: all 25000 20000 15000 10000 5000 4000 3000 2000 
* 9 TOT: 0000_all 0000_25000 0000_20000 0000_15000 0000_10000 0000_5000 0000_4000 0000_3000 0000_2000

* specs that run within each loop/rft output
local dynamic1 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.ln_income_2018_bin3#i.ty i.U_2018_bin3#i.ty i.kinderSpots_bin3#i.ty i.shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.ksh4 
local dynamic2 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.ln_income_2018_bin3#i.ty i.U_2018_bin3#i.ty i.kinderSpots_bin3#i.ty i.shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.szemazon 

foreach outcomeVar of local outcomeVars {
foreach se of local ses {
foreach bw of local bws {
	disp("`outcomeVar'")	
	disp("`se'")
	disp("`bw'")

eststo clear
eststo q_1: reghdfe `outcomeVar' i.CSOK_`bw'##ib2019.ty, absorb(`dynamic1') vce(`se') nosample
eststo q_2: reghdfe `outcomeVar' i.CSOK_`bw'##ib2019.ty, absorb(`dynamic2') vce(`se') nosample
* save
esttab using "${output}/regs_`bw'_1_`outcomeVar'_2022.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g) 

}
}
} // cut out static




* rename continous variables
rename OP_ln_income_2018 OP_ln_income_2018_cts
rename OP_U_2018 OP_U_2018_cts
rename OP_hsShare_2018 OP_hsShare_2018_cts 
rename OP_homesPerCap OP_homesPerCap_cts 
rename OP_kinderSpots OP_kinderSpots_cts 
rename OP_shareWomen_15_49 OP_shareWomen_15_49_cts 