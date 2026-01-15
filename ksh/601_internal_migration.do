

* fix bp kerületek !! 


/*------------------------------------------------------------------------------
	internal migration
	
	year 2022 is missing now (2025 August)
------------------------------------------------------------------------------*/

use "${temp}/tstar_important", clear
keep if ty == 2018
drop ty
tempfile tstar
save `tstar'





forval i = 2015(1)2024 {
	
	if `i' == 2022 {
		continue
	}
	
	use  "${internal_migration}/belfoldivandorlas_`i'", clear
	
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



use "${internal_migration}/belfoldi_vandorlas 1975-2012", clear


append using "${internal_migration}/belfoldi_vandorlas_2013-14"

forval i = 2015(1)2024 {
	cap append using `y_`i''
}


ren VA_* *

foreach X of  varlist * {
			
	local v`i'_`X' = strlower("`X'")
	ren `X' `v`i'_`X''

}	



lab var jel ""
lab var kshtip ""
lab var esev ""
lab var esho ""
lab var nem ""
lab var csal ""
lab var szulev ""
lab var allp ""
lab var odatel ""
lab var eltel ""
lab var korev ""


gen tm = (esev-1960) * 12 + esho - 1
format tm %tm

gen ty = yofd(dofm(tm))
drop esev esho

ren eltel out_ksh4_bpker
ren odatel in_ksh4_bpker

gen out_ksh4 = out_ksh4_bpker
gen in_ksh4 = in_ksh4_bpker


foreach X in out in {
	foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
		replace `X'_ksh4 = 1357 if `X'_ksh4_bpker == `Y'
	}
}




foreach X of varlist out_ksh4 in_ksh4 {

	local direction = subinstr("`X'", "_ksh4", "", .)

	
	ren `X' ksh4
	merge m:1 ksh4  using `tstar', nogen keep(1 3) keepusing(de01 tx01 tx02 tx03 mn01 CSOK_0000 CSOK_5000 mkod2018)
	
	ren ksh4 `X'

		
	foreach Y of varlist de01 tx01 tx02 tx03 mn01 CSOK_0000 CSOK_5000 mkod2018 {
		ren `Y' `direction'_`Y'
	}
}

foreach X of varlist in_CSOK* out_CSOK* {

		replace `X' = 0 if `X' == .

}


replace jel = 1 if jel == 2
replace jel = 1 if jel == 3



* sanity check: it is weird in the sample data
/*
gen age = ty - szulev
reg age korev
binscatter age korev
graph export ${output}/check_internal_migration_age.pdf, as(pdf) replace
*/

save "${temp}/internal_migration_01", replace



use "${temp}/internal_migration_01", clear

keep if inrange(ty, 2007, .)

save "${temp}/internal_migration_02", replace

