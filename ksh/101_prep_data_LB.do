
forval i = 2016(1)2019 {
	
	use ${LB}/Szuletes_`i', clear
	
	foreach X of varlist * {
		local v`i'_`X' = strlower("`X'")
		ren `X' `v`i'_`X''
	}	
	
	tempfile y_`i'
	save `y_`i''
}




use ${LB}/Élveszuletes_1970-2015, clear

foreach X of varlist * {
	local v_`X' = strlower("`X'")
	ren `X' `v_`X''
}

forval i = 2016(1)2019 {
	append using `y_`i''
}

forval i = 2020(1)2024 {
	append using ${LB}/Szuletes_`i'
}


save "${temp}/LB_000", replace



use "${temp}/LB_000", clear

ren sz_* *


*** settlement 
ren nolak ksh4_bpker_mother
ren filak ksh4_bpker_father

foreach X in mother father {
	gen ksh4_`X' = ksh4_bpker_`X'
	foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
		replace ksh4_`X' = 1357 if ksh4_bpker_`X' == `Y'
	}
}


* generate dates

gen birth_td = mdy(esho, esnap, esev)
format birth_td %td 

gen birth_mother_td = mdy(noszho, nosznap, noszev)
format birth_mother_td %td

gen birth_father_td = mdy(fiszho, fisznap, fiszev)
format birth_father_td %td

gen birth_prev_td = mdy(eloho, elonap, eloev)
format birth_prev_td %td


foreach X in birth birth_father birth_mother birth_prev {
	gen `X'_ty = yofd(`X'_td)
	gen `X'_tm = mofd(`X'_td)
	format `X'_tm %tm
}

gen mother_age = birth_ty - birth_mother_ty
gen mother_age_tm = (birth_tm - birth_mother_tm) / 12


local vars_to_drop esho esnap esev noszho nosznap noszev fiszho fisznap fiszev eloho elonap eloev
drop `vars_to_drop'

save "${temp}/LB_001", replace




