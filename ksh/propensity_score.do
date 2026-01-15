


/*------------------------------------------------------------------------------
	Appendix Tab A4
	Appendix Tab A5
	Appendix Tab A6

	propensity score matching
------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------*/
* 1) create the matched sample

/*
global more_control "unexpected_01"
global more_control ""
*/

foreach TYPE in A B {   /* how we treat Nodebt HHs, control group vs dropped  */ 
	foreach caliper in 10 5 1 {
		forval WAVE = 2005(1)2012 { 
		
			use ${temp}/hkf_cd01, clear
			
			keep if WAVE == `WAVE'
			keep if N == 1
			
			local CALIPER = `caliper' / 1000
			
			cap drop TREATMENT
			gen TREATMENT = .
			replace TREATMENT = 1 if FCDebt == 1
			replace TREATMENT = 0 if FCDebt == 0 & NoDebt == 0
			if "`TYPE'" == "B" {
				replace TREATMENT = 0 if NoDebt == 1
			}
			
			* keep obs where distance is small
			cap teffects psmatch (c2_w3_pc2) (TREATMENT $x1 $x3 $more_control) , vce(robust) caliper(`CALIPER') osample(OSAMPLE)
			keep if OSAMPLE == 0
			
			* determine TREATMENT-CONTROL matches
			cap teffects psmatch (c2_w3_pc2) (TREATMENT $x1 $x3 $more_control) , vce(robust)  gen(match)
			gen ob = _n
			tempfile fulldata
			save `fulldata'
			
			keep if TREATMENT == 1 /* keep treated */
			keep match1  /* keep the observation number of matched control observation */
			bysort match : gen WEIGHT_`caliper' = _N  /* count how many times each control observation serves as control */
			by match: keep if _n == 1  /* keep just one row per control observation */
			ren match ob
			
			merge 1:m ob using `fulldata'
			replace WEIGHT = 1 if TREATMENT == 1  /* replace weight to 1 for treated */
			gen WW_`caliper' = weight * WEIGHT  /* create the proper weight: some controls serve as control multiple times; take this into account */
			
			ren TREATMENT TREATMENT_`caliper'
			keep sorsz TREATMENT_`caliper' WEIGHT_`caliper' WW_`caliper'
			save ${temp}/psmatch_`caliper'_`TYPE'_`WAVE' , replace

		}
		
		clear
		forval WAVE = 2005(1)2012 {
			append using ${temp}/psmatch_`caliper'_`TYPE'_`WAVE'
		}
		foreach X of varlist * {
			ren `X' `X'_`TYPE'
		}
		ren sorsz_ sorsz
		save ${temp}/psmatch_`caliper'_`TYPE' , replace
	}
}



/*----------------------------------------------------------------------------*/
* 2) estimate the effect




foreach  caliper in 1 5 10 {

	use ${temp}/hkf_cd01, clear

	merge m:1 sorsz using ${temp}/psmatch_`caliper'_A, nogen keep(1 3)
	merge m:1 sorsz using ${temp}/psmatch_`caliper'_B, nogen keep(1 3)

	eststo clear
	gen TREATMENT = .
	gen WW = .
	replace TREATMENT = TREATMENT_`caliper'_A
	replace WW = WW_`caliper'_A 

	eststo q_1 : ppmlhdfe c2_w3_pc2 i.TREATMENT##i.POST [pw = WW], absorb(sorsz ty) cluster(sorsz)
		estadd local hhtimeFE "Yes"
	eststo q_2 : ppmlhdfe c2_w3_pc2 $x1_post i.TREATMENT##i.POST [pw = WW], absorb(sorsz ty $x3_post) cluster(sorsz)
		estadd local hhtimeFE "Yes"
		estadd local ind_cont "Yes"	
		
	replace TREATMENT = TREATMENT_`caliper'_B	
	replace WW = WW_`caliper'_B
	eststo q_3 : ppmlhdfe c2_w3_pc2 i.TREATMENT##i.POST [pw = WW], absorb(sorsz ty) cluster(sorsz)
		estadd local hhtimeFE "Yes"
	eststo q_4 : ppmlhdfe c2_w3_pc2 $x1_post i.TREATMENT##i.POST [pw = WW], absorb(sorsz ty $x3_post) cluster(sorsz)
		estadd local hhtimeFE "Yes"
		estadd local ind_cont "Yes"


		esttab, keep(1.TREATMENT#1.POST  ) coeflabel( 1.TREATMENT#1.POST "\(Treated \times Post\)")
		
	#d ;
	esttab q* 	using ${output}/tab_pscore_`caliper'.tex, booktabs replace nocons nomtitle
		keep(1.TREATMENT#1.POST  ) coeflabel( 1.TREATMENT#1.POST "FC \(\times\) Post")	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars("hhtimeFE Household \& Year FE"
				"ind_cont Household controls"
				) 
		mgroups("LC control" "LC \& NoDebt control" , pattern(1 0 1 0  ) prefix(\multicolumn{@span}{c}{)suffix(}) span erepeat(\cmidrule(lr){@span}))
		;
	#d cr

}


	
/*----------------------------------------------------------------------------*/
* 3) create balance tables



foreach  caliper in 1 5 10 {

	foreach TYPE in A B {

		use ${temp}/hkf_cd01, clear

		merge m:1 sorsz using ${temp}/psmatch_`caliper'_A, nogen keep(1 3)
		merge m:1 sorsz using ${temp}/psmatch_`caliper'_B, nogen keep(1 3)

		eststo clear
		gen TREATMENT = .
		gen WW = .
		replace TREATMENT = TREATMENT_`caliper'_`TYPE'
		replace WW = WW_`caliper'_`TYPE' 


		gen c2_i = c2_w0_pc0 / income_w0
		winsor2 c2_i, cuts(0 99.0) by(ty) suffix(_w)
		winsor2 c2_i, cuts(0 97.5) by(ty) suffix(2_w)

		gen P_i = P_2008_09 / ( income_w0 / 12)
		replace P_i = 0 if FC_o == 0
		winsor2 P_i, cuts(0 99.0) by(ty) suffix(_w)

		gen food_i = evf01 / income_w0_pc0
		winsor2 food_i, cuts(0 99.0) by(ty) suffix(_w)

		replace income_w3_pc1 = income_w3_pc1 / 1000
		replace income_w3_pc2 = income_w3_pc2 / 1000

		gen FC_2group = - FC_old /* for to replace the ordering */
		replace FC_2group = . if FC_old == 0

		gen b_nb = FC_old
		replace b_nb = 1 if FC_old == 2
		replace b_nb = - b_nb

		tab HHeduc, gen(HHeduc_)
		tab d2, gen(d2_)

		lab var HHeduc_1 "Primary school"
		lab var HHeduc_2 "Vocational school"
		lab var HHeduc_3 "High school"
		lab var HHeduc_4 "College"
		lab var d2_1 "Capital"
		lab var d2_2 "County capital"
		lab var d2_3 "Town"
		lab var d2_4 "Village"
		lab var HHsize "Household size"
		lab var unexpected "Have liquid assets"

		lab var HHsex "Female"
		lab var HHage "Age"
		lab var income_w3_pc2 "Income (1000 HUF)"
		lab var c2_i_w "Consumption to income"
		lab var P_i_w "Payment to income"
		lab var food_i_w "Food exp. to income"
		lab var high_liq "Have liquid assets"

		
		gen VAR = ""
		gen TREATED = .
		gen CONTROL = .
		gen DIFF = .
		gen TSTAT = .
		gen STANDARD_DIFF = .

		local j = 1
		forval i=2008(1)2008 {

			foreach  VARLIST in HHeduc_1 HHeduc_2 HHeduc_3 HHeduc_4 HHsize HHage HHsex income_w3_pc2 c2_i_w food_i_w P_i_w high_liq d2_1 d2_2 d2_3 d2_4 {


				if "`VARLIST'" == "P_i_w" {
					if "`TYPE'" == "B" {
						continue
					}
					
				}
			
				reg `VARLIST' TREATMENT if ty == `i' [aw = WW], r
				local tstat = _b[TREATMENT] / _se[TREATMENT]
				
				dis in red "TREATED"
				sum `VARLIST' if TREATMENT == 1 & ty == `i' [aw = WW]
				local mean_treated = r(mean)
				local sd_treated = r(sd)
				
				dis in red "CONTROL"
				sum `VARLIST' if TREATMENT == 0 & ty == `i' [aw = WW]
				local mean_control = r(mean)
				local sd_control = r(sd)
				
				local standard_diff = (`mean_treated' - `mean_control') / sqrt((`sd_treated')^2 + (`sd_control')^2)
				
				local label : variable label `VARLIST'
				
				replace VAR = "`label'" in `j'
				replace TREATED = `mean_treated' in `j'
				replace CONTROL = `mean_control' in `j'
				replace DIFF = `mean_treated' - `mean_control' in `j'
				replace TSTAT = `tstat' in `j'
				replace STANDARD_DIFF = `standard_diff' in `j'
				
				local j = `j' + 1
			}
				
			keep VAR TREATED CONTROL DIFF TSTAT STANDARD_DIFF
			keep if VAR != ""
			
			foreach X of varlist TREATED CONTROL DIFF TSTAT STANDARD_DIFF {
				format `X' %9.2fc
			}
			
			tostring DIFF, gen(DIFF_2) format(%9.2fc) force
			drop DIFF
			ren DIFF_2 DIFF
			replace DIFF = DIFF + "+" if abs(TSTAT) >= 1.645 & abs(TSTAT)< 1.96
			replace DIFF = DIFF + "*" if abs(TSTAT) >= 1.96 & abs(TSTAT)< 2.58
			replace DIFF = DIFF + "**" if abs(TSTAT) >= 2.58
			
			
			
			lab var TREATED "Treatment"
			lab var CONTROL "Control"
			lab var DIFF "Treatment-Control Diff."
			lab var TSTAT "t-statistic"
			lab var STANDARD_DIFF "Normalized Diff."
			
			texsave_begintable using ${output}/tab_balance_psmatch_`i'_calip`caliper'_type`TYPE'.tex, replace varlabels frag nofix
			*texsave using ${output}/tab_balance_psmatch_`i'_calip`caliper'_type`TYPE'.tex, replace varlabels frag nofix
				
		}
	}
	
}

