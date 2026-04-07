

/*------------------------------------------------------------------------------
	abortion
------------------------------------------------------------------------------*/





forval i = 2016(1)2024 {
	
	
	use  "${abortion}/terhessegmegszakitas_`i'", clear
	
	if inlist(`i', 2015, 2016, 2017, 2018) {
		
		tempfile y_`i'
		save `y_`i''
		
	}
	else if inrange(`i', 2019, 2024) {
		foreach X of  varlist * {
			
			local v`i'_`X' = strupper("`X'")
			ren `X' `v`i'_`X''

		}		
		tempfile y_`i'
		save `y_`i''
	}

}



use ${abortion}/Terhessegmegszakitas_1975-2015, clear

forval i = 2016(1)2024 {
	append using `y_`i''
}

ren MU_* *

foreach X of  varlist * {
			
	local v`i'_`X' = strlower("`X'")
	ren `X' `v`i'_`X''

}	

gen td = mdy(esho, esnap, esev)
format td %td
gen ty = yofd(td)

gen td_mother = mdy(szulho, szulnap, szulev)
format td_mother %td
gen ty_mother = yofd(td_mother)



ren lak ksh4_bpker
gen ksh4 = ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}


save "${temp}/abortion_001", replace


aaa

*** full population
use "${temp}/demography_1970_2023_women", clear
collapse (sum) population , by(ksh4 ty)
ren population N_women_15_49
tempfile number_women
save `number_women'

use ${tstar}/de, clear
keep if ev == 2018
ren tazon ksh4
keep ksh4 de01
tempfile population
save `population'



use "${temp}/abortion_001", clear

gen abortion = 1

collapse (sum) abortion , by(ksh4 ty)

merge m:1 ksh4 using `population', nogen keep(1 3)
merge m:1 ksh4 ty using `number_women', nogen keep(1 3)


foreach BW in 1000 1500 2000 3000 4000 5000 {

	gen CSOK_`BW' = .
	local lower = 5000 - `BW'
	local upper = 5000 + `BW'
	replace CSOK_`BW' = 1 if inrange(de01, `lower', 4999)
	replace CSOK_`BW' = 0 if inrange(de01, 5000, `upper')
	
}

keep if CSOK_2000 != .


collapse (sum) abortion N_women, by(CSOK_2000 ty)


gen abortion_rate_ = abortion / N_women_15_49
keep abortion_rate ty CSOK_2000
reshape wide abortion, i(ty) j(CSOK_2000)


line abortion_rate* ty, lpattern(_ solid) xline(2019)

gen diff = abortion_rate_1 - abortion_rate_0

line diff ty, xline(2019)








*** by cohort
use "${temp}/demography_1970_2023_women", clear

gen cohort = .
forval i = 15(5)45 {
		local j = `i' + 4
		replace cohort = `i' if inrange(age, `i', `j')
}

collapse (sum) population , by(ksh4 ty cohort)
ren population N_women
tempfile number_women
save `number_women'

use ${tstar}/de, clear
keep if ev == 2018
ren tazon ksh4
keep ksh4 de01
tempfile population
save `population'



use "${temp}/abortion_001", clear

gen age = ty - ty_mother

gen cohort = .
forval i = 15(5)45 {
		local j = `i' + 4
		replace cohort = `i' if inrange(age, `i', `j')
}

gen abortion = 1

collapse (sum) abortion , by(ksh4 ty cohort)

merge m:1 ksh4 using `population', nogen keep(1 3)
merge m:1 ksh4 ty cohort using `number_women', nogen keep(1 3)


foreach BW in 1000 1500 2000 3000 4000 5000 {

	gen CSOK_`BW' = .
	local lower = 5000 - `BW'
	local upper = 5000 + `BW'
	replace CSOK_`BW' = 1 if inrange(de01, `lower', 4999)
	replace CSOK_`BW' = 0 if inrange(de01, 5000, `upper')
	
}

keep if CSOK_2000 != .


collapse (sum) abortion N_women, by(CSOK_2000 ty cohort)


gen abortion_rate_ = abortion / N_women
keep abortion_rate ty CSOK_2000 cohort
drop if cohort == .
reshape wide abortion_rate, i(ty CSOK_2000) j(cohort)
ren abortion* abortion*_
reshape wide abortion*, i(ty ) j(CSOK_2000)



line abortion_rate_25* ty, lpattern(_ solid) xline(2019)
line abortion_rate_30* ty, lpattern(_ solid) xline(2019)
line abortion_rate_35* ty, lpattern(_ solid) xline(2019)

gen diff = abortion_rate_1 - abortion_rate_0

line diff ty, xline(2019)

