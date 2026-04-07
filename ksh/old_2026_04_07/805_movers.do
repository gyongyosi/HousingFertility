cls
capture log close
log using "${temp}/run1015.log", replace

use "${temp}/census_002_trim_updated", clear

gen eterul_ksh4 = floor(eterul / 10)
gen eterul_ksh4_bpker = floor(eterul / 10)

foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace eterul_ksh4 = 1357 if eterul_ksh4_bpker == `Y'
}

gen MOVE = .
replace MOVE = 0 if lakev_x == 0
replace MOVE = 0 if lakev_x == 1 & lakev < 2019
replace MOVE = 1 if lakev_x == 1 & lakev >= 2019
replace MOVE = 2 if lakev_x == 1 & lakev >= 2019 & ksh4 == eterul_ksh4
replace MOVE = 3 if lakev_x == 1 & lakev >= 2019 & ksh4 != eterul_ksh4 & inrange(eterul_ksh4, 4000, 9999) 

lab def MOVE 0 "did not move" 1 "moved (across muni)" 2 "moved (within muni)" 3 "moved (from abroad)"
lab val MOVE MOVE



/**
* collapse by settlement
collapse (firstnm) U_2018 I_2018, by(ksh4)
* generate bins of 5
xtile U_2018_bin5 = U_2018, nq(5)
xtile I_2018_bin5 = I_2018, nq(5)
* generate bins of 2
xtile U_2018_bin2 = U_2018, nq(2)
xtile I_2018_bin2 = I_2018, nq(2)
* save
save "${temp}/binnedTSTAR", replace
* restore
use "${temp}/census_002_trim_updated", clear
drop _merge
* bring back into main data
merge m:1 ksh4 using  "${temp}/binnedTSTAR"
** adding 2-bin TSTAR with each of 2 FEs x 3 location vars
local controls23 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
local controls24 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
local controls25 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
local controls26 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
local controls27 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
local controls28 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin2##i.ty i.U_2018_bin2##i.ty
** adding 5-bin TSTAR with each of 2 FEs x 3 location vars
local controls29 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
local controls30 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
local controls31 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
local controls32 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
local controls33 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
local controls34 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.I_2018_bin5##i.ty i.U_2018_bin5##i.ty
**/



*** FLOW

local controls29 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty  i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty



forval J = 0(1)2 {
	
	reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & MOVE == `J', absorb(`controls29') vce("cluster ksh4")

	gen TIME_`J' = _n if inrange(_n, 2014, 2024)
	gen b_`J' = .
	gen se_`J' = .

	forval i = 2008(1)2024 {
		cap replace b_`J' = _b[1.CSOK_5000#`i'.ty] if TIME_`J' == `i'
		cap replace se_`J' = _se[1.CSOK_5000#`i'.ty] if TIME_`J' == `i'
	}
	gen hi_`J' = b_`J' + 1.96 * se_`J'
	gen lo_`J' = b_`J' - 1.96 * se_`J'


}

replace TIME_1 = TIME_0 + 0.1
replace TIME_2 = TIME_0 + 0.2


preserve

	drop if TIME_0 == .

	#d ;
		twoway 
			(connected b_0 TIME_0, lcolor("$color1") mcolor("$color1"))
			(connected b_1 TIME_1, lcolor("$color2") mcolor("$color2"))
			(connected b_2 TIME_2, lcolor("$color3") mcolor("$color3"))
			(rcap hi_0 lo_0 TIME_0, color("$color1")) 
			(rcap hi_1 lo_1 TIME_1, color("$color2")) 
			(rcap hi_2 lo_2 TIME_2, color("$color3")), 		
				graphregion(color(white))
				xtitle("Year")
				ytitle("Annual Birth Probability")
				legend(position(6) order(1 "Non-movers" 2 "Movers (across municipalities)" 3 "Movers (within municipality)"))
				xline(2019.5)
				yline(0)
				xlabel(2014(1)2024)
				yscale(range(-0.005 0.005))
				ylabel(-0.005(0.001)0.005)
			;
	#d cr

restore
	
graph export "${output}/pretrend_CSOK_5000_29_move_flow.pdf", as(pdf) replace
drop b_* se_* hi_* lo_* TIME_*






*** STOCK

local controls29 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty



forval J = 0(1)2 {
	
	reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & MOVE == `J', absorb(`controls29') vce("cluster ksh4")

	gen TIME_`J' = _n if inrange(_n, 2014, 2024)
	gen b_`J' = .
	gen se_`J' = .

	forval i = 2008(1)2024 {
		cap replace b_`J' = _b[1.CSOK_5000#`i'.ty] if TIME_`J' == `i'
		cap replace se_`J' = _se[1.CSOK_5000#`i'.ty] if TIME_`J' == `i'
	}
	gen hi_`J' = b_`J' + 1.96 * se_`J'
	gen lo_`J' = b_`J' - 1.96 * se_`J'


}

replace TIME_1 = TIME_0 + 0.1
replace TIME_2 = TIME_0 + 0.2


preserve

	drop if TIME_0 == .

	#d ;
		twoway 
			(connected b_0 TIME_0, lcolor("$color1") mcolor("$color1"))
			(connected b_1 TIME_1, lcolor("$color2") mcolor("$color2"))
			(connected b_2 TIME_2, lcolor("$color3") mcolor("$color3"))
			(rcap hi_0 lo_0 TIME_0, color("$color1")) 
			(rcap hi_1 lo_1 TIME_1, color("$color2")) 
			(rcap hi_2 lo_2 TIME_2, color("$color3")), 		
				graphregion(color(white))
				xtitle("Year")
				ytitle("Annual Birth Probability")
				legend(position(6) order(1 "Non-movers" 2 "Movers (across municipalities)" 3 "Movers (within municipality)"))
				xline(2019.5)
				yline(0)
				xlabel(2014(1)2024)
				yscale(range(-0.005 0.005))
				ylabel(-0.005(0.001)0.005)
			;
	#d cr

restore
	
graph export "${output}/pretrend_CSOK_5000_29_move_stock.pdf", as(pdf) replace
drop b_* se_* hi_* lo_* TIME_*
