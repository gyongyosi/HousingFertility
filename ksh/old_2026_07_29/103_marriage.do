




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
	cleaning -- individual
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

keep if inrange(ty_marriage, 2000, .)

gen ksh4_bpker_wife = ntart
replace ksh4_bpker_wife = nlak if ksh4_bpker_wife == .

gen ksh4_bpker_husband = ftart
replace ksh4_bpker_husband = flak if ksh4_bpker_husband == .


foreach W in wife husband {

	gen ksh4_`W' = ksh4_bpker_`W'

	foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
		replace ksh4_`W' = 1357 if ksh4_bpker_`W' == `Y'
	}
}

gen edu_wife = .
replace edu_wife = 1 if inlist(nisk, 1, 2)
replace edu_wife = 1 if inlist(nisk99, 1, 2, 3, 4, 5)
replace edu_wife = 1 if inlist(nisk21, 0, 1, 2)

replace edu_wife = 2 if inlist(nisk, 3)
replace edu_wife = 2 if inlist(nisk99, 6, 7)
replace edu_wife = 2 if inlist(nisk21, 3)

replace edu_wife = 3 if inlist(nisk, 4)
replace edu_wife = 3 if inlist(nisk99, 8)
replace edu_wife = 3 if inlist(nisk21, 4)

replace edu_wife = 4 if inlist(nisk, 5)
replace edu_wife = 4 if inlist(nisk99, 9, 10)
replace edu_wife = 4 if inlist(nisk21, 5, 6, 7)


ren felve kids_husband
ren nelve kids_wife
ren fhazszam mcount_husband
ren nhazszam mcount_wife
ren fkor age_husband
ren nkor age_wife


foreach W in wife husband {
	replace kids_`W' = . if kids_`W' == 99
}

	
save "${temp}/marriages_002", replace





/*------------------------------------------------------------------------------
	collapse + merge settlement level variables
	
	important: there are some settlements with no marriage, hence they would be missing
	 --> start with T-Star
------------------------------------------------------------------------------*/

local W "wife"

use "${temp}/marriages_002", clear

gen N_marriages = 1
gen N_marriages_kids0 = 1 if kids_wife == 0
gen N_marriages_kids1 = 1 if inrange(kids_wife,  1, 50)
gen N_marriages_age_15_39 = 1 if inrange(age_wife, 15, 39)
gen N_marriages_age_40_plus = 1 if inrange(age_wife, 40, 98)

collapse (sum) N_marriages* , by(ty_marriage ksh4_`W' )
tempfile marriage
save `marriage'




use "${temp}/tstar_important", clear
ren ksh4 ksh4_`W'
ren ty ty_marriage

merge m:1 ksh4_`W' ty_marriage using `marriage', keep(1 3) nogen

foreach X of varlist N_marriages* {
	replace `X' = 0 if `X' == .
}

gen ln_de01 = ln(de01)
gen income = (tx02 - tx03) / tx01
gen ln_income = ln(income)
gen U = mn01 / de01

gen women_18_plus = de11 + de12
gen ln_women_18_plus = ln(women_18_plus)

foreach X of varlist ln_income de01 ln_de01 women_18_plus ln_women_18_plus de16 U {
	
	foreach Y in 2014 2018 {
		gen tmp_`X' = `X' if ty_marriage == `Y'
		egen `X'_`Y' = mean(tmp_`X'), by(ksh4_`W')
		drop tmp_`X'
	}
	
}


foreach X in "" _kids0 _kids1 _age_15_39  _age_40_plus {
	gen sh_marriages`X' = N_marriages`X' / (women_18_plus) * 1000
}
ren sh_marriages sh

gen RCSOK_per_women = subsidy_3_2019_2023 / women_18_plus_2018


gen POST_2015 = (ty_marriage>= 2015)
gen POST_2019 = (ty_marriage>= 2019)

gen CSOK_0000_POST_2019 = CSOK_0000 * POST_2019
gen CSOK_5000_POST_2019 = CSOK_5000 * POST_2019
gen CSOK_all_POST_2019 = CSOK_all * POST_2019

gen RCSOK_per_women_POST_2019 = RCSOK_per_women * POST_2019

ren ty_marriage ty


*keep if inrange(ty, 2014, 2024)

save "${temp}/marriages_003", replace









/*------------------------------------------------------------------------------
	TABLE: rural CSOK
------------------------------------------------------------------------------*/


global cc_1_post "c.ln_income_2018##i.POST_2019 c.U##i.POST_2019 c.ln_women_18_plus_2018##i.POST_2019 " /* c.ln_women_18_plus_2018##i.POST_2019 */
global cc_1_ty  "c.ln_income_2018##i.ty c.U##i.ty c.ln_women_18_plus_2018##i.ty" /* c.ln_women_18_plus_2018##i.ty */
 
global cc_2_post "i.rkod##i.POST_2019"
global cc_2_ty "i.rkod##i.ty"
 
global cc_3_post "i.mkod##i.POST_2019"
global cc_3_ty "i.mkod##i.ty"
  
global cc_4_post "i.jaras##i.POST_2019"
global cc_4_ty "i.jaras##i.ty"
  

  
  
use "${temp}/marriages_003", clear
keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000
  
eststo clear
eststo q_1 : reghdfe sh CSOK_0000_POST_2019 if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018] , absorb(ksh4 ty) cluster(ksh4)
	estadd local muni_fe "Yes"
	  
eststo q_2 : reghdfe sh CSOK_0000_POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 : reghdfe sh CSOK_0000_POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"  

	
qui: 	reghdfe CSOK_0000_POST_2019 CSOK_all_POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST_2019] / _se[CSOK_all_POST_2019])^2
		
	
eststo q_4 :  ivreghdfe sh (CSOK_0000_POST_2019 = i.CSOK_all##i.POST_2019)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'

	
qui: 	reghdfe RCSOK_per_women_POST_2019 CSOK_all_POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST_2019] / _se[CSOK_all_POST_2019])^2
	
eststo q_5 :  ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_all##i.POST_2019)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'
	

esttab
	
#d ;
esttab q* 	using "${output}/tab_marriage.rtf",  replace nocons 
	keep(CSOK_0000_POST_2019 RCSOK_per_women_POST_2019 ) coeflabel( CSOK_0000_POST_2019 "Rural CSOK \(\times\) Post" RCSOK_per_women_POST_2019 "Subsidies per women \(\times\) Post")	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 mtitles("OLS" "OLS" "OLS" "IV" "IV")
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			"Fstat F-statistics"
			) 
	;
#d cr	
	
	/*

* reghdfe -- treatment status
use "${temp}/marriages_003", clear


local BW = "0000"

eststo clear
eststo q_1 : reghdfe sh i.CSOK_`BW'##i.POST_2019 if inrange(de01_2018, 0, 10000) [aw = women_18_plus_2018], absorb(ksh4 ty)
	estadd local muni_fe "Yes"
	
eststo q_2 : reghdfe sh i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 : reghdfe sh i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"

	
eststo q_4 : reghdfe sh i.CSOK_`BW'##i.POST_2019 if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_3_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local county "Yes"

eststo q_5 : reghdfe sh i.CSOK_`BW'##i.POST_2019 if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_4_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"

esttab



* ivreghdfe -- eligibility
use "${temp}/marriages_003", clear


local BW = "0000"

eststo clear
eststo q_1 : ivreghdfe sh (CSOK_`BW'_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000) [aw = women_18_plus_2018], absorb(ksh4 ty)
	estadd local muni_fe "Yes"
	
eststo q_2 : ivreghdfe sh (CSOK_`BW'_POST_2019 = i.CSOK_5000##i.POST_2019)  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 :  ivreghdfe sh (CSOK_`BW'_POST_2019 = i.CSOK_5000##i.POST_2019)  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"

	
eststo q_4 :  ivreghdfe sh (CSOK_`BW'_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_3_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local county "Yes"

eststo q_5 :  ivreghdfe sh (CSOK_`BW'_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_4_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"

esttab



* ivreghdfe -- dose
use "${temp}/marriages_003", clear


local BW = "0000"

eststo clear
eststo q_1 : ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000) [aw = women_18_plus_2018], absorb(ksh4 ty)
	estadd local muni_fe "Yes"
	
eststo q_2 : ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_5000##i.POST_2019)  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 :  ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_5000##i.POST_2019)  if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"

	
eststo q_4 :  ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_3_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local county "Yes"

eststo q_5 :  ivreghdfe sh (RCSOK_per_women_POST_2019 = i.CSOK_5000##i.POST_2019) if inrange(de01_2018, 0, 10000)  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_4_post)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"

esttab
*/


/*------------------------------------------------------------------------------
	heterogeneity
------------------------------------------------------------------------------*/

use "${temp}/marriages_003", clear
  
local lower = 0
local upper = 20000

foreach BW in "0000" 2000 3000 4000 5000 {

	eststo clear

	eststo q_1 : reghdfe sh_marriages_kids0 i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
	eststo q_2 : reghdfe sh_marriages_kids1 i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_3 : reghdfe sh_marriages_age_15_39 i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_4 : reghdfe sh_marriages_age_40_plus i.CSOK_`BW'##i.POST_2019  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post $cc_2_post)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	#d ;
	esttab q* 	using "${output}/tab_marriage_heterogeneity_BW`BW'.rtf",  replace nocons 
	keep(CSOK_0000_POST_2019  ) coeflabel( CSOK_0000_POST_2019 "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
	;
	#d cr	
	
}


/*

* ppml
use "${temp}/marriages_003", clear

replace de01_2018 = round(de01_2018)

eststo clear
eststo q_1 : ppmlhdfe N_marriage i.CSOK_0000##i.POST_2019 if inrange(de01_2018, 0, 10000) [fw = women_18_plus_2018], absorb(ksh4 ty) cluster(ksh4) 
	estadd local muni_fe "Yes"

eststo q_2 : ppmlhdfe N_marriage i.CSOK_5000##i.POST_2019 if inrange(de01_2018, 0, 10000)  [fw = women_18_plus_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4) exposure(women_18_plus)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"


eststo q_3 : ppmlhdfe N_marriage i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"

eststo q_4 : ppmlhdfe N_marriage i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4 ty $cc_1_post $cc_3_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local county "Yes"

eststo q_5 : ppmlhdfe N_marriage i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4 ty $cc_1_post $cc_4_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"


esttab

*/

/*------------------------------------------------------------------------------
	FIGURE: rural CSOK
------------------------------------------------------------------------------*/



use "${temp}/marriages_003", clear

local lower = 0
local upper = 20000

foreach BW in "0000" all {

	reghdfe sh i.CSOK_`BW'##ib2017.ty   if inrange(ty, 2010, 2023)  & inrange(de01_2018, `lower', `upper') [aw = women_18_plus_2018], absorb(ksh4 ty $cc_1_ty $cc_2_ty  /*$cc_3_ty */) cluster(ksh4)

	gen TIME = _n if inrange(_n, 2010, 2024)
	gen b = .
	gen se = .

	forval i = 2010(1)2024 {
		cap replace b = _b[1.CSOK_`BW'#`i'.ty] if TIME == `i'
		cap replace se = _se[1.CSOK_`BW'#`i'.ty] if TIME == `i'
	}
	gen hi = b + 1.96 * se
	gen lo = b - 1.96 * se

	#d ;
		twoway 
			(connected b TIME, lcolor("$color1") mcolor("$color1"))
			(rcap hi lo TIME, color("$color1")), 
				graphregion(color(white))
				xtitle("Year")
				ytitle("Estimated coefficient")
				legend(off)
				xline(2014.5 2018.5)	
			;
	#d cr
	graph export "${output}/pretrend_marriage_BW`BW'.pdf", as(pdf) replace
	
	drop TIME b se hi lo
	
}



/*------------------------------------------------------------------------------
	trend in age at marriage
------------------------------------------------------------------------------*/



use "${temp}/marriages_002", clear

foreach X in husband wife {
	gen age_`X' = ty_marriage - ty_`X'
}


collapse (mean) age*, by(ty_marriage)


line age_hu ty


line age_wi age_hu ty







