cls
capture log close
log using "${temp}/runIVRegs_comprehensiveWed.log", replace

use "${temp}/census_002_unbal_filled_moreTSTAR", clear


gen tmp_OP_women_15_49_2018 = OP_women_15_49 if ty == 2018
egen OP_women_15_49_2018 = mean(tmp_OP_women_15_49_2018), by(szemazon)
drop tmp_OP_women_15_49_2018

gen OP_subsidy_3_2019_2023_perW = OP_subsidy_3_2019_2023 / OP_women_15_49_2018
gen OP_subsidy_3_2019_2023_perW_POST = OP_subsidy_3_2019_2023_perW * post



* outcome (x2): N_childrenNEW OR C_childrenNEW
local outcomeVars /* C_childrenNEW */ N_childrenNEW
* SE (x1): "cluster P_ksh4"
local ses `" "cluster P_ksh4" "'
* bandwidth/treatment variable (x6)
local bws /* 10000 5000 */ 15000 
* 9 ITT: all 25000 20000 15000 10000 5000 4000 3000 2000 
* 9 TOT: 0000_all 0000_25000 0000_20000 0000_15000 0000_10000 0000_5000 0000_4000 0000_3000 0000_2000
local pds 1

* specs that run within each loop/rft output
* pd=0
local dynamic1 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.OP_ln_income_2018_bin3#i.ty i.OP_U_2018_bin3#i.ty i.OP_kinderSpots_bin3#i.ty i.OP_shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.P_ksh4
local dynamic2 i.ty_mother_birth#i.ty i.marriedBy2019#i.ty i.kidsBy2019#i.ty i.eduCatg#i.ty i.OP_ln_income_2018_bin3#i.ty i.OP_U_2018_bin3#i.ty i.OP_kinderSpots_bin3#i.ty i.OP_shareWomen_15_49_bin3#i.ty i.ethCatg#i.ty i.relCatg#i.ty i.szemazon
* pd=1
local static1 i.P_ksh4 i.ty_mother_birth#i.post i.marriedBy2019#i.post i.kidsBy2019#i.post i.eduCatg#i.post i.OP_ln_income_2018_bin3#i.post i.OP_U_2018_bin3#i.post i.OP_kinderSpots_bin3#i.post i.OP_shareWomen_15_49_bin3#i.post i.ethCatg#i.post i.relCatg#i.post 
local static2 i.szemazon i.ty_mother_birth#i.post i.marriedBy2019#i.post i.kidsBy2019#i.post i.eduCatg#i.post i.OP_ln_income_2018_bin3#i.post i.OP_U_2018_bin3#i.post i.OP_kinderSpots_bin3#i.post i.OP_shareWomen_15_49_bin3#i.post i.ethCatg#i.post i.relCatg#i.post 

foreach outcomeVar of local outcomeVars {
	foreach se of local ses {
		foreach bw of local bws {
			foreach pd of local pds {
				disp("`outcomeVar'")
				disp("`se'")
				disp("`bw'")
				disp("`pd'")
				

				if `pd'==1  {
					* run and store regressions
					eststo clear
					eststo q_1: ivreghdfe `outcomeVar' (OP_subsidy_3_2019_2023_perW_POST = i.P_CSOK_`bw'##ib0.post), absorb(`static1') vce(`se') nosample
					eststo q_2: ivreghdfe `outcomeVar' (OP_subsidy_3_2019_2023_perW_POST = i.P_CSOK_`bw'##ib0.post), absorb(`static2') vce(`se') nosample
					* save
					esttab using "${output}/IVregs_`bw'_`pd'_`outcomeVar'_wed.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g) 
				}


			}
		}
	}
}