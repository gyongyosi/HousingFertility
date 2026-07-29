

/*==============================================================================
	put together one settlement level file
==============================================================================*/


/*------------------------------------------------------------------------------
	election
------------------------------------------------------------------------------*/


use "${election}/election_2014_2022_final", clear
keep ksh4_bpker ty sh_fidesz sh_turnout
ren sh_fidesz sh_fidesz_
ren sh_turnout sh_turnout_
reshape wide sh_*, i(ksh4_bpker) j(ty)

tempfile election
save `election'



/*------------------------------------------------------------------------------
	fc
------------------------------------------------------------------------------*/

use "${fc}/Fertility_and_Crisis_indiv_data_20230405.dta", clear
duplicates drop ksh4_bpker, force
keep ksh4_bpker fcs_N
tempfile fcs
save `fcs'


/*------------------------------------------------------------------------------
	agglomeration
------------------------------------------------------------------------------*/


clear

import excel using  "${agglomeration}/agglomerációval ellátott helységnévtár.xlsx", sheet("Agglomeráció 2020.01.01.") first

ren HelységKSHkód ksh5
gen ksh4_bpker = int(ksh5 / 10)

gen ksh4 = ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}


gen a = Agglomerációk2003

gen agglomeration = 1
replace agglomeration = 0 if a == "999 - Településegyüttesbe nem tartozó települések"



duplicates drop ksh4_bpker, force

keep ksh4_bpker agglomeration

compress
save "${temp}/agglomeration_2003", replace


/*------------------------------------------------------------------------------
	census 2011 -- education controls
------------------------------------------------------------------------------*/


use "${census_2011}/szemely_2011", clear

foreach X of varlist * {
	local Q = strlower("`X'")
	ren `X' `Q'
}

keep if inrange(szev, ., 2004)

destring terul, gen(ksh5)
gen ksh4_bpker = int(ksh5/10)

destring irelsz, replace
gen eduCatg = 0
* no secondary school
replace eduCatg = 1 if inlist(irelsz,0,1, 2)
* secondary-vocational
replace eduCatg = 2 if inlist(irelsz,3,4, 5)
* secondary-general + some non-degree tertiary
replace eduCatg = 3 if inlist(irelsz,6,7, 8, 9, 10)
* college, university, or grad degree
replace eduCatg = 4 if inlist(irelsz,11, 12, 13, 14, 15)

tab eduCatg, gen(edu_)

collapse (sum) edu_*, by(ksh4_bpker)

gen edu_all = edu_1 + edu_2 + edu_3 + edu_4

forval i = 1(1)4 {
	gen SH_t_`i' = edu_`i' / edu_all
}

lab var SH_t_1 "education share: primary"
lab var SH_t_2 "education share: vocational"
lab var SH_t_3 "education share: high school"
lab var SH_t_4 "education share: college"

keep ksh4_bpker SH_t*

save "${temp}/census_2011_education", replace

/*------------------------------------------------------------------------------
	CSOK
------------------------------------------------------------------------------*/

use "${csok}/village_csok", clear
keep ksh4_bpker village_csok
ren village_csok CSOK_0000
lab var CSOK_0000 "Rural CSOK indicator (original)"
tempfile csok
save `csok'


use "${csok}/csok_takeup", clear

ren ksh4 ksh4_bpker 

local VARS "subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 number_of_contracts_2016_2023 families_csok_2016_2023 existing_kids_2016_2023 planned_kids_2016_2023 tamftcsok1623összesensum201 tamft1623összesensum201620"

keep ksh4_bpker `VARS'
foreach X of local VARS {
	replace `X' = 0 if `X' == .
}

tempfile csok_takeup
save `csok_takeup'


/*------------------------------------------------------------------------------
	demography
------------------------------------------------------------------------------*/

* women 15-49
use "${temp}/demography_1970_2024", clear

keep if inrange(ty, 2000, .)

keep if inrange(age, 15, 49)
keep if gender == 2

collapse (sum) population , by(ksh4_bpker ty)
ren population women_15_49

tempfile women_15_49
save `women_15_49'



* women 15-plus
use "${temp}/demography_1970_2024", clear

keep if inrange(ty, 2000, .)

keep if inrange(age, 15, .)
keep if gender == 2

collapse (sum) population , by(ksh4_bpker ty)
ren population women_15_plus

tempfile women_15_plus
save `women_15_plus'


* women 15-39
use "${temp}/demography_1970_2024", clear

keep if inrange(ty, 2000, .)

keep if inrange(age, 15, 39)
keep if gender == 2

collapse (sum) population , by(ksh4_bpker ty)
ren population women_15_39

tempfile women_15_39
save `women_15_39'


* women 40-plus
use "${temp}/demography_1970_2024", clear

keep if inrange(ty, 2000, .)

keep if inrange(age, 40, .)
keep if gender == 2

collapse (sum) population , by(ksh4_bpker ty)
ren population women_40_plus

tempfile women_40_plus
save `women_40_plus'


* women 18-plus
use "${temp}/demography_1970_2024", clear

keep if inrange(ty, 2000, .)

keep if inrange(age, 18, .)
keep if gender == 2

collapse (sum) population , by(ksh4_bpker ty)
ren population women_18_plus

tempfile women_18_plus
save `women_18_plus'



/*------------------------------------------------------------------------------
	Tstar
------------------------------------------------------------------------------*/

use "${tstar}/de", clear

ren tazon ksh4
ren ev ty

foreach X of varlist de* {
	replace `X' = 0 if `X' == .
}

gen women_15_49_TSTAR = de30 + de31 + de32 + de33 + de34 + de35
gen pop_15_64 =  (de30 + de31 + de32 + de33 + de34 + de35 + de36 + de37) + (de40 + de41 + de42 + de43 + de44 + de45 + de46 + de47)


keep  ksh4 ty de01 de02 de03 de11 de12 jaras175 mkod2018 rkod2018 women_15_49_TSTAR pop_15_64

gen tmp_de01 = de01 if ty == 2018
egen de01_2018 = mean(tmp_de01), by(ksh4)
drop tmp_de01

* missing if outside bandwidth, 1 just below 5K and 0 just above 5K
foreach BW in 2000 3000 4000 5000 15000 {

	gen CSOK_`BW' = .
	local lower = 5000 - `BW'
	local upper = 5000 + `BW'
	replace CSOK_`BW' = 1 if de01_2018!=. & inrange(de01_2018, `lower', 4999)
	replace CSOK_`BW' = 0 if de01_2018!=. & inrange(de01_2018, 5000, `upper')
	lab var CSOK_`BW' "CSOK indicator, bandwidth = `BW'"
}
* TIM addition 10/02/2025
gen CSOK_all = .
replace CSOK_all = 1 if de01_2018!=. & de01_2018<=4999 
replace CSOK_all = 0 if de01_2018!=. & de01_2018>=4999
lab var CSOK_all "CSOK indicator, bandwidth = all"

drop de01_2018

tempfile de
save `de'


use "${tstar}/mn", clear
ren tazon ksh4
ren ev ty
keep  ksh4 ty mn01
tempfile mn
save `mn'


use "${tstar}/tx", clear
ren tazon ksh4
ren ev ty
keep  ksh4 ty tx01 tx02 tx03
tempfile tx
save `tx'

use "${tstar}/al", clear
ren tazon ksh4
ren ev ty

foreach X of varlist al* {
	replace `X' = 0 if `X' == .
}


gen emp_0 = al01 + al02
gen emp_1 = al04 + al05
gen emp_2 = al06 + al07
gen emp_3 = al08 + al09
gen emp_4 = al10 + al11
gen emp_5 = al12 + al13
gen emp_6 = al14 + al15
gen emp_7 = al16 + al17
gen emp_8 = al18 + al19
gen emp_9 = al20 + al21

gen emp_all = emp_0 + emp_1 + emp_2 + emp_3 + emp_4 + emp_5 + emp_6 + emp_7 + emp_8 + emp_9 

forval i = 0(1)9 {
	gen emp_sh_`i' = emp_`i' / emp_all
}

keep  ksh4 ty emp_sh* emp_all
tempfile al
save `al'



/*------------------------------------------------------------------------------
	merge together stuff
------------------------------------------------------------------------------*/

use "${temp}/demography_1970_2024", clear
keep if ty >= 2000
keep ksh4_bpker
duplicates drop ksh4_bpker, force
tempfile muni
save `muni'

clear
set obs 3000
gen ty = _n
keep if inrange(ty, 2000, 2024)
tempfile time
save `time'

use `muni', clear
cross using `time'



gen ksh4 = ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}


merge 1:1 ksh4_bpker ty using `women_15_49', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `women_15_plus', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `women_15_39', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `women_40_plus', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `women_18_plus', keep(1 3) nogen

foreach X of varlist women* {
	replace `X' = 0 if `X' == .
}



merge m:1 ksh4_bpker  using "${temp}/census_2011_education", nogen keep(1 3)
merge m:1 ksh4 ty using `de', nogen keep(1 3)
merge m:1 ksh4 ty using `al', nogen keep(1 3)
merge m:1 ksh4 ty using `mn', nogen keep(1 3)
merge m:1 ksh4 ty using `tx', nogen keep(1 3)
merge m:1 ksh4_bpker  using `csok', nogen keep(1 3)
merge m:1 ksh4_bpker  using `csok_takeup', nogen keep(1 3)
merge m:1 ksh4_bpker using "${temp}/agglomeration_2003", nogen keep( 1 3)
merge m:1 ksh4_bpker using  `fcs', nogen keep( 1 3)

merge m:1 ksh4_bpker using  `election', nogen keep(1 3)


replace CSOK_0000 = 0 if CSOK_0000 == .



gen U = mn01 / de01
gen income = (tx02 - tx03) / tx01
gen ln_income = ln(income)
gen emp_SH = emp_all / pop_15_64

foreach X in de01 U ln_income {
	gen tmp_`X' = `X' if ty == 2018
	egen `X'_2018 = mean(tmp_`X'), by(ksh4_bpker)
	drop tmp_`X'
}





order ksh4 ty jaras mkod rkod CSOK_0 CSOK_2 CSOK_3 CSOK_4 CSOK_5 CSOK_all

save "${temp}/tstar_important", replace




aaa






/*------------------------------------------------------------------------------
	prep marriage data
------------------------------------------------------------------------------*/


local W "wife"

use "${temp}/marriages_002", clear

gen N_marriage = 1
gen N_marriage_kids0 = 1 if kids_wife == 0
gen N_marriage_kids1 = 1 if inrange(kids_wife,  1, 50)
gen N_marriage_age_15_39 = 1 if inrange(age_wife, 15, 39)
gen N_marriage_age_40_plus = 1 if inrange(age_wife, 40, 98)
gen N_marriage_edu1 = 1 if edu_wife == 1
gen N_marriage_edu2 = 1 if edu_wife == 2
gen N_marriage_edu3 = 1 if edu_wife == 3

collapse (sum) N_marriage* , by(ty_marriage ksh4_bpker_`W' )

ren ksh4_bpker_`W' ksh4_bpker
ren ty_marriage ty

tempfile marriage
save `marriage'





/*------------------------------------------------------------------------------
	prep divorce data
------------------------------------------------------------------------------*/



use "${temp}/divorce_002", clear

gen N_divorce = 1
gen N_divorce_kids0 = 1 if kids_wife == 0
gen N_divorce_kids1 = 1 if inrange(kids_wife,  1, 50)
gen N_divorce_age_15_39 = 1 if inrange(age_wife, 15, 39)
gen N_divorce_age_40_plus = 1 if inrange(age_wife, 40, 98)
gen N_divorce_edu1 = 1 if edu_wife == 1
gen N_divorce_edu2 = 1 if edu_wife == 2
gen N_divorce_edu3 = 1 if edu_wife == 3

collapse (sum) N_divorce* , by(ty_divorce ksh4_bpker_`W' )

ren ksh4_bpker_`W' ksh4_bpker
ren ty_divorce ty

tempfile divorce
save `divorce'







/*------------------------------------------------------------------------------
	prep abortion data
------------------------------------------------------------------------------*/

use "${temp}/abortion_002", clear


gen N_abortion = 1
gen N_abortion_kids0 = 1 if kids_mother == 0
gen N_abortion_kids1 = 1 if inrange(kids_mother,  1, 50)
gen N_abortion_age_15_39 = 1 if inrange(age_mother, 15, 39)
gen N_abortion_age_40_plus = 1 if inrange(age_mother, 40, 98)
gen N_abortion_edu1 = 1 if edu_mother == 1
gen N_abortion_edu2 = 1 if edu_mother == 2
gen N_abortion_edu3 = 1 if edu_mother == 3

collapse (sum) N_abortion* , by(ty_abortion ksh4_bpker_mother )

ren ksh4_bpker_mother ksh4_bpker
ren ty_abortion ty

tempfile abortion
save `abortion'





/*------------------------------------------------------------------------------
	prep internal migration
------------------------------------------------------------------------------*/

*** first version: include within settlement moves as well
clear
foreach BW in  "0000"  5000 15000 /* 5000 */ {

	foreach DIRECTION in "out" "in" {

		use "${temp}/internal_migration_02", clear
	
		ren `DIRECTION'_ksh4_bpker ksh4_bpker

		gen `DIRECTION'_M_CSOK_`BW' = .

		
		if "`DIRECTION'" == "in" {
			local QQ = "out"
			
			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		else if "`DIRECTION'" == "out" {
			local QQ = "in"

			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		gen N_INCL_migrate_`BW'_`DIRECTION'_ = 1

		collapse (sum) N_INCL_migrate_`BW'_`DIRECTION'_, by(ty ksh4_bpker `DIRECTION'_M_CSOK_`BW')
		
		reshape wide N_INCL_migrate_`BW'_`DIRECTION'_, i(ksh4_bpker ty) j(`DIRECTION'_M_CSOK_`BW')
		
		
		tempfile migrate_INCL_`DIRECTION'_`BW'
		save `migrate_INCL_`DIRECTION'_`BW''
	}

}
*** second version: exclude within settlement moves as well
clear
foreach BW in  "0000"  5000 15000 /* 5000 */ {

	foreach DIRECTION in "in" "out" {

		use "${temp}/internal_migration_02", clear
		
		drop if in_ksh4_bpker == out_ksh4_bpker
	
		ren `DIRECTION'_ksh4_bpker ksh4_bpker

		gen `DIRECTION'_M_CSOK_`BW' = .

		
		if "`DIRECTION'" == "in" {
			local QQ = "out"
			
			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		else if "`DIRECTION'" == "out" {
			local QQ = "in"

			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		gen N_EXCL_migrate_`BW'_`DIRECTION'_ = 1

		collapse (sum) N_EXCL_migrate_`BW'_`DIRECTION'_, by(ty ksh4_bpker `DIRECTION'_M_CSOK_`BW')
		
		reshape wide N_EXCL_migrate_`BW'_`DIRECTION'_, i(ksh4_bpker ty) j(`DIRECTION'_M_CSOK_`BW')
		
		
		tempfile migrate_EXCL_`DIRECTION'_`BW'
		save `migrate_EXCL_`DIRECTION'_`BW''
	}

}

*** third version: EXCL + women 15-49 
clear
foreach BW in  "0000"  5000 15000 /* 5000 */ {

	foreach DIRECTION in "in" "out" {

		use "${temp}/internal_migration_02", clear
		
		keep if nem == 2
		keep if inrange(korev, 15, 49)
		
		drop if in_ksh4_bpker == out_ksh4_bpker
	
		ren `DIRECTION'_ksh4_bpker ksh4_bpker

		gen `DIRECTION'_M_CSOK_`BW' = .

		
		if "`DIRECTION'" == "in" {
			local QQ = "out"
			
			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		else if "`DIRECTION'" == "out" {
			local QQ = "in"

			replace `DIRECTION'_M_CSOK_`BW' = 0 if  `QQ'_CSOK_`BW' == 0
			replace `DIRECTION'_M_CSOK_`BW' = 1 if  `QQ'_CSOK_`BW' == 1
		}
		
		gen N_women1549_migrate_`BW'_`DIRECTION'_ = 1

		collapse (sum) N_women1549_migrate_`BW'_`DIRECTION'_, by(ty ksh4_bpker `DIRECTION'_M_CSOK_`BW')
		
		reshape wide N_women1549_migrate_`BW'_`DIRECTION'_, i(ksh4_bpker ty) j(`DIRECTION'_M_CSOK_`BW')
		
		
		tempfile migrate_women1549_`DIRECTION'_`BW'
		save `migrate_women1549_`DIRECTION'_`BW''
	}

}


/*------------------------------------------------------------------------------
	merge marriage-divorce-abortion to the main file
------------------------------------------------------------------------------*/




use "${temp}/tstar_important", clear

merge 1:1 ksh4_bpker ty using `marriage', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `divorce', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `abortion', keep(1 3) nogen

merge 1:1 ksh4_bpker ty using `migrate_INCL_in_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_INCL_out_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_INCL_in_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_INCL_out_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_INCL_in_15000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_INCL_out_15000', keep(1 3) nogen

merge 1:1 ksh4_bpker ty using `migrate_EXCL_in_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_EXCL_out_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_EXCL_in_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_EXCL_out_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_EXCL_in_15000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_EXCL_out_15000', keep(1 3) nogen

merge 1:1 ksh4_bpker ty using `migrate_women1549_in_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_women1549_out_0000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_women1549_in_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_women1549_out_5000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_women1549_in_15000', keep(1 3) nogen
merge 1:1 ksh4_bpker ty using `migrate_women1549_out_15000', keep(1 3) nogen

save "${temp}/settlement_level_001", replace





/*------------------------------------------------------------------------------
	define variables
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_001", clear


foreach X of varlist N_marriage* N_divorce* N_abortion* {
	replace `X' = 0 if `X' == .
}

* define rates for marriage and divorce
replace de11 = 0 if de11 == .
replace de12 = 0 if de12 == .

gen women_18_plus_TSTAR = de11 + de12

foreach X in "" _kids0 _kids1 _age_15_39  _age_40_plus _edu1 _edu2 _edu3 {
	gen sh_marriage`X' = N_marriage`X' / (women_18_plus_TSTAR) * 1000
	gen sh_divorce`X' = N_divorce`X' / (women_18_plus_TSTAR) * 1000
	gen sh_abortion`X' = N_abortion`X' / (women_18_plus_TSTAR) * 1000
}

foreach X in  15_39  40_plus {
	gen SH_marriage_age_`X' = N_marriage_age_`X' / (women_`X') * 1000
	gen SH_divorce_age_`X' = N_divorce_age_`X' / (women_`X') * 1000
}


* migration variables
foreach X of varlist N_EXCL_mig* N_INCL_mig* N_women1549_mig* {
	replace `X' = 0 if `X' == .
}


xtset ksh4_bpker ty
foreach INCL in "INCL" "EXCL" "women1549" {
	foreach BW in "0000" 15000 {
		foreach DIRECTION in "in" "out" {
			foreach ELIG in 0 1 {
				gen q_`INCL'_mig_`BW'_`DIRECTION'_`ELIG' = N_`INCL'_migrate_`BW'_`DIRECTION'_`ELIG' / l.de01
			}
		}
	}
}

gen ln_de01 = ln(de01)
gen ln_women_15_plus = ln(women_15_plus)
gen ln_women_18_plus = ln(women_18_plus)
gen ln_women_18_plus_TSTAR = ln(women_18_plus_TSTAR)



foreach X of varlist   ln_de01 women_15_plus ln_women_15_plus women_18_plus women_18_plus_TSTAR ln_women_18_plus_TSTAR  {
	
	foreach Y in 2014 2018 {
		gen tmp_`X' = `X' if ty == `Y'
		egen `X'_`Y' = mean(tmp_`X'), by(ksh4_bpker)
		drop tmp_`X'
	}
}

gen RCSOK_per_women = subsidy_3_2019_2023 / women_18_plus_TSTAR_2018


gen post = (ty >= 2015)
lab var post "post-2015"
gen POST = (ty >= 2019)
lab var POST "post-2019"

gen CSOK_0000_POST = CSOK_0000 * POST
gen CSOK_5000_POST = CSOK_5000 * POST
gen CSOK_15000_POST = CSOK_15000 * POST
gen CSOK_all_POST = CSOK_all * POST

gen RCSOK_per_women_POST = RCSOK_per_women * POST

save "${temp}/settlement_level_002", replace












