/*------------------------------------------------------------------------------
	load raw Live Birth data and concatenate into LB_000 
------------------------------------------------------------------------------*/
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

/*------------------------------------------------------------------------------
	load LB_000 and format location, dates, education, then save as LB_001
------------------------------------------------------------------------------*/
use "${temp}/LB_000", clear

ren sz_* *
*** settlement (what is notart and fitart?)
gen ksh4_bpker_mother = notart
replace ksh4_bpker_mother = nolak if ksh4_bpker_mother == .
gen ksh4_bpker_father = fitart
replace ksh4_bpker_father = filak if ksh4_bpker_father == .

** all 23 Budapest districts into one ksh-style label?
foreach X in mother father {
	gen ksh4_`X' = ksh4_bpker_`X'
	foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
		replace ksh4_`X' = 1357 if ksh4_bpker_`X' == `Y'
	}
}

** generate dates: nicely format them the 5 important dates

* for days and months variables, replace 99 with Stata's missing
foreach X in esho noszho fiszho hazho eloho esnap nosznap fisznap haznap elonap {
	replace `X' = . if `X' == 99
}
* for years variables, replace 9999 with Stata's missing
foreach X in esev noszev fiszev hazev eloev {
	replace `X' = . if `X' == 9999
}
* concatenate all 3 components
* NOTE: if any component is missing or 0, this concatenation produces a missing value
** for marriage, 0 denotes not married (20%), gets generated to missing
** for previous baby, 0 denotes first born (46%), gets generated to missing
** NOTE: when matching across birth parity slices in 801, I use the individual date parts
gen td_baby = mdy(esho, esnap, esev)
format td_baby %td 
gen td_mother = mdy(noszho, nosznap, noszev)
format td_mother %td
gen td_father = mdy(fiszho, fisznap, fiszev)
format td_father %td
gen td_marriage = mdy(hazho, haznap, hazev)
format td_marriage %td
gen td_prev = mdy(eloho, elonap, eloev)
format td_prev %td

* rename months of dates
ren esho m_baby
ren noszho m_mother
ren fiszho m_father
ren hazho m_marriage
ren eloho m_prev
* rename days of dates
ren esnap d_baby
ren nosznap d_mother
ren fisznap d_father
ren haznap d_marriage
ren elonap d_prev
* rename years of dates
ren esev y_baby
ren noszev y_mother
ren fiszev y_father
ren eloev y_prev
ren hazev y_marriage

* what is this doing?
foreach X in baby mother father marriage prev {
	* concatenate 2 components: year and month
	gen tm_`X' = ym(y_`X', m_`X')
	format tm_`X' %tm
	* one component: just year
	gen ty_`X' = y_`X' // before summer 2026, used to be: yofd(td_`X')
}
* Note: there are a lot of mothers with birth years but no more, but born before 1955

* generate mother's age
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

* IMPORTANT: generate unique LB baby ID
gen id_baby = _n
* save 
save "${temp}/LB_001", replace

/*------------------------------------------------------------------------------
	trim to only women born and births occurring after a certain date
------------------------------------------------------------------------------*/

use  "${temp}/LB_001", clear

* IMPORTANT: keep only women who are 49 or younger in 2010
keep if inrange(y_mother,1961,.) // we had this at 1965 previously, now at 1961
* IMPORTANT: keep only kids born 1976 or later (prev birth info available only from 1973)
keep if inrange(y_baby,1976,.) // we had this at 2010 previously, now at 1976
* drop twins 2.5% of the sample!
keep if iker == 1

* drop if td_baby == .
* drop if td_mother == .
/* what identifies an observation?
duplicates tag td_baby td_mother, gen(tag_1) /* date of mother, date of birth */
tab tag_1
duplicates tag td_baby td_mother nem, gen(tag_2) /* + gender */ 
tab tag_2
duplicates tag td_baby td_mother nem elve1, gen(tag_3) /* + total number of kids  */
tab tag_3
duplicates tag td_baby td_mother nem elve1 eduCat, gen(tag_4) /* + mother education */
tab tag_4
*/

save "${temp}/LB_002", replace

/*------------------------------------------------------------------------------
	merge 2018 settlement-level information from T-STAR
------------------------------------------------------------------------------*/

* create temporary T-STAR data file from tstar_important (see 107 code file)
use "${temp}/tstar_important", clear
* snapshot from 2018, the pre-treatment year
keep if ty == 2018
* keep variables of interest
keep ksh4_bpker jaras175 mkod2018 rkod2018 CSOK_* SH_t_1 SH_t_2 SH_t_3 SH_t_4 CSOK_15000 de01 emp_sh_0 emp_sh_1 emp_sh_2 emp_sh_3 emp_sh_4 emp_sh_5 emp_sh_6 emp_sh_7 emp_sh_8 emp_sh_9 subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 U_2018* ln_income_2018* women_15_49* 
* save temporary T-STAR data file
compress
tempfile tstar
save `tstar'

* load trimmed LB data
use "${temp}/LB_002", clear
* merge with temporary T-STAR data file
ren ksh4_bpker_mother ksh4_bpker
merge m:1 ksh4_bpker using `tstar', nogen keep(1 3)

* adjust some LB variables
replace apgar = . if apgar == 99
replace suly = . if suly == 9999
replace hossz = . if hossz == 99
replace thet = . if thet == 99
** thet<37
gen thet2 = thet-2 // weeks of pregancy, why subtract 2?
gen bef37w = thet2<37
lab var bef37w "Gest. weeks < 37"
gen parents_married = (ty_marriage != .)
gen low_weight = (suly < 2500)
gen hungarian = (noallp == 0)

* IMPORTANT: creates post-treatment variable here--do we want to include first half of 2019?
gen POST = (ty_baby>2018)
foreach BW in all 25000 20000 15000 10000 5000 4000 3000 2000 0000_all 0000_25000 0000_20000 0000_15000 0000_10000 0000_5000 0000_4000 0000_3000 0000_2000 {
	gen CSOK_`BW'_POST = CSOK_`BW' * POST
}
* creates take-up intensity variables
gen s_CSOK = subsidy_3 / women_15_49_TSTAR
gen s_CSOK_POST = s_CSOK * POST

* log settlement population
gen ln_de01_2018 = ln(de01)
* save 
compress
save "${temp}/LB_for_matching_001", replace