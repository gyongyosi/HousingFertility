** LIST: i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.szemazon i.ksh4 i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty i.rkod2018##i.ty i.mkod2018##i.ty i.jaras175##i.ty
local controls27 i.ty_mother_birth##i.ty i.kids_by_2018##i.ty i.eduCatg##i.ty i.rkod2018##i.ty i.szemazon i.marriedBy2019##i.ty i.lcstip##i.ty i.hungarian##i.ty i.relC##i.ty

** compute HP variable
use "${hp}/house_price_settlement", clear
rename year ty
sort ksh4_bpker ty
* choose price variable
local priceVar total_price

* generate relevant years
gen hp_2015_temp = `priceVar' if ty==2015
egen hp_2015 = max(hp_2015_temp), by(ksh4_bpker)
gen hp_2018_temp = `priceVar' if ty==2018
egen hp_2018 = max(hp_2018_temp), by(ksh4_bpker)
gen hp_2023_temp = `priceVar' if ty==2023
egen hp_2023 = max(hp_2023_temp), by(ksh4_bpker)
drop hp_2015_temp hp_2018_temp hp_2023_temp

* figure out which years have data for that price variable
gen HP_nonm = ty if `priceVar'!=. 
* last house price (2021 or after)
egen hp_lastY = max(HP_nonm), by(ksh4_bpker)
gen hp_last_temp = `priceVar' if ty==hp_lastY
egen hp_last = max(hp_last_temp), by(ksh4_bpker)
replace hp_last = . if hp_lastY < 2020
drop hp_lastY hp_last_temp
* first house price (2018 or before)
egen hp_firstY = min(HP_nonm), by(ksh4_bpker)
gen hp_first_temp = `priceVar' if ty==hp_firstY
egen hp_first = max(hp_first_temp), by(ksh4_bpker)
replace hp_first = . if hp_firstY > 2018
drop hp_first_temp
* pre treatment house price (closest to 2018 we can get)
gen hp_preY = hp_firstY
replace hp_preY = 2016 if ty==2016 & `priceVar'!=.
replace hp_preY = 2017 if ty==2017 & `priceVar'!=.
replace hp_preY = 2018 if ty==2018 & `priceVar'!=.
gen hp_pre_temp = `priceVar' if ty==hp_preY
egen hp_pre = max(hp_pre_temp), by(ksh4_bpker)
replace hp_pre = . if hp_preY > 2018
drop HP_nonm hp_firstY hp_preY hp_pre_temp 

* identify high and low growth settlements
gen delta18 = 100*(hp_2023 - hp_2018) / hp_2018
gen delta15 = 100*(hp_2023 - hp_2015) / hp_2015
gen deltaPre = 100*(hp_last - hp_pre) / hp_pre
gen deltaFirst = 100*(hp_last - hp_first) / hp_first

collapse (firstnm) delta18 delta15 deltaPre deltaFirst, by(ksh4_bpker)
drop if delta18==. & delta15==.  & deltaPre==.  & deltaFirst==.
rename ksh4_bpker ksh4 
merge 1:1 ksh4 using "${temp}/tstar_important_2019"
keep if _merge==3
keep ksh4 delta18 delta15 deltaPre deltaFirst CSOK_5000 CSOK_4000
rename ksh4 ksh4_bpker
drop if CSOK_5000==.
 * two groups
xtile delta18G = delta18, nq(2)
xtile delta15G = delta15, nq(2)
xtile deltaPreG = deltaPre, nq(2)
xtile deltaFirstG = deltaFirst, nq(2)
save "${hp}/house_price_settlement_coll", replace


use "${temp}/census_002_trim_updated", clear
drop _merge
merge m:1 ksh4_bpker using "${hp}/house_price_settlement_coll"
drop if _merge==2

** compute parity variable
gen paritySplit = kids_by_2018
replace paritySplit = 3 if kids_by_2018 > 3

forval cc = 0(1)3 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & paritySplit==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_parity_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1(1)4 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & eduCatg==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_educ_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1965(5)2005 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & cohort5==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_age_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 0(1)1 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & marriedBy2019==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_marr_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1(1)2 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & delta18G==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_18G_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1(1)2 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & delta15G==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_15G_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1(1)2 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & deltaPreG==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_PreG_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************

forval cc = 1(1)2 {

reghdfe N_childrenNEW i.CSOK_5000##ib2019.ty if inrange(ty, 2014, 2024) & deltaFirstG==`cc', absorb(`controls27') vce("cluster ksh4")

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
		;
#d cr
graph export "${output}/pretrend_CSOK_5000_FirstG_`cc'.pdf", as(pdf) replace
drop b se hi lo TIME

}

***************************************************