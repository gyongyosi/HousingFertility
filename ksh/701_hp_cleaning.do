






/*------------------------------------------------------------------------------
	compare number of transactions to offical statistics
------------------------------------------------------------------------------*/

use "${hp_aggr}/ksh_price_levels", clear

keep if region == "Ország"
keep if inlist(settlement_type, "főváros", "községek", "vármegyeszékhely", "városok")

destring period, replace
ren period ty


collapse (sum) transactions, by(ty)
line tr ty
tempfile aggr_tr
save `aggr_tr'


use "${hp}/KRTK_adatvéd.dta", clear

gen tr = 1
gen ty = adev + 2000

collapse (sum) tr, by(ty)

merge 1:1 ty using `aggr_tr', nogen 

line tr tran ty

gen diff = tran-tr
line diff ty



/*------------------------------------------------------------------------------
	count the number of dropped observations
------------------------------------------------------------------------------*/


use "${hp}/KRTK_adatvéd", clear

ren adev ty

destring ar, replace
replace lat = subinstr(lat, ",", ".", 1)
destring lat, replace

replace latt = subinstr(latt, ",", ".", 1)
destring latt, replace

gen dropped = 0
replace dropped = 1 if (ar == . & latt == .)

gen missing_ar = (ar == .)
gen missing_latt = (latt == .)

collapse (sum) dropped missing_*, by(ty)
line dropped missing* ty



use "${hp}/KRTK_adatvéd", clear

ren adev ty

destring ar, replace
replace lat = subinstr(lat, ",", ".", 1)
destring lat, replace

replace latt = subinstr(latt, ",", ".", 1)
destring latt, replace

gen dropped = 0
replace dropped = 1 if (ar == . & latt == .)

gen missing_ar = (ar == .)
gen missing_latt = (latt == .)

tab n_break dropped,m


collapse (sum) dropped missing_*, by(ty település)
sum dropped




/*------------------------------------------------------------------------------
	data cleaning
------------------------------------------------------------------------------*/


use "${temp}/tstar_important", clear
keep if ty == 2018
duplicates drop ksh4, force
tempfile tstar
save `tstar'


use "${hp}/KRTK_adatvéd", clear

destring ar, replace
replace lat = subinstr(lat, ",", ".", 1)
destring lat, replace

replace latt = subinstr(latt, ",", ".", 1)
destring latt, replace


gen ksh4_bpker = int(telaz5 / 10)
gen ksh4 = ksh4_bpker
foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}
drop telaz

gen ty = adev + 2000
drop adev

ren ar  price
ren lat  size
ren latt size_imputed
gen ln_price = ln(price)

gen size_cat = .
gen size_cat_imputed = .

forval i = 20(5)250 {
	
	local j = `i' + 4.999
	replace size_cat = `i' if inrange(size, `i', `j')
	replace size_cat_imputed = `i' if inrange(size_imputed, `i', `j')
}





lab var price "House price"
lab var ln_price "Log house price"
lab var size "Size (square meter)"


foreach X of varlist irsz telep {
	cap drop `X'
}


merge m:1 ksh4 using `tstar', nogen keep(1 3) keepusing(CSOK_* SH_t_1 SH_t_2 SH_t_3 SH_t_4 de01_2018 U_2018 ln_income_2018 jaras175 mkod2018 rkod2018 subsidy_1_2016_2023 subsidy_2_2016_2023 subsidy_4_2016_2023 subsidy_3_2019_2023 women_15_39)


gen POST = (ty>2018)

order ksh4* ty
save "${temp}/hp_001", replace




/*------------------------------------------------------------------------------
	descriptives
------------------------------------------------------------------------------*/



use "${temp}/hp_001", clear



forval YEAR = 2010(1)2024 {
		#d ;
			hist size if ty == `YEAR' & inrange(size, 0, 100), 
				disc
			;
		#d cr
		graph export "${output}/hist_hp_size_`YEAR'.pdf", as(pdf) replace
}

forval YEAR = 2010(1)2024 {
		#d ;
			binscatter ln_price size if ty == `YEAR' , nq(100)
				
			;
		#d cr
		graph export "${output}/binscatter_hp_lnprice_size_`YEAR'.pdf", as(pdf) replace
}



gen p_per_size = price / size_imputed
hist p_per_size if ty == 2014
binscatter p_per_size size if ty == 2014, nq(100) controls(SH_t*) absorb(rkod)



binscatter p_per_size size if ty == 2013, nq(100) controls(SH_t*)


binscatter p_per_size size if ty == 2018, nq(100) controls(SH_t*)

binscatter p_per_size size if ty == 2017, nq(100) controls(SH_t*) absorb(rkod)


binscatter p_per_size size if ty == 2017 & CSOK_15000 != ., nq(100) controls(SH_t*) absorb(rkod)

binscatter p_per_size size if ty == 2014 & CSOK_15000 != ., nq(100) controls(SH_t*) absorb(rkod)



use "${temp}/hp_001", clear

keep if inrange(ty, 2013, .)


eststo clear

reghdfe ln_price size ib0.CSOK_15000##ib2018.ty, absorb(ksh4 ty) cluster(ksh4)

reghdfe ln_price size ib0.CSOK_15000##ib0.POST if inrange(ty, 2012, .) , absorb(ksh4 ty) cluster(ksh4)

reghdfe ln_price  ib0.CSOK_15000##ib0.POST if inrange(ty, 2012, .) , absorb(ksh4 ty c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST) cluster(ksh4)

ppmlhdfe price  ib0.CSOK_15000##ib0.POST if inrange(ty, 2012, .) , absorb(ksh4 ty c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST) cluster(ksh4)



reghdfe p_per_size size ib0.CSOK_15000##ib0.POST if inrange(ty, 2012, .) & out == 1, absorb(ksh4 ty c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST i.jaras175##i.POST) cluster(ksh4)



reghdfe ln_price size ib0.CSOK_15000##ib0.POST if inrange(ty, 2012, .) , absorb(ksh4 ty i.jaras175##i.POST) cluster(ksh4)





reghdfe ln_price size ib0.CSOK_0000_all##ib0.POST if CSOK_15000 != . & inrange(ty, 2012, .) & out == 1, absorb(ksh4 ty  i.ksh4#c.ty c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST ) cluster(ksh4)




/*------------------------------------------------------------------------------
	descriptives
------------------------------------------------------------------------------*/

use "${temp}/hp_001", clear

gen p_per_size = price / size_imputed

local CSOK CSOK_15000

replace  `CSOK' = 2 if `CSOK' == .
collapse (mean) p_per_size , by(ty `CSOK')
ren p_per_size P_
reshape wide P_, i(ty) j(`CSOK')

line P_* ty
gen  diff = P_1 - P_0
line diff ty




/*------------------------------------------------------------------------------
	descriptives
------------------------------------------------------------------------------*/

use "${temp}/hp_001", clear

gen p_per_size = price / size_imputed

drop if CSOK_15000 == .
collapse (mean) p_per_size, by(ty size_cat_imp CSOK_15000)
ren p_per_size  P_
reshape wide P_, i(ty size_cat) j(CSOK)

line P_* ty if size_cat == 55 ||  line P_* ty if size_cat == 60 

line P_* ty if size_cat == 55 ||  line P_* ty if size_cat == 60 




use "${temp}/hp_001", clear

gen p_per_size = price / size_imputed

*drop if out == 0
drop if CSOK_15000 == .
drop if size_cat_i == .
collapse (mean) p_per_size, by(ty size_cat_imp CSOK_15000)
ren p_per_size  P_
reshape wide P_, i(ty size_cat) j(CSOK)
ren P_* P_*_
reshape wide P*, i(ty) j(size)

line   P_1_40 P_1_45 P_1_50 P_1_55 P_1_60 P_1_65 P_1_70 P_1_75 P_1_80 P_1_85 P_1_90 ty, lpattern(_)


line   P_0_40 P_0_45 P_0_50 P_0_55 P_0_60 P_0_65 P_0_70 P_0_75 P_0_80 P_0_85 P_0_90 ty



forval i = 40(5)90 {
	local j = `i' + 5
	cap drop D_`i'_`j'
	gen D_`i'_`j' = (P_1_`j' - P_0_`j') - (P_1_`i' - P_0_`i')
}





line D_40_45 ty, xline(2018.5)
line D_45_50 ty, xline(2018.5)
line D_50 ty, xline(2018.5)
line D_55 ty, xline(2018.5)
line D_60 ty, xline(2018.5)
line D_65 ty, xline(2018.5)
line D_70 ty, xline(2018.5)
line D_75 ty, xline(2018.5)
line D_80 ty, xline(2018.5)
line D_85 ty, xline(2018.5)


line P_1_40 P_0_40 P_1_45 P_0_45 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)

line P_1_45 P_0_45 P_1_50 P_0_50 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_50 P_0_50 P_1_55 P_0_55 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_55 P_0_55 P_1_60 P_0_60 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)



line P_1_60 P_0_60 P_1_65 P_0_65 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)

line P_1_65 P_0_65 P_1_70 P_0_70 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)

line P_1_70 P_0_70 P_1_75 P_0_75 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_75 P_0_75 P_1_80 P_0_80 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_80 P_0_80 P_1_85 P_0_85 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_85 P_0_85 P_1_90 P_0_90 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)

line P_1_90 P_0_90 P_1_95 P_0_95 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)


line P_1_45 P_0_45 P_1_50 P_0_50 ty, lpattern(solid _ solid _) lcolor(red red blue blue) xline(2018.5)






use "${temp}/hp_001", clear

gen p_per_size = price / size_imputed

drop if size_cat_i == .
collapse (mean) p_per_size, by(ty size_cat_imp )
ren p_per_size  P_
reshape wide P_, i(ty ) j(size_cat)
ren P_* P_*_


line   P_40 P_45 P_50 P_55 P_60 P_65 P_70 P_75 P_80 P_85 P_90 ty


line   P_85 P_90 ty

line   P_55 P_60 ty

line   P_75 P_80 ty




/*------------------------------------------------------------------------------
	policy & number of transactions
------------------------------------------------------------------------------*/


use "${temp}/hp_001", clear

gen N_tr = 1

local CSOK CSOK_15000

replace  `CSOK' = 2 if `CSOK' == .
collapse (sum) N_tr , by(ty `CSOK')
ren N_tr N_tr_
reshape wide N_tr_, i(ty) j(`CSOK')

line N_tr_* ty
gen  diff = N_tr_1 - N_tr_0
line diff ty




use "${temp}/hp_001", clear

drop if de01_2018 > 30000
gen N_tr = 1
gen p_per_size = price / size_imputed


collapse (sum) N_tr (mean) de01_2018 p_per_size women* subsidy*, by(ty ksh4)

gen N_tr_percap = N_tr / de01_2018
gen S_1 = subsidy_1 / women
gen S_2 = subsidy_2 / women
gen S_3 = subsidy_3 / women
gen S_4 = subsidy_4 / women
gen S_12 = S_1 + S_2


xtset ksh4 ty
gen D_p_per_size = p_per_size - l.p_per_size
gen D2_p_per_size = p_per_size - l2.p_per_size
gen D3_p_per_size = p_per_size - l3.p_per_size



binscatter N_tr_perc de01_2018 if ty == 2014, rd(5000)
binscatter N_tr_perc de01_2018 if ty == 2014 [aw = de01_2018], rd(5000) nq(100)

binscatter N_tr_perc de01_2018 if ty == 2017, rd(5000)
binscatter N_tr_perc de01_2018 if ty == 2017 [aw = de01_2018], rd(5000) nq(100)

binscatter N_tr_perc de01_2018 if ty == 2018, rd(5000)
binscatter N_tr_perc de01_2018 if ty == 2018 [aw = de01_2018], rd(5000) nq(100)

binscatter N_tr_perc de01_2018 if ty == 2019, rd(5000)
binscatter N_tr_perc de01_2018 if ty == 2019 [aw = de01_2018], rd(5000) nq(100)

binscatter N_tr_perc de01_2018 if ty == 2021, rd(5000) nq(100)
binscatter N_tr_perc de01_2018 if ty == 2021 [aw = de01_2018], rd(5000) nq(100)



binscatter p_per_size de01_2018 if ty == 2014 [aw = N_tr], rd(5000) nq(100)


binscatter p_per_size de01_2018 if ty == 2015 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2018 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2019 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2021 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2022 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2023 [aw = N_tr], rd(5000) nq(100)
binscatter p_per_size de01_2018 if ty == 2024 [aw = N_tr], rd(5000) nq(100)


binscatter D3_p_per_size de01_2018 if ty == 2022 [aw = N_tr], rd(5000) nq(100)
binscatter D3_p_per_size de01_2018 if ty == 2019 [aw = N_tr], rd(5000) nq(100)
binscatter D3_p_per_size de01_2018 if ty == 2015 [aw = N_tr], rd(5000) nq(100)
binscatter D3_p_per_size de01_2018 if ty == 2018 [aw = N_tr], rd(5000) nq(100)


binscatter S_12 de01_2018 if ty == 2018 , rd(5000) nq(100)
binscatter D3_p_per_size  S_12  if ty == 2015 ,  nq(100)

binscatter D3_p_per_size  S_12  if ty == 2018 ,  nq(100)
reg D3_p_per_size  S_12  if ty == 2018 ,  



use "${temp}/hp_001", clear

cap drop POST
gen POST = (ty>2015)

gen S_1 = subsidy_1 / women
gen S_2 = subsidy_2 / women
gen S_3 = subsidy_3 / women
gen S_4 = subsidy_4 / women
gen S_12 = S_1 + S_2

gen p_per_size = price / size_imputed
gen ln_p_per_size = ln(p_per_size)

gen size_imputed_sq = size_imputed * size_imputed


keep if inrange(ty, 2012, .)
reghdfe ln_price size_i c.S_12##i.POST, absorb(ksh4_bpker ty i.jaras175##i.ty)



reghdfe ln_price size_i c.S_12##ib2015.ty, absorb(ksh4_bpker ty i.rkod##i.ty) cluster(ksh4_bpker)


reghdfe ln_price size_imputed c.S_12##ib2015.ty c.S_3##ib2015.ty c.S_4##ib2015.ty, absorb(ksh4_bpker ty i.rkod##i.ty) cluster(ksh4_bpker)



reghdfe ln_p_per_size size_imputed c.S_12##ib2015.ty c.S_3##ib2015.ty c.S_4##ib2015.ty, absorb(ksh4_bpker ty i.rkod##i.ty) cluster(ksh4_bpker)


reghdfe ln_p_per_size size_i c.S_12##ib2015.ty, absorb(ksh4_bpker ty i.rkod##i.ty) cluster(ksh4_bpker)

reghdfe ln_p_per_size  c.S_12##ib2015.ty, absorb(ksh4_bpker ty c.size_imputed##i.ty c.size_imputed_sq##i.ty i.rkod##i.ty) cluster(ksh4_bpker)
 
reghdfe ln_p_per_size  c.S_12##ib2015.ty, absorb(ksh4_bpker ty c.size_imputed##i.ty c.size_imputed_sq##i.ty c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty  i.rkod##i.ty) cluster(ksh4_bpker)






/*------------------------------------------------------------------------------
	number of transactions, crude diff-in-diff
------------------------------------------------------------------------------*/


use "${temp}/hp_001", clear


drop if CSOK_15000 == .
drop if size_cat_imp == .

gen N_tr = 1
collapse (sum) N_tr, by(ty size_cat_imp CSOK_15000)
ren N_tr  N_tr_
reshape wide N_tr_, i(ty size_cat) j(CSOK)
ren N_tr_* N_tr_*_
reshape wide N_tr*, i(ty) j(size)

line   N_tr_1_40 N_tr_1_45 N_tr_1_50 N_tr_1_55 N_tr_1_60 N_tr_1_65 N_tr_1_70 N_tr_1_75 N_tr_1_80 N_tr_1_85 N_tr_1_90 ty, lpattern(_)


line   N_tr_0_40 N_tr_0_45 N_tr_0_50 N_tr_0_55 N_tr_0_60 N_tr_0_65 N_tr_0_70 N_tr_0_75 N_tr_0_80 N_tr_0_85 N_tr_0_90 ty, lpattern(_)



forval i = 40(5)90 {
	local j = `i' + 5
	cap drop D_`i'_`j'
	gen D_`i'_`j' = (N_tr_1_`j' - N_tr_0_`j') - (N_tr_1_`i' - N_tr_0_`i')
}





line D_40_45 ty, xline(2018.5)
line D_45_50 ty, xline(2018.5)
line D_50 ty, xline(2018.5)
line D_55 ty, xline(2018.5)
line D_60 ty, xline(2018.5)
line D_65 ty, xline(2018.5)
line D_70 ty, xline(2018.5)
line D_75 ty, xline(2018.5)
line D_80 ty, xline(2018.5)
line D_85 ty, xline(2018.5)





/*------------------------------------------------------------------------------

------------------------------------------------------------------------------*/


use "${temp}/hp_001", clear

cap drop POST
gen POST = (ty>2014)

gen p_per_size = price / size_imputed
gen ln_p_per_size = ln(p_per_size)

drop if out == 0


eststo clear

forval i = 40(5)90 {
	
	local lo = `i' - 4
	local hi = `i' + 4
	
	cap drop size_i_rec 
	cap drop BIG
	
	gen size_i_rec = size_imputed - `i'
	gen BIG = (size_i_rec >= 0)

	eststo q_`i' : reghdfe ln_p_per_size  i.POST##c.size_i_rec##i.BIG if inrange(size_imputed, `lo',`hi'), absorb(ksh4_bpker ty)

}

esttab, keep(1.POST#1.BIG)








/*------------------------------------------------------------------------------


use "${temp}/hp_001", clear


gen N_tr = 1
collapse (sum) N_tr, by(ty ksh4)
tempfile N_tr
save `N_tr'


use "${temp}/tstar_important", clear
duplicates drop ksh4 ty, force

merge 1:1 ksh4 ty using `N_tr', keep(1 2 3)
tab ty _

collapse (sum) la* N_tr, by(ty)

line N_tr la02 ty if inrange(ty, 2007, .)











use "${temp}/tstar_important", clear
keep if ty == 2018

gen S_1 = subsidy_1 / women_15_39
gen S_2 = subsidy_2 / women_15_39
gen S_3 = subsidy_3 / women_15_39
gen S_4 = subsidy_4 / women_15_39
gen S_12 = S_1 + S_2
gen S_124 = S_1 + S_2 + S_4
gen S_123 = S_1 + S_2 + S_3

reghdfe S_1 CSOK_15000 , cluster(ksh4)
reghdfe S_12 CSOK_15000 , cluster(ksh4)

reghdfe S_12 CSOK_15000 SH_t* , cluster(ksh4)

reghdfe S_12 SH_t_* i.rkod, cluster(ksh4)

reghdfe S_12 fcs, cluster(ksh4)

binscatter S_1 fcs if inrange(de01_2018, 0, 30000) , nq(100)
binscatter S_1 fcs if inrange(de01_2018, 0, 30000) & S_1 != 0, nq(100)
binscatter S_2 fcs if inrange(de01_2018, 0, 30000) , nq(100)
binscatter S_2 fcs if inrange(de01_2018, 0, 30000) & S_2 != 0, nq(100)
binscatter S_3 fcs if inrange(de01_2018, 0, 30000) , nq(100)
binscatter S_3 fcs if inrange(de01_2018, 0, 30000) & S_3 != 0, nq(100)
binscatter S_4 fcs if inrange(de01_2018, 0, 30000) , nq(100)
binscatter S_4 fcs if inrange(de01_2018, 0, 30000) & S_4 != 0, nq(100)

binscatter S_12 fcs if inrange(de01_2018, 0, 30000)  & S_12 != 0, nq(100)

binscatter de01_2018 fcs  if inrange(de01_2018, 0, 30000)  , nq(100)


binscatter S_1 de01_2018 if inrange(de01_2018, 0, 30000) & S_1 != 0, nq(100)
binscatter S_2 de01_2018 if inrange(de01_2018, 0, 30000) & S_2 != 0, nq(100)
binscatter S_12 de01_2018 if inrange(de01_2018, 0, 30000) & S_12 != 0, nq(100)
binscatter S_123 de01_2018 if inrange(de01_2018, 0, 30000) & S_123 != 0, nq(100)
binscatter S_124 de01_2018 if inrange(de01_2018, 0, 30000) & S_124 != 0, nq(100)
binscatter S_4 de01_2018 if inrange(de01_2018, 0, 30000) & S_4 != 0, nq(100)
binscatter S_3 de01_2018 if inrange(de01_2018, 0, 30000) & S_3 != 0, nq(100)

binscatter S_12 SH_t_1 
binscatter S_12 SH_t_1 [aw = de01]

binscatter S_12 fcs_
binscatter S_12 SH_t_1 [aw = de01]



/*------------------------------------------------------------------------------
	diff-in-disc
------------------------------------------------------------------------------*/




use "${temp}/hp_001", clear

keep if inrange(ty, 2014, .)

cap drop POST
gen POST = (ty>2018)

gen p_per_size = price / size_imputed
gen ln_p_per_size = ln(p_per_size)
gen ln_size_imputed = ln(size_imputed)
gen de01_2018_rec = de01_2018 - 5000

tab jelleg, gen(J_)
lab def J 1 "családi ház" 2 "többlakásos" 3 "panel"



foreach OUTCOME in  ln_price  ln_size_imputed  ln_p_per_size uj  J_1 /* J_2 J_3 */   {
	foreach BW in  5000 10000  15000 {
		eststo clear
		
		eststo q_1 : reghdfe `OUTCOME' i.POST##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty ) cluster(ksh4_bpker)

		eststo q_2 : reghdfe `OUTCOME' i.POST##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty c.SH_t_1##i.POST  c.SH_t_2##i.POST  c.SH_t_3##i.POST  c.SH_t_4##i.POST )  cluster(ksh4_bpker)

		eststo q_3 : reghdfe `OUTCOME' i.POST##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty c.U_2018##i.POST c.ln_income_2018##i.POST )  cluster(ksh4_bpker)

		eststo q_4 : reghdfe `OUTCOME' i.POST##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty c.SH_t_1##i.POST  c.SH_t_2##i.POST  c.SH_t_3##i.POST  c.SH_t_4##i.POST i.rkod##i.POST)  cluster(ksh4_bpker)

		eststo q_5 : reghdfe `OUTCOME' i.POST##i.CSOK_`BW'##c.de01_2018_rec if out == 1, absorb(ksh4_bpker ty c.SH_t_1##i.POST  c.SH_t_2##i.POST  c.SH_t_3##i.POST  c.SH_t_4##i.POST i.rkod##i.POST)  cluster(ksh4_bpker)
		
		
		esttab * using "${output}/tab_hp_`OUTCOME'_BW`BW'.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g)  

	}
}


foreach OUTCOME in ln_p_per_size /* ln_price  ln_size_imputed   uj  J_1 J_2 J_3  */ {
	foreach BW in  /* 5000 10000 */  15000 {
		eststo clear
		

		eststo q_1 : reghdfe `OUTCOME' ib2018.ty##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty )  cluster(ksh4_bpker)

		eststo q_4 : reghdfe `OUTCOME' ib2018.ty##i.CSOK_`BW'##c.de01_2018_rec , absorb(ksh4_bpker ty c.SH_t_1##i.ty  c.SH_t_2##i.ty  c.SH_t_3##i.ty  c.SH_t_4##i.ty i.rkod##i.ty)  cluster(ksh4_bpker)

		
		
		esttab * using "${output}/tab_hp_`OUTCOME'_BW`BW'_dynamic.rtf", replace b(%9.4g) se(%9.4g) r2(%9.4g) ar2(%9.4g) pr2(%9.4g)  

	}
}




/*------------------------------------------------------------------------------

------------------------------------------------------------------------------*/


use "${temp}/hp_001", clear

keep if inrange(ty, 2014, .)


gen S_1 = subsidy_1 / women_15_39
gen S_2 = subsidy_2 / women_15_39
gen S_3 = subsidy_3 / women_15_39
gen S_4 = subsidy_4 / women_15_39
gen S_12 = S_1 + S_2

cap drop POST
gen POST = (ty>2018)

gen p_per_size = price / size_imputed
gen ln_p_per_size = ln(p_per_size)

drop if out == 0


gen de01_2018_rec = de01_2018 - 5000


tab size_cat_i, gen(SIZE_)


eststo clear

eststo q_1 : reghdfe ln_p_per_size i.POST##i.CSOK_15000##c.de01_2018_rec , absorb(ksh4_bpker ty ) 


reghdfe ln_p_per_size size i.POST##i.CSOK_5000##c.de01_2018_rec , absorb(ksh4_bpker ty) 


eststo clear
forval i = 1(1)17 {
	eststo q_`i' : reghdfe ln_p_per_size i.POST##i.CSOK_10000##c.de01_2018_rec if SIZE_`i' == 1, absorb(ksh4_bpker ty  ) cluster(ksh4_bpker)
}
esttab , keep(1.POST#1.CSOK_10000)


eststo q_1 : reghdfe ln_p_per_size size uj ib2018.ty##i.CSOK_15000##c.de01_2018_rec , absorb(ksh4_bpker ty  ) cluster(ksh4_bpker)



eststo q_1 : reghdfe ln_p_per_size ib2018.ty##i.CSOK_10000##c.de01_2018_rec , absorb(ksh4_bpker ty  ) cluster(ksh4_bpker)




eststo q_1 : reghdfe ln_p_per_size ib2018.ty##i.CSOK_5000##c.de01_2018_rec , absorb(ksh4_bpker ty  ) 


eststo q_1 : reghdfe ln_p_per_size ib2018.ty##i.CSOK_2000##c.de01_2018_rec , absorb(ksh4_bpker ty  ) 



eststo q_1 : reghdfe ln_p_per_size ib2018.ty##i.CSOK_15000##c.de01_2018_rec , absorb(ksh4_bpker ty c.S_1##i.ty  c.S_2##i.ty ) 



