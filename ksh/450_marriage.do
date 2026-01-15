




forval i = 2016(1)2024 {

	use ${marriage}/Hazassag_`i', clear
	
	foreach X of  varlist * {
				
		local v_`X' = strlower("`X'")
		ren `X' `v_`X''

	}	
	
	tempfile y_`i'
	save `y_`i''
	
	
	
}



use ${marriage}/Hazassag_1970-2015, clear

foreach X of  varlist * {
			
	local v_`X' = strlower("`X'")
	ren `X' `v_`X''

}

forval i = 2016(1)2024 {

	append using `y_`i''

}


foreach X of varlist hz_* {
	
	local new_name = subinstr("`X'", "hz_", "", 1)
	ren `X' `new_name'
	
}

save "${temp}/marriages_001", replace




/*------------------------------------------------------------------------------
	aggregate
------------------------------------------------------------------------------*/

use "${temp}/marriages_001", clear



foreach X in es fszul nszul {
	
	if "`X'" == "es" {
		local Y = "marriage"
	}
	if "`X'" == "fszul" {
		local Y = "husband"
	}
	if "`X'" == "nszul" {
		local Y = "wife"
	}

	
	gen ty_`Y' = `X'ev
	gen tm_`Y' = ym(`X'ev, `X'ho)
	format tm_`Y' %tm
	gen td_`Y' = mdy(`X'ho, `X'nap, `X'ev)
	format td_`Y' %td

}



gen one = 1

collapse (sum) one, by(ty_marriage)

line one ty, xline(2015.5 2019.5)
