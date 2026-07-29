cls
capture log close

use "${temp}/census_002_unbal_filled_moreTSTAR", clear

egen agexpar = group(cohort5 kidsBy2019)

* heterogeneity via subsamples
local hetVars agexpar cohort5 kidsBy2019 eduCatg marriedBy2019 OP_ln_income_2018_bin3 OP_U_2018_bin3 relCatg ethCatg

foreach hetVar of local hetVars {
* cohort5 - 10 cats 
* eduCatg - 4 cats
* marriedBy2019 - 2 cats
* kidsBy2019 - 4 cats
* OP_ln_income_2018_bin3 - 3 cats
* OP_U_2018_bin3 - 3 cats
* relCatg - 5 cats
* ethCatg - 3 cats

summ `hetVar'
local loopFirst `r(min)'
local loopLast `r(max)'
display(`loopFirst')
display(`loopLast')
forval thisValue = `loopFirst'(1)`loopLast' {
	
	* implement heterogeneity here
	use "${temp}/census_002_unbal_filled_moreTSTAR", clear
	egen agexpar = group(cohort5 kidsBy2019)
	keep if `hetVar'==`thisValue'

* outcome (x2): N_childrenNEW OR C_childrenNEW
local outcomeVars C_childrenNEW
* SE (x1): "cluster P_ksh4"
local ses `" "cluster P_ksh4" "'
* bandwidth/treatment variable (x6)
local bws 10000 // 0000_10000 0000_5000 0000_15000 5000 15000 
* 9 ITT: all 25000 20000 15000 10000 5000 4000 3000 2000 
* 9 TOT: 0000_all 0000_25000 0000_20000 0000_15000 0000_10000 0000_5000 0000_4000 0000_3000 0000_2000

foreach outcomeVar of local outcomeVars {
foreach se of local ses {
foreach bw of local bws {
	disp("`outcomeVar'")
	disp("`se'")
	disp("`bw'")

* specs that run within each loop/rft output
local dynamic1 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.OP_ln_income_2018_bin3#i.ty i.OP_U_2018_bin3#i.ty i.OP_kinderSpots_bin3#i.ty i.OP_shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.P_ksh4
local dynamic2 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.OP_ln_income_2018_bin3#i.ty i.OP_U_2018_bin3#i.ty i.OP_kinderSpots_bin3#i.ty i.OP_shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.szemazon

* run and store regressions
eststo clear
eststo q_1: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic1') vce(`se') nosample
eststo q_2: reghdfe `outcomeVar' i.P_CSOK_`bw'##ib2019.ty, absorb(`dynamic2') vce(`se') nosample

* save
esttab using "${output}/regs_`bw'_`outcomeVar'_`hetVar'_`thisValue'_wed.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g)

}
}
}	
} // close loop over values of hetero var 
} // close loop over hetero var