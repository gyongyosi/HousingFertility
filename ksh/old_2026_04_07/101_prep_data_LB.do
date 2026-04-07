
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

foreach X in esho noszho fiszho esnap nosznap fisznap eloho elonap hazho haznap {
	replace `X' = . if `X' == 99
}

foreach X in esev noszev fiszev eloev hazev {
	replace `X' = . if `X' == 9999
}




gen td_baby = mdy(esho, esnap, esev)
format td_baby %td 

gen td_mother = mdy(noszho, nosznap, noszev)
format td_mother %td

gen td_father = mdy(fiszho, fisznap, fiszev)
format td_father %td

gen td_prev = mdy(eloho, elonap, eloev)
format td_prev %td

gen td_marriage = mdy(hazho, haznap, hazev)
format td_marriage %td

ren esho m_baby
ren noszho m_mother
ren fiszho m_father
ren esnap d_baby
ren nosznap d_mother
ren fisznap d_father
ren eloho m_prev
ren elonap d_prev
ren hazho m_marriage
ren haznap d_marriage

ren esev y_baby
ren noszev y_mother
ren fiszev y_father
ren eloev y_prev
ren hazev y_marriage

foreach X in baby mother father marriage prev {
	gen tm_`X' = ym(y_`X', m_`X')
	format tm_`X' %tm
}




gen mother_age = y_baby - y_mother



* education
foreach X in no fi {
	
	if "`X'" == "no" {
		local j = "mother" 
	}
	else if "`X'" == "fi" {
		local j = "father"
	}
	
	

	gen edu_`j' = .
	replace edu_`j' = 1 if inrange(`X'isk, 1, 2)
	replace edu_`j' = 2 if inrange(`X'isk, 3, 3)
	replace edu_`j' = 3 if inrange(`X'isk, 4, 4)
	replace edu_`j' = 4 if inrange(`X'isk, 5, 5)

	replace edu_`j' = 1 if inrange(`X'isk99, 1, 5)
	replace edu_`j' = 2 if inrange(`X'isk99, 6, 7)
	replace edu_`j' = 3 if inrange(`X'isk99, 8, 8)
	replace edu_`j' = 4 if inrange(`X'isk99, 9, 10)

	replace edu_`j' = 1 if inrange(`X'isk21, 0, 2)
	replace edu_`j' = 2 if inrange(`X'isk21, 3, 3)
	replace edu_`j' = 3 if inrange(`X'isk21, 4, 4)
	replace edu_`j' = 4 if inrange(`X'isk21, 5, 7)	
}



lab def edu 1 "primary school" 2 "vocational school" 3 "high school" 4 "college"
lab val edu_mother edu
lab val edu_father edu


gen id_baby = _n



save "${temp}/LB_001", replace



/*------------------------------------------------------------------------------
	information on previous birth is only available from 1973
------------------------------------------------------------------------------*/

use  "${temp}/LB_001", clear

keep if inrange(y_baby, 1973, .)

save "${temp}/LB_002", replace
