cls
capture log close
log using "${temp}/run1015.log", replace

use "${temp}/census_002_trim_updated", clear

gen mover = (lakev_x==1 & lakev >= 2019)
drop if mover = 1 

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

local controls9 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.szemazon


reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls9') vce("cluster ksh4")

gen TIME = _n if inrange(_n, 2014, 2024)
gen b = .
gen se = .

forval i = 2008(1)2024 {
	cap replace b = _b[1.CSOK_5000#`i'.ty] if TIME == `i'
	cap replace se = _se[1.CSOK_5000#`i'.ty] if TIME == `i'
}
gen hi = b + 1.96 * se
gen lo = b - 1.96 * se

#d ;
	twoway 
		(connected b TIME, lcolor("$color1") mcolor("$color1"))
		(rcap hi lo TIME, color("$color1")), 
			graphregion(color(white))
			xtitle("Year")
			ytitle("Annual Birth Probability")
			legend(off)
			xline(2019.5)
			yline(0)
			xlabel(2014(1)2024)
			yscale(range(-0.005 0.005))
			ylabel(-0.005(0.001)0.005)
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_9_move.pdf", as(pdf) replace
drop b se hi lo TIME