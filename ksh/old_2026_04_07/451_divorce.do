



forval i = 2016(1)2024 {

	use ${divorce}/Valas_`i', clear
	
	foreach X of  varlist * {
				
		local v_`X' = strlower("`X'")
		ren `X' `v_`X''

	}	
	
	tempfile y_`i'
	save `y_`i''
	
	
	
}



use ${divorce}/Valas_1977-2015, clear

foreach X of  varlist * {
			
	local v_`X' = strlower("`X'")
	ren `X' `v_`X''

}

forval i = 2016(1)2024 {

	append using `y_`i''

}


foreach X of varlist vl_* {
	
	local new_name = subinstr("`X'", "vl_", "", 1)
	ren `X' `new_name'
	
}

save "${temp}/divorce_001", replace





use "${temp}/divorce_001", clear



foreach X in es kot fszul nszul {
	
	if "`X'" == "es" {
		local Y = "divorce"
	}
	if "`X'" == "fszul" {
		local Y = "husband"
	}
	if "`X'" == "nszul" {
		local Y = "wife"
	}
	if "`X'" == "kot" {
		local Y = "marriage"
	}
	
	gen ty_`Y' = `X'ev
	gen tm_`Y' = ym(`X'ev, `X'ho)
	format tm_`Y' %tm
	gen td_`Y' = mdy(`X'ho, `X'nap, `X'ev)
	format td_`Y' %td

}




gen one = 1

collapse (sum) one, by(ty_divorce)

line one ty,


