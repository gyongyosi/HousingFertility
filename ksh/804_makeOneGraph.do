cls
capture log close
log using "${temp}/run1013.log", replace

use "${temp}/census_002_trim_updated", clear

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

******* dynamic
* three core controls
local controls1 i.ty_mother_birth##i.ty
local controls2 i.kids_by_2018##i.ty
local controls3 i.eduCatg##i.ty
local controls4 i.kids_by_2018##i.ty i.eduCatg##i.ty
local controls5 i.ty_mother_birth##i.ty i.eduCatg##i.ty
local controls6 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty
local controls7 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty
* marriage
local controls8 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty
* woman/settlement FEs
local controls9 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.szemazon
local controls10 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.ksh4
* 3 location-year FEs (x2 FEs)
local controls11 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.szemazon i.rkod2018##i.ty
local controls12 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.szemazon i.mkod2018##i.ty
local controls13 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.szemazon i.jaras175##i.ty
local controls14 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.ksh4 i.rkod2018##i.ty
local controls15 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.ksh4 i.mkod2018##i.ty
local controls16 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.marriedBy2019##i.ty i.ksh4 i.jaras175##i.ty
* last three controls all at once with each of 2 FEs x 3 location vars
local controls17 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
local controls18 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
local controls19 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
local controls20 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
local controls21 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.mkod2018##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
local controls22 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.jaras175##i.ty i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty
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

******* static
* three core controls
local controls35 i.ty_mother_birth i.kids_by_2018 i.eduCatg
* marriage as fourth control with each of FE
local controls36 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.szemazon i.marriedBy2019
local controls37 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.ksh4 i.marriedBy2019
* last three controls all at once with each of FE 
local controls38 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.szemazon i.marriedBy2019 i.lcstip i.hungarian i.relC
local controls39 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.ksh4 i.marriedBy2019 i.lcstip i.hungarian i.relC
* last TSTAR (5) controls with each kind of FE
local controls40 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.szemazon i.marriedBy2019 i.lcstip i.hungarian i.relC i.I_2018_bin5 i.U_2018_bin5
local controls41 i.ty_mother_birth i.kids_by_2018 i.eduCatg i.ksh4 i.marriedBy2019 i.lcstip i.hungarian i.relC i.I_2018_bin5 i.U_2018_bin5

forval cc = 1(1)41 {

reghdfe C_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls`cc'') vce("cluster ksh4")

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
			ytitle("Total Children")
			legend(off)
			xline(2019.5)
			yline(0)
			xlabel(2014(1)2024)
			yscale(range(-0.025 0.025))
			ylabel(-0.025(0.005)0.025)			
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_`cc'_cumul.pdf", as(pdf) replace
drop b se hi lo TIME

}
********************************************************************************
** no controls
reghdfe C_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), vce("cluster ksh4")

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
			ytitle("Total Children")
			legend(off)
			xline(2019.5)
			yline(0)
			xlabel(2014(1)2024)
			yscale(range(-0.025 0.025))
			ylabel(-0.025(0.005)0.025)					
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_0_cumul.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************
** robust standard errors
reghdfe C_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty) vce(robust)

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
			yscale(range(-0.025 0.025))
			ylabel(-0.025(0.005)0.025)				
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_robust_cumul.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************
** 4000 bandwidth
reghdfe C_childrenNEW i.CSOK_4000##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty) vce("cluster ksh4")

gen TIME = _n if inrange(_n, 2014, 2024)
gen b = .
gen se = .

forval i = 2008(1)2024 {
	cap replace b = _b[1.CSOK_4000#`i'.ty] if TIME == `i'
	cap replace se = _se[1.CSOK_4000#`i'.ty] if TIME == `i'
}
gen hi = b + 1.96 * se
gen lo = b - 1.96 * se

#d ;
	twoway 
		(connected b TIME, lcolor("$color1") mcolor("$color1"))
		(rcap hi lo TIME, color("$color1")), 
			graphregion(color(white))
			xtitle("Year")
			ytitle("Total Children")
			legend(off)
			xline(2019.5)
			yline(0)
			xlabel(2014(1)2024)
			yscale(range(-0.025 0.025))
			ylabel(-0.025(0.005)0.025)			
		;
#d cr
graph export "${output}/pretrend_CSOK_4000_bw_cumul.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************
**** FLOW ***************************************************************

forval cc = 1(1)41 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), absorb(`controls`cc'') vce("cluster ksh4")

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
graph export "${output}/pretrend_CSOK_5000_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}
********************************************************************************
** no controls
reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), vce("cluster ksh4")

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
graph export "${output}/pretrend_CSOK_5000_0.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************
** robust standard errors
reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty) vce(robust)

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
graph export "${output}/pretrend_CSOK_5000_robust.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************
** 4000 bandwidth
reghdfe N_childrenNEW i.CSOK_4000##ib2019.ty if inrange(ty, 2014, 2024), absorb(i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty) vce("cluster ksh4")

gen TIME = _n if inrange(_n, 2014, 2024)
gen b = .
gen se = .

forval i = 2008(1)2024 {
	cap replace b = _b[1.CSOK_4000#`i'.ty] if TIME == `i'
	cap replace se = _se[1.CSOK_4000#`i'.ty] if TIME == `i'
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
graph export "${output}/pretrend_CSOK_4000_bw.pdf", as(pdf) replace
drop b se hi lo TIME

********************************************************************************