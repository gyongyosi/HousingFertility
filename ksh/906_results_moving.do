
** within movers
use "${temp}/internal_migration_02", clear

keep if nem == 2
*keep if csal == 2
keep if inrange(korev, 15, 49)
keep if allp == 1

keep if in_ksh4_bpker == out_ksh4_bpker

gen mover_sameSett = 1
collapse (sum) mover_sameSett , by(ty out_ksh4_bpker)
ren out_ksh4_bpker ksh4_bpker
tempfile mover_sameSett
save `mover_sameSett'


** across movers
use "${temp}/internal_migration_02", clear

keep if nem == 2
*keep if csal == 2
keep if inrange(korev, 15, 49)
keep if allp == 1

keep if in_ksh4_bpker != out_ksh4_bpker

gen mover_newSett = 1
collapse (sum) mover_newSett , by(ty out_ksh4_bpker)
ren out_ksh4_bpker ksh4_bpker
tempfile mover_newSett
save `mover_newSett'



** by elig status
use "${temp}/internal_migration_02", clear

keep if nem == 2
*keep if csal == 2
keep if inrange(korev, 15, 49)
keep if allp == 1

* identify moving related to CSOK 5000 cutoff
gen mover_withinITT = ( in_CSOK_all==1 & out_CSOK_all==1)
gen mover_intoITT = ( in_CSOK_all==1 & out_CSOK_all==0)
gen mover_withoutITT = ( in_CSOK_all==0 & out_CSOK_all==0)
gen mover_outofITT = ( in_CSOK_all==0 & out_CSOK_all==1)
* identify moving related to CSOK actual eligibility
gen mover_withinTOT = ( in_CSOK_0000_all==1 & out_CSOK_0000_all==1)
gen mover_intoTOT = ( in_CSOK_0000_all==1 & out_CSOK_0000_all==0)
gen mover_withoutTOT = ( in_CSOK_0000_all==0 & out_CSOK_0000_all==0)
gen mover_outofTOT = ( in_CSOK_0000_all==0 & out_CSOK_0000_all==1)

collapse (sum) mover* , by(ty out_ksh4_bpker)

gen M_in_ITT = mover_withinITT + mover_intoITT
gen M_out_ITT = mover_withoutITT + mover_outofITT
gen M_in_TOT = mover_withinTOT + mover_intoTOT
gen M_out_TOT = mover_withoutTOT + mover_outofTOT


ren out_ksh4_bpker ksh4_bpker

tempfile mover_by_elig
save `mover_by_elig'




use "${temp}/tstar_important", clear


merge 1:1 ksh4_bpker ty using `mover_sameSett', nogen keep(1 3)
merge 1:1 ksh4_bpker ty using `mover_newSett', nogen keep(1 3)
merge 1:1 ksh4_bpker ty using `mover_by_elig', nogen keep(1 3)

xtset ksh4_bpker ty
foreach X of varlist mover* M_in* M_out* {
	replace `X' = 0 if `X' == .
	gen sh_`X' = `X' / l.women_15_49
	winsor2 sh_`X', suffix(_W) cuts(1 99) by(ty)
}


keep if inrange(ty, 2014, .)
drop if ty == 2022

gen POST = (ty > 2019)
gen tmp_women_15_49_2018 = women_15_49 if ty == 2018
egen women_15_49_2018 = mean(tmp_women_15_49_2018), by(ksh4_bpker)
drop tmp_women_15_49

gen ln_de01_2018 = ln(de01_2018)
gen de01_2018_recentered = de01_2018 - 5000


aaa


*** within settlement moving
eststo clear
eststo q_1 : reghdfe sh_mover_sameSett_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo q_2 : reghdfe sh_mover_sameSett_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.POST c.ln_income_2018_bin5##i.POST  c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST  i.jaras175##i.POST) cluster(ksh4) 




eststo d_1 : reghdfe sh_mover_sameSett_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo d_2 : reghdfe sh_mover_sameSett_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty  c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty  i.jaras175##i.ty) cluster(ksh4) 






*** across settlement moving
eststo clear
eststo q_1 : reghdfe sh_mover_newSett_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo q_2 : reghdfe sh_mover_newSett_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.POST c.ln_income_2018_bin5##i.POST c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST  i.jaras175##i.POST) cluster(ksh4) 




eststo d_1 : reghdfe sh_mover_newSett_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo d_2 : reghdfe sh_mover_newSett_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty   i.jaras175##i.ty ) cluster(ksh4) 




** moving by elig status - sh_M_out_ITT_W
eststo clear
eststo q_1 : reghdfe sh_M_out_ITT_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo q_2 : reghdfe sh_M_out_ITT_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.POST c.ln_income_2018_bin5##i.POST c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST i.jaras175##i.POST) cluster(ksh4) 



eststo d_1 : reghdfe sh_M_out_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo d_2 : reghdfe sh_M_out_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty ) cluster(ksh4) 

eststo d_3 : reghdfe sh_M_out_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty i.jaras175##i.ty) cluster(ksh4) 






** moving by elig status - sh_M_in_ITT
eststo clear
eststo q_1 : reghdfe sh_M_in_ITT_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo q_2 : reghdfe sh_M_in_ITT_W i.CSOK_15000##i.POST    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.POST c.ln_income_2018_bin5##i.POST c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST i.jaras175##i.POST) cluster(ksh4) 



eststo d_1 : reghdfe sh_M_in_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty ) cluster(ksh4) 

eststo d_2 : reghdfe sh_M_in_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty ) cluster(ksh4) 

eststo d_3 : reghdfe sh_M_in_ITT_W i.CSOK_15000##ib2019.ty    [aw = women_15_49_2018], absorb(ksh4 ty i.U_2018_bin5##i.ty c.ln_income_2018_bin5##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty i.jaras175##i.ty) cluster(ksh4) 






/*------------------------------------------------------------------------------
	individual moving from census
------------------------------------------------------------------------------*/


use "${temp}/census_002_unbal_filled", clear

keep if ty == 2019


gen M_in = mover_withinITT + mover_intoITT
gen M_out = mover_withoutITT + mover_outofITT



foreach BW in   15000 /* 5000 0000_all all*/  {

	eststo clear
	eststo q_1 : reghdfe mover P_CSOK_`BW', absorb() vce("cluster P_ksh4") 

	eststo q_2 : reghdfe mover P_CSOK_`BW', absorb( $x1) vce("cluster P_ksh4") 
		estadd local controls "Yes"

	eststo q_3 : reghdfe mover $x2 P_CSOK_`BW', absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		
		estadd local jaras "Yes"
		
	eststo q_4 : reghdfe mover_sameSett $x2 P_CSOK_`BW', absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"
		
	eststo q_5 : reghdfe mover_newSett $x2 P_CSOK_`BW', absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"

	eststo q_6 : reghdfe M_in $x2 P_CSOK_`BW', absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"
		
	eststo q_7 : reghdfe M_out $x2 P_CSOK_`BW', absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"

	esttab
	
	#d ;
	esttab q* 	using "${output}/tab_moving_individual_BW`BW'.rtf",  replace nocons nomtitle
		keep(P_CSOK_`BW' ) coeflabel( P_CSOK_`BW' "Rural CSOK eligible" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars(
				"controls Individual controls"
				"muni_controls Municipality controls"
				"jaras Microregion FE"
				) 
		mgroups( "All moving" "Moving within muni" "Moving across muni" "Moving into eligible" "Moving into non-eligible" )
		;
	#d cr
}





/*------------------------------------------------------------------------------
	individual moving from census
		heterogeneity
------------------------------------------------------------------------------*/



use "${temp}/census_002_unbal_filled", clear

keep if ty == 2019


gen M_in = mover_withinITT + mover_intoITT
gen M_out = mover_withoutITT + mover_outofITT



foreach BW in   15000 /* 0000_all all */ {

	eststo clear

	* by married2019
	eststo q_1 : reghdfe mover P_CSOK_`BW'  $x2 if marriedBy2019 == 0, absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_2 : reghdfe mover P_CSOK_`BW' $x2  if marriedBy2019 == 1, absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"

	* by kids2019
	eststo q_3 : reghdfe mover P_CSOK_`BW'  $x2 if kidsBy2019 == 0, absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_4 : reghdfe mover P_CSOK_`BW'  $x2 if inrange(kidsBy2019, 1, 10) ,  absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
		
	* by cohort
	eststo q_5 : reghdfe mover P_CSOK_`BW'  $x2 if inrange(cohort5, 4, 6) == 0, absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_6 : reghdfe mover P_CSOK_`BW'  $x2 if inrange(cohort5, 7, 9) ,  absorb($x1  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"

	esttab

		#d ;
		esttab q* 	using "${output}/tab_moving_individual_BW`BW'_hetero.rtf",  replace nocons nomtitle
			keep(P_CSOK_`BW' ) coeflabel( P_CSOK_`BW' "Rural CSOK eligible" )	
			 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
			scalars(
					"controls Controls"
					"jaras Microregion FE"
					) 
			mgroups( "Married in 2019" "Have kids in 2019" "Age" )
			;
		#d cr
}




/*------------------------------------------------------------------------------
	individual moving from microcensus
------------------------------------------------------------------------------*/


use "${temp}/microcensus_002_unbal", clear

keep if ty == 2013

gen M_in = mover_withinITT + mover_intoITT
gen M_out = mover_withoutITT + mover_outofITT



foreach BW in   15000 5000 0000_all all  {

	eststo clear
	eststo q_1 : reghdfe mover P_CSOK_`BW', absorb() vce("cluster P_ksh4") 

	eststo q_2 : reghdfe mover P_CSOK_`BW', absorb( $x1_microcensus) vce("cluster P_ksh4") 
		estadd local controls "Yes"

	eststo q_3 : reghdfe mover $x2_microcensus P_CSOK_`BW', absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		
		estadd local jaras "Yes"
		
	eststo q_4 : reghdfe mover_sameSett $x2_microcensus P_CSOK_`BW', absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"
		
	eststo q_5 : reghdfe mover_newSett $x2_microcensus P_CSOK_`BW', absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"

	eststo q_6 : reghdfe M_in $x2_microcensus P_CSOK_`BW', absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"
		
	eststo q_7 : reghdfe M_out $x2_microcensus P_CSOK_`BW', absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local muni_controls "Yes"
		estadd local jaras "Yes"

	esttab

	
	#d ;
	esttab q* 	using "${output}/tab_moving_individual_BW`BW'_microcensus.rtf",  replace nocons nomtitle
		keep(P_CSOK_`BW' ) coeflabel( P_CSOK_`BW' "Rural CSOK eligible" )	
		 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
		scalars(
				"controls Individual controls"
				"muni_controls Municipality controls"
				"jaras Microregion FE"
				) 
		mgroups( "All moving" "Moving within muni" "Moving across muni" "Moving into eligible" "Moving into non-eligible" )
		;
	#d cr
}



/*------------------------------------------------------------------------------
	individual moving from microcensus
		heterogeneity
------------------------------------------------------------------------------*/



use "${temp}/microcensus_002_unbal", clear

keep if ty == 2013


gen M_in = mover_withinITT + mover_intoITT
gen M_out = mover_withoutITT + mover_outofITT



foreach BW in   15000 /* 0000_all all */ {

	eststo clear

	* by married2019
	eststo q_1 : reghdfe mover P_CSOK_`BW' $x2_microcensus if marriedBy2013 == 0, absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_2 : reghdfe mover P_CSOK_`BW' $x2_microcensus if marriedBy2013 == 1, absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"

	* by kids2019
	eststo q_3 : reghdfe mover P_CSOK_`BW' $x2_microcensus if kidsBy2013 == 0, absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_4 : reghdfe mover P_CSOK_`BW' $x2_microcensus if inrange(kidsBy2013, 1, 15) ,  absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
		
	* by cohort
	eststo q_5 : reghdfe mover P_CSOK_`BW' $x2_microcensus if inrange(cohort5, 1956, 1971) == 0, absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"
	eststo q_6 : reghdfe mover P_CSOK_`BW' $x2_microcensus if inrange(cohort5, 1976, 1996) ,  absorb($x1_microcensus  P_jaras175) vce("cluster P_ksh4") 
		estadd local controls "Yes"
		estadd local jaras "Yes"

	esttab

		#d ;
		esttab q* 	using "${output}/tab_moving_individual_BW`BW'_hetero.rtf",  replace nocons nomtitle
			keep(P_CSOK_`BW' ) coeflabel( P_CSOK_`BW' "Rural CSOK eligible" )	
			 nonote obslast  star(+ 0.1 * 0.05 ** 0.01) se 
			scalars(
					"controls Controls"
					"jaras Microregion FE"
					) 
			mgroups( "Married in 2019" "Have kids in 2019" "Age" )
			;
		#d cr
}


/*------------------------------------------------------------------------------
	grav
------------------------------------------------------------------------------*/


foreach DIRECTION in in out {

	use "${temp}/tstar_important", clear
	keep if ty ==  2018
	keep ksh4 CSOK_all CSOK_15000 SH_t_1 SH_t_2 SH_t_3 SH_t_4 U_2018 ln_income_2018
	duplicates drop ksh4, force
	foreach X of varlist * {
		ren `X' `DIRECTION'_`X'
	}
	
	tempfile `DIRECTION'_tstar
	save ``DIRECTION'_tstar'

}


use ${tel_to_tel_dist}/tel_to_tel, clear
ren telkod4_1 in_ksh4_bpker
ren telkod4_2 out_ksh4_bpker
keep in* out* kozut*
tempfile distance
save `distance'


use "${temp}/internal_migration_02", clear

gen M_all = 1
gen M_f1549 = 1 if (nem == 2 & inrange(korev, 15, 49))
gen M_f1549_married = 1 if (nem == 2 & inrange(korev, 15, 49) & csal == 2)

collapse (sum) M_*, by(in_ksh4_bpker out_ksh4_bpker ty)
tempfile flows
save `flows'



clear
set obs 3000
gen ty = _n
keep if inrange(ty, 2014, 2024)
tempfile time
save `time'

foreach DIRECTION in in out {
	use "${temp}/internal_migration_02", clear
	keep `DIRECTION'_ksh4_bpker 
	duplicates drop `DIRECTION'_ksh4_bpker, force
	gen `DIRECTION'_ksh4 = `DIRECTION'_ksh4_bpker
	foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
		replace `DIRECTION'_ksh4 = 1357 if `DIRECTION'_ksh4_bpker == `Y'
	}
	tempfile `DIRECTION'
	save ``DIRECTION''
}
 

use `in', clear
cross using `out'
cross using `time'

merge m:1 in_ksh4_bpker out_ksh4_bpker using `distance', nogen keep(1 3)
merge 1:1 in_ksh4_bpker out_ksh4_bpker ty using `flows', nogen keep(1 3)

foreach X of varlist M_* {
	replace `X' = 0 if `X' == .
}

merge m:1 in_ksh4 using `in_tstar', nogen keep(1 3)
merge m:1 out_ksh4 using `out_tstar', nogen keep(1 3)

compress
save "${temp}/moving_flows_01", replace









use "${temp}/moving_flows_01", clear

gen POST = (ty > 2019)

gen ln_dist = ln(kozutmeter)


eststo clear

eststo q_1 : ppmlhdfe M_f1549 ln_dist i.in_CSOK_15000##i.POST, absorb(in_ksh4_bpker  ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo q_2 : ppmlhdfe M_f1549 ln_dist i.in_CSOK_15000##i.POST, absorb(in_ksh4_bpker i.out_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo q_3 : ppmlhdfe M_f1549  i.in_CSOK_15000##i.POST, absorb(in_ksh4_bpker#out_ksh4_bpker i.out_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)



eststo m_1 : ppmlhdfe M_f1549 ln_dist i.out_CSOK_15000##i.POST, absorb(out_ksh4_bpker  ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo m_2 : ppmlhdfe M_f1549 ln_dist i.out_CSOK_15000##i.POST, absorb(out_ksh4_bpker i.in_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo m_3 : ppmlhdfe M_f1549  i.out_CSOK_15000##i.POST, absorb(out_ksh4_bpker#in_ksh4_bpker i.in_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)




eststo qd_1 : ppmlhdfe M_f1549 ln_dist i.in_CSOK_15000##ib2018.ty, absorb(in_ksh4_bpker  ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo qd_2 : ppmlhdfe M_f1549 ln_dist i.in_CSOK_15000##ib2018.ty, absorb(in_ksh4_bpker i.out_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo qd_3 : ppmlhdfe M_f1549  i.in_CSOK_15000##ib2018.ty, absorb(in_ksh4_bpker#out_ksh4_bpker i.out_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)


eststo md_1 : ppmlhdfe M_f1549 ln_dist i.out_CSOK_15000##ib2018.ty, absorb(out_ksh4_bpker  ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo md_2 : ppmlhdfe M_f1549 ln_dist i.out_CSOK_15000##ib2018.ty, absorb(out_ksh4_bpker i.in_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)

eststo md_3 : ppmlhdfe M_f1549  i.out_CSOK_15000##ib2018.ty, absorb(out_ksh4_bpker#in_ksh4_bpker i.in_ksh4_bpker#i.ty ty) cluster(in_ksh4_bpker out_ksh4_bpker)


esttab q_* m_* using "${output}/tab_moving_admin_static.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g) 

esttab qd_* md_* using "${output}/tab_moving_admin_dynamic.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g) 











ppmlhdfe M_f1549_marr i.out_CSOK_15000##i.POST, absorb(i.in_ksh4_bpker#i.out_ksh4_bpker ty)



