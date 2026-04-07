





/*==============================================================================
	MARRIAGE
==============================================================================*/

/* c.ln_women_18_plus_2018##i.POST_2019 */

*  

global cc_1_post " c.ln_income_2018##i.POST c.U_2018##i.POST c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST  c.ln_women_18_plus_TSTAR##i.POST" 
* c.ln_women_18_plus_TSTAR##i.POST " 
global cc_1_ty  " c.ln_income_2018##i.ty c.U##i.ty c.ln_women_18_plus_TSTAR##i.ty"
 /* c.ln_women_18_plus_2018##i.ty */
 
global cc_2_post "i.rkod##i.POST"
global cc_2_ty "i.rkod##i.ty"
 
global cc_3_post "i.mkod##i.POST"
global cc_3_ty "i.mkod##i.ty"
  
global cc_4_post "i.jaras##i.POST"
global cc_4_ty "i.jaras##i.ty"
  

  
  
  
foreach BW in "0000" 5000 15000 {
	
	use "${temp}/settlement_level_002", clear

	keep if inrange(ty, 2014, .)
	keep if inrange(de01_2018, 0, 20000)
	keep if CSOK_`BW' != .

	
	eststo clear
	eststo q_1 : reghdfe sh_marriage CSOK_`BW'_POST  [aw = women_18_plus_TSTAR_2018] , absorb(ksh4 ty) cluster(ksh4)
		estadd local muni_fe "Yes"
		  
	eststo q_2 : reghdfe sh_marriage CSOK_`BW'_POST   [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"

	eststo q_3 : reghdfe sh_marriage CSOK_`BW'_POST   [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  
		
	eststo q_4 :  reghdfe sh_marriage CSOK_`BW'_POST     [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post   $cc_3_post  ) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local county "Yes"	
		
		
	eststo q_5 :  reghdfe sh_marriage  CSOK_`BW'_POST     [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post  $cc_4_post ) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"	
		
		

	esttab
		
	#d ;
	esttab q* 	using "${output}/tab_marriage_OLS_BW`BW'.rtf",  replace nocons 
		keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		 nomtitles
		scalars("muni_fe  Municipality \& Year FE"
				"controls Controls"
				"region Region FE"
				"county County FE"
				"subregion Subregion FE"
				
				) 
		;
	#d cr	

}



foreach BW in  5000 15000 {
	use "${temp}/settlement_level_002", clear

	keep if inrange(ty, 2014, .)
	keep if inrange(de01_2018, 0, 20000)
	keep if CSOK_`BW' != .

	
	eststo clear
	eststo q_1 : ivreghdfe sh_marriage (CSOK_0000_POST = CSOK_`BW'_POST)  [aw = women_18_plus_TSTAR_2018] , absorb(ksh4 ty) cluster(ksh4)
		estadd local muni_fe "Yes"
		  
	eststo q_2 : ivreghdfe sh_marriage (CSOK_0000_POST = CSOK_`BW'_POST)  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"

	eststo q_3 : ivreghdfe sh_marriage (CSOK_0000_POST = CSOK_`BW'_POST)   [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  

		
		
	eststo q_4 :  ivreghdfe sh_marriage (CSOK_0000_POST = CSOK_`BW'_POST)  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post   $cc_3_post  ) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local county "Yes"	

	eststo q_5 :  ivreghdfe sh_marriage (CSOK_0000_POST = CSOK_`BW'_POST)   [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post  $cc_4_post ) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"	
		

	esttab
		
	#d ;
	esttab q* 	using "${output}/tab_marriage_IV_BW`BW'.rtf",  replace nocons 
		keep(CSOK_0000_POST ) coeflabel( CSOK_0000_POST "Rural CSOK \(\times\) Post" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		 nomtitles
		scalars("muni_fe  Municipality \& Year FE"
				"controls Controls"
				"region Region FE"
				"county County FE"
				"subregion Subregion FE"
				) 
		;
	#d cr	

}


*** PPML estimate -- it works, with specifying exp()
/*



foreach BW in /* "0000" 5000 */ 15000 {

	use "${temp}/settlement_level_002", clear

	keep if inrange(ty, 2014, .)
	keep if inrange(de01_2018, 0, 20000)
	keep if CSOK_`BW' != .  
	  
	  
	eststo clear
	eststo q_1 : ppmlhdfe N_marriage CSOK_`BW'_POST if  women_18_plus_TSTAR != 0 [fw = women_18_plus_TSTAR_2018] , absorb(ksh4 ty) cluster(ksh4) exposure(women_18_plus_TSTAR)
		estadd local muni_fe "Yes"

	eststo q_2 : ppmlhdfe N_marriage CSOK_`BW'_POST  if  women_18_plus_TSTAR != 0  [fw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4) exposure(women_18_plus_TSTAR)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"

	eststo q_3 : ppmlhdfe N_marriage CSOK_`BW'_POST  if  women_18_plus_TSTAR != 0  [fw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4) exposure(women_18_plus_TSTAR)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		
	eststo q_4 : ppmlhdfe N_marriage CSOK_`BW'_POST  if  women_18_plus_TSTAR != 0   [fw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_3_post ) cluster(ksh4) exposure(women_18_plus_TSTAR)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
			
	eststo q_5 : ppmlhdfe N_marriage CSOK_`BW'_POST  if  women_18_plus_TSTAR != 0   [fw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_4_post ) cluster(ksh4) exposure(women_18_plus_TSTAR)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		
	esttab

	
	
}



*** FIGURE
log using "${output}/OC_marriage.txt", replace text name(OC_marriage)

use "${temp}/settlement_level_002", clear


local controls_1 ""
local controls_2 " $cc_1_ty $cc_3_ty"
local controls_3 " $edu_ty "



local lower = 0
local upper = 20000

foreach BW in "0000"  5000 15000  {

	foreach CONTROLS in 1 2 3 {
		eststo q_`count' : reghdfe sh_marriage i.CSOK_`BW'##ib2014.ty   if inrange(ty, 2010, 2024)  & inrange(de01_2018, `lower', `upper') [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty `controls_`CONTROLS'' ) cluster(ksh4)

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
					note("Regressziós elemszám: `e(N)' ")
				;
		#d cr
		graph export "${output}/pretrend_marriage_BW`BW'_controls`CONTROLS'.pdf", as(pdf) replace 
		
		drop TIME b se hi lo
		
		local count = `count' + 1
	}
	
	
}


log close OC_marriage


/*------------------------------------------------------------------------------
	MARRIAGE - heterogeneity
		redcued form and OLS
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear
 
keep if inrange(ty, 2010, .)
 
local lower = 0
local upper = 20000

foreach BW in "0000" all {

	eststo clear

	eststo q_1 : reghdfe sh_marriage_kids0 CSOK_`BW'_POST if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
	eststo q_2 : reghdfe sh_marriage_kids1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_3 : reghdfe sh_marriage_age_15_39 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_4 : reghdfe sh_marriage_age_40_plus CSOK_`BW'_POST   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_5 : reghdfe sh_marriage_edu1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
	eststo q_6 : reghdfe sh_marriage_edu2 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_7 : reghdfe sh_marriage_edu3 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
		
	esttab	
		
	#d ;
	esttab q* 	using "${output}/tab_marriage_heterogeneity_OLS_BW`BW'.rtf",  replace nocons 
	keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
	;
	#d cr	
	
}


/*------------------------------------------------------------------------------
	MARRIAGE - heterogeneity
		IV
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear
  
keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000


eststo clear

eststo q_1 : ivreghdfe sh_marriage_kids0 (CSOK_0000_POST = CSOK_all_POST) if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_2 : ivreghdfe sh_marriage_kids1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_3 : ivreghdfe sh_marriage_age_15_39 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_4 : ivreghdfe sh_marriage_age_40_plus (CSOK_0000_POST = CSOK_all_POST)   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_5 : ivreghdfe sh_marriage_edu1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
eststo q_6 : ivreghdfe sh_marriage_edu2 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_7 : ivreghdfe sh_marriage_edu3 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
	
esttab	
	
#d ;
esttab q* 	using "${output}/tab_marriage_heterogeneity_IV_BW`BW'.rtf",  replace nocons 
	keep(CSOK_0000_POST  ) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
;
#d cr	
	






/*==============================================================================
	DIVORCE
==============================================================================*/



use "${temp}/settlement_level_002", clear

keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000
  
eststo clear
eststo q_1 : reghdfe sh_divorce CSOK_0000_POST if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018] , absorb(ksh4 ty) cluster(ksh4)
	estadd local muni_fe "Yes"
	  
eststo q_2 : reghdfe sh_divorce CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 : reghdfe sh_divorce CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"  

	
qui: 	reghdfe CSOK_0000_POST CSOK_all_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST] / _se[CSOK_all_POST])^2
		
	
eststo q_4 :  ivreghdfe sh_divorce (CSOK_0000_POST = i.CSOK_all##i.POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post   $cc_3_post  ) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'

	
qui: 	reghdfe RCSOK_per_women_POST CSOK_all_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST] / _se[CSOK_all_POST])^2
	
eststo q_5 :  ivreghdfe sh_divorce (RCSOK_per_women_POST = i.CSOK_all##i.POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post  $cc_3_post ) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'
	

esttab
	
	
	
	
	

*** FIGURE

log using "${output}/OC_divorce.txt", replace text name(OC_divorce)

use "${temp}/settlement_level_002", clear


local controls_1 ""
local controls_2 " $cc_1_ty $cc_3_ty"
local controls_3 " $edu_ty "



local lower = 0
local upper = 20000


foreach BW in "0000"  all  {

	foreach CONTROLS in 1 2 3 {
		reghdfe sh_divorce i.CSOK_`BW'##ib2014.ty   if inrange(ty, 2010, 2024)  & inrange(de01_2018, `lower', `upper') [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty `controls_`CONTROLS'' ) cluster(ksh4)

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
					note("Regressziós elemszám: `e(N)' ")
				;
		#d cr
		graph export "${output}/pretrend_divorce_BW`BW'_controls`CONTROLS'.pdf", as(pdf) replace 
		
		drop TIME b se hi lo
	}
}

log close OC_divorce


/*------------------------------------------------------------------------------
	DIVORCE - heterogeneity
		redcued form and OLS
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear
  
keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000

foreach BW in "0000" all {

	eststo clear

	eststo q_1 : reghdfe sh_divorce_kids0 CSOK_`BW'_POST if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_2 : reghdfe sh_divorce_kids1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_3 : reghdfe sh_divorce_age_15_39 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_4 : reghdfe sh_divorce_age_40_plus CSOK_`BW'_POST   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_5 : reghdfe sh_divorce_edu1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
	eststo q_6 : reghdfe sh_divorce_edu2 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_7 : reghdfe sh_divorce_edu3 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
		
	esttab	
		
	#d ;
	esttab q* 	using "${output}/tab_divorce_heterogeneity_OLS_BW`BW'.rtf",  replace nocons 
	keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
	;
	#d cr	
	
}


/*------------------------------------------------------------------------------
	DIVORCE - heterogeneity
		IV
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear

keep if inrange(ty, 2010, .)

 
local lower = 0
local upper = 20000


eststo clear

eststo q_1 : ivreghdfe sh_divorce_kids0 (CSOK_0000_POST = CSOK_all_POST) if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_2 : ivreghdfe sh_divorce_kids1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_3 : ivreghdfe sh_divorce_age_15_39 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_4 : ivreghdfe sh_divorce_age_40_plus (CSOK_0000_POST = CSOK_all_POST)   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_5 : ivreghdfe sh_divorce_edu1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
eststo q_6 : ivreghdfe sh_divorce_edu2 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_7 : ivreghdfe sh_divorce_edu3 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
	
esttab	
	
#d ;
esttab q* 	using "${output}/tab_divorce_heterogeneity_IV.rtf",  replace nocons 
	keep(CSOK_0000_POST  ) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
;
#d cr	
	






/*==============================================================================
	ABORTION
==============================================================================*/


global edu_post "c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST "
global edu_ty "c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty "


global cc_1_post " c.ln_income_2018##i.POST c.U_2018##i.POST " 
* c.ln_women_18_plus_TSTAR##i.POST " 
global cc_1_ty  " c.ln_income_2018##i.ty c.U##i.ty c.ln_women_18_plus_TSTAR##i.ty"
 /* c.ln_women_18_plus_2018##i.ty */
 
global cc_2_post "i.rkod##i.POST"
global cc_2_ty "i.rkod##i.ty"
 
global cc_3_post "i.mkod##i.POST"
global cc_3_ty "i.mkod##i.ty"
  
global cc_4_post "i.jaras##i.POST"
global cc_4_ty "i.jaras##i.ty"
  


use "${temp}/settlement_level_002", clear

keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000
  
eststo clear
eststo q_1 : reghdfe sh_abortion CSOK_0000_POST if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018] , absorb(ksh4 ty) cluster(ksh4)
	estadd local muni_fe "Yes"
	  
eststo q_2 : reghdfe sh_abortion CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"

eststo q_3 : reghdfe sh_abortion CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"  

	
qui: 	reghdfe CSOK_0000_POST CSOK_all_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST] / _se[CSOK_all_POST])^2
		
	
eststo q_4 :  ivreghdfe sh_abortion (CSOK_0000_POST = i.CSOK_all##i.POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post   $cc_3_post  ) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'

	
qui: 	reghdfe RCSOK_per_women_POST CSOK_all_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
local fstat = (_b[CSOK_all_POST] / _se[CSOK_all_POST])^2
	
eststo q_5 :  ivreghdfe sh_abortion (RCSOK_per_women_POST = i.CSOK_all##i.POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post  $cc_2_post ) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local region "Yes"	
	estadd scalar Fstat = `fstat'
	

esttab
	
#d ;
esttab q* 	using "${output}/tab_abortion.rtf",  replace nocons 
	keep(CSOK_0000_POST RCSOK_per_women_POST ) coeflabel( CSOK_0000_POST "Rural CSOK \(\times\) Post" RCSOK_per_women_POST "Subsidies per women \(\times\) Post")	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 mtitles("OLS" "OLS" "OLS" "IV" "IV")
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			"Fstat F-statistics"
			) 
	;
#d cr	




*** FIGURE

log using "${output}/OC_abortion.txt", replace text name(OC_abortion)

use "${temp}/settlement_level_002", clear


local controls_1 ""
local controls_2 " $cc_1_ty $cc_3_ty"
local controls_3 " $edu_ty "



local lower = 0
local upper = 20000


foreach BW in all /* "0000"  all */ {

	foreach CONTROLS in 1 2 3 {
		reghdfe sh_abortion i.CSOK_`BW'##ib2014.ty   if inrange(ty, 2010, 2024)  & inrange(de01_2018, `lower', `upper') [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty `controls_`CONTROLS'' ) cluster(ksh4)

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
					note("Regressziós elemszám: `e(N)' ")
				;
		#d cr
		graph export "${output}/pretrend_abortion_BW`BW'_controls`CONTROLS'.pdf", as(pdf) replace 
		
		drop TIME b se hi lo
	}
}

log close OC_abortion





/*------------------------------------------------------------------------------
	ABORTION - heterogeneity
		redcued form and OLS
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear
  
keep if inrange(ty, 2010, .)
  
local lower = 0
local upper = 20000

foreach BW in "0000" all {

	eststo clear

	eststo q_1 : reghdfe sh_abortion_kids0 CSOK_`BW'_POST if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_2 : reghdfe sh_abortion_kids1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_3 : reghdfe sh_abortion_age_15_39 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_4 : reghdfe sh_abortion_age_40_plus CSOK_`BW'_POST   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_5 : reghdfe sh_abortion_edu1 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
	eststo q_6 : reghdfe sh_abortion_edu2 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
	eststo q_7 : reghdfe sh_abortion_edu3 CSOK_`BW'_POST  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local subregion "Yes"
		
		
		
	esttab	
		
	#d ;
	esttab q* 	using "${output}/tab_abortion_heterogeneity_OLS_BW`BW'.rtf",  replace nocons 
	keep(CSOK_`BW'_POST  ) coeflabel( CSOK_`BW'_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
	;
	#d cr	
	
}


/*------------------------------------------------------------------------------
	ABORTION - heterogeneity
		IV
------------------------------------------------------------------------------*/

use "${temp}/settlement_level_002", clear

keep if inrange(ty, 2010, .)

 
local lower = 0
local upper = 20000


eststo clear

eststo q_1 : ivreghdfe sh_abortion_kids0 (CSOK_0000_POST = CSOK_all_POST) if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_2 : ivreghdfe sh_abortion_kids1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_3 : ivreghdfe sh_abortion_age_15_39 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_4 : ivreghdfe sh_abortion_age_40_plus (CSOK_0000_POST = CSOK_all_POST)   if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_5 : ivreghdfe sh_abortion_edu1 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
eststo q_6 : ivreghdfe sh_abortion_edu2 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
eststo q_7 : ivreghdfe sh_abortion_edu3 (CSOK_0000_POST = CSOK_all_POST)  if inrange(de01_2018, `lower', `upper')  [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $cc_1_post $cc_2_post) cluster(ksh4)
	estadd local muni_fe "Yes"
	estadd local controls "Yes"
	estadd local subregion "Yes"
	
	
	
esttab	
	
#d ;
esttab q* 	using "${output}/tab_abortion_heterogeneity_IV.rtf",  replace nocons 
	keep(CSOK_0000_POST  ) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post" )	
	 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
	 nomtitles
	scalars("muni_fe  Municipality \& Year FE"
			"controls Controls"
			"region Region FE"
			) 
;
#d cr	
	




/*==============================================================================
	MIGRATION
==============================================================================*/

global m_1_post "c.ln_income_2018##i.POST c.U_2018##i.POST c.SH_t_1##i.POST  c.SH_t_2##i.POST  c.SH_t_3##i.POST  c.SH_t_4##i.POST c.ln_de01_2018##i.POST"  /* c.ln_de01_2018##i.POST */ 

global m_1_ty "c.ln_income_2018##i.ty c.U_2018##i.ty c.SH_t_1##i.ty  c.SH_t_2##i.ty  c.SH_t_3##i.ty  c.SH_t_4##i.ty c.ln_de01_2018##i.ty"  /* c.ln_de01_2018##i.POST */ 
 


global m_2_post "i.rkod##i.POST"
global m_2_ty "i.rkod##i.ty"
 
global m_3_post "i.mkod##i.POST"
global m_3_ty "i.mkod##i.ty"
  
global m_4_post "i.jaras##i.POST"
global m_4_ty "i.jaras##i.ty"
  

use "${temp}/settlement_level_002", clear

keep if inrange(ty, 2010, .)





foreach FIXED_EFFECT in 2  3 4 5 /* 2 3 4 */   {

	local lower = 0
	local upper = 20000

	eststo clear

		
	eststo incl_1 : reghdfe q_INCL_mig_0000_in_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo incl_2 : reghdfe q_INCL_mig_0000_in_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo incl_3 : reghdfe q_INCL_mig_0000_out_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo incl_4 : reghdfe q_INCL_mig_0000_out_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  
		
	


	eststo excl_1 : reghdfe q_EXCL_mig_0000_in_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo excl_2 : reghdfe q_EXCL_mig_0000_in_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo excl_3 : reghdfe q_EXCL_mig_0000_out_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo excl_4 : reghdfe q_EXCL_mig_0000_out_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


		
		
	eststo women1549_1 : reghdfe q_women1549_mig_0000_in_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo women1549_2 : reghdfe q_women1549_mig_0000_in_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo women1549_3 : reghdfe q_women1549_mig_0000_out_0 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  


	eststo women1549_4 : reghdfe q_women1549_mig_0000_out_1 CSOK_0000_POST  if inrange(de01_2018, `lower', `upper')  [aw = de01_2018], absorb(ksh4 ty $m_1_post ${m_`FIXED_EFFECT'_post}) cluster(ksh4)
		estadd local muni_fe "Yes"
		estadd local controls "Yes"
		estadd local region "Yes"  

		
	#d ;
		esttab incl* using "${output}/tab_migration_FE`FIXED_EFFECT'.rtf"	, 
			replace nocons nomtitle
			keep(CSOK_0000_POST) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post")
			nonote obslast 
			star(+ 0.1 * 0.05 ** 0.01) se 
			scalars("time Mother \& Year FE"
			"mother Mother controls"
			"region_FE Region FE"
			"county_FE County FE"
			"subregion_FE Subregion FE"
			) 
			;
	#d cr
	
	
			
	#d ;
		esttab excl* using "${output}/tab_migration_FE`FIXED_EFFECT'.rtf"	, 
			append nocons nomtitle
			keep(CSOK_0000_POST) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post")
			nonote obslast 
			star(+ 0.1 * 0.05 ** 0.01) se 
			scalars("time Mother \& Year FE"
			"mother Mother controls"
			"region_FE Region FE"
			"county_FE County FE"
			"subregion_FE Subregion FE"
			) 
			;
	#d cr
		
	#d ;
		esttab women1549* using "${output}/tab_migration_FE`FIXED_EFFECT'.rtf"	, 
			append nocons nomtitle
			keep(CSOK_0000_POST) coeflabel(CSOK_0000_POST "Rural CSOK \(\times\) Post")
			nonote obslast 
			star(+ 0.1 * 0.05 ** 0.01) se 
			scalars("time Mother \& Year FE"
			"mother Mother controls"
			"region_FE Region FE"
			"county_FE County FE"
			"subregion_FE Subregion FE"
			) 
			;
	#d cr
}




*** FIGURE

log using "${output}/OC_migration.txt", replace text name(OC_migration)

use "${temp}/settlement_level_002", clear

drop if ty == 2022


local lower = 0
local upper = 20000


foreach BW in all /* "0000"  all */ {

	foreach FIXED_EFFECT in 2  3 4 5 /* 2 3 4 */   {
		
		foreach OUTCOME in q_EXCL_mig_0000_in_0 q_EXCL_mig_0000_in_1 q_EXCL_mig_0000_out_0 q_EXCL_mig_0000_out_1   q_INCL_mig_0000_in_0 q_INCL_mig_0000_in_1 q_INCL_mig_0000_out_0 q_INCL_mig_0000_out_1  {
			
			reghdfe `OUTCOME'  i.CSOK_`BW'##ib2014.ty   if inrange(ty, 2010, 2024)  & inrange(de01_2018, `lower', `upper') [aw = women_18_plus_TSTAR_2018], absorb(ksh4 ty $m_1_ty ${m_`FIXED_EFFECT'_ty} ) cluster(ksh4)

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
						note("Regressziós elemszám: `e(N)' ")
					;
			#d cr
			graph export "${output}/pretrend_migration_`OUTCOME'_BW`BW'FE`FIXED_EFFECT'.pdf", as(pdf) replace 
			
			drop TIME b se hi lo
		}
	}
}

log close OC_migration


