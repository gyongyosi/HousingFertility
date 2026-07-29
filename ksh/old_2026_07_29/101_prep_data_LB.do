
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


gen ksh4_bpker_mother = notart
replace ksh4_bpker_mother = nolak if ksh4_bpker_mother == .
gen ksh4_bpker_father = fitart
replace ksh4_bpker_father = filak if ksh4_bpker_father == .

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
	gen ty_`X' = yofd(td_`X')
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

*keep if inrange(y_baby, 1973, .)
keep if inrange(ty_baby, 2010, .)

save "${temp}/LB_002", replace




/*------------------------------------------------------------------------------
	merge settlement level information
------------------------------------------------------------------------------*/


use "${temp}/tstar_important", clear
keep if ty == 2018
drop ty
keep ksh4_bpker jaras175 mkod2018 rkod2018 CSOK_0000 CSOK_5000 CSOK_all SH_t_1 SH_t_2 SH_t_3 SH_t_4 CSOK_15000 de01 emp_sh_0 emp_sh_1 emp_sh_2 emp_sh_3 emp_sh_4 emp_sh_5 emp_sh_6 emp_sh_7 emp_sh_8 emp_sh_9 subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 U_2018 ln_income_2018 women_15_49* 
compress
tempfile tstar
save `tstar'



use "${temp}/LB_002", clear

ren ksh4_bpker_mother ksh4_bpker
merge m:1 ksh4_bpker using `tstar', nogen keep(1 3)

replace apgar = . if apgar == 99
replace suly = . if suly == 9999
replace hossz = . if hossz == 99
replace thet = . if thet == 99

** thet<37
gen thet2 = thet-2
gen bef37w = thet2<37
lab var bef37w "Gest. weeks < 37"

gen parents_married = (ty_marriage != .)

gen POST = (ty_baby>2018)
gen low_weight = (suly < 2500)

gen hungarian = (noallp == 0)

foreach BW in "0000" all 5000 15000 {
	gen CSOK_`BW'_POST = CSOK_`BW' * POST
}

gen s_CSOK = subsidy_3 / women_15_49_TSTAR
gen s_CSOK_POST = s_CSOK * POST

gen ln_de01_2018 = ln(de01)

compress
save "${temp}/LB_003", replace
