



forval i = 2016(1)2024 {

	use ${divorce}/Valas_`i', clear
	
	foreach X of  varlist * {
				
		local v_`X' = strlower("`X'")
		ren `X' `v_`X''

	}	
	
	tempfile y_`i'
	save `y_`i''
	
	
	
}



use ${divorce}/Valas_1977-2015, clear

foreach X of  varlist * {
			
	local v_`X' = strlower("`X'")
	ren `X' `v_`X''

}

forval i = 2016(1)2024 {

	append using `y_`i''

}


foreach X of varlist vl_* {
	
	local new_name = subinstr("`X'", "vl_", "", 1)
	ren `X' `new_name'
	
}

save "${temp}/divorce_001", replace


/*------------------------------------------------------------------------------
	cleaning
------------------------------------------------------------------------------*/


use "${temp}/divorce_001", clear



foreach X in es kot fszul nszul {
	
	if "`X'" == "es" {
		local Y = "divorce"
	}
	if "`X'" == "fszul" {
		local Y = "husband"
	}
	if "`X'" == "nszul" {
		local Y = "wife"
	}
	if "`X'" == "kot" {
		local Y = "marriage"
	}
	
	gen ty_`Y' = `X'ev
	gen tm_`Y' = ym(`X'ev, `X'ho)
	format tm_`Y' %tm
	gen td_`Y' = mdy(`X'ho, `X'nap, `X'ev)
	format td_`Y' %td

}


keep if inrange(ty_divorce, 2000, .)

gen ksh4_bpker_wife = ntart
replace ksh4_bpker_wife = nlak if ksh4_bpker_wife == .

gen ksh4_wife = ksh4_bpker_wife

foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4_wife = 1357 if ksh4_bpker_wife == `Y'
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



ren fkor age_husband
ren nkor age_wife
ren felve kids_husband
ren nelve kids_wife

save "${temp}/divorce_002", replace





/*------------------------------------------------------------------------------
	collapse + merge settlement level variables
------------------------------------------------------------------------------*/




use "${temp}/divorce_002", clear
gen N_divorce = 1
collapse (sum) N_divorce , by(ty_divorce ksh4_wife )
tempfile divorce
save `divorce'


use "${temp}/tstar_important", clear
ren ksh4 ksh4_wife
ren ty ty_divorce

merge m:1 ksh4_wife ty_divorce using `divorce', keep(1 3) nogen

replace N_divorce = 0 if N_divorce == .

gen ln_de01 = ln(de01)
gen income = (tx02 - tx03) / tx01
gen ln_income = ln(income)
gen U = mn01 / de01


foreach X of varlist ln_income de01 ln_de01 de16 U {
	
	foreach Y in 2014 2018 {
		gen tmp_`X' = `X' if ty_divorce == `Y'
		egen `X'_`Y' = mean(tmp_`X'), by(ksh4_wife)
		drop tmp_`X'
	}
	
}

gen sh_divorce = N_divorce / de01 * 1000
gen post_2015 = (ty_divorce>= 2015)
gen post_2019 = (ty_divorce>= 2019)


ren ty_divorce ty


save "${temp}/divorce_003", replace




/*------------------------------------------------------------------------------
	aggregate statistics
------------------------------------------------------------------------------*/

use "${temp}/divorce_002", clear


gen one = 1

collapse (sum) one, by(ty_divorce)


#d ;
	line one ty if inrange(ty, 2000, .),
		xtitle("")
		ytitle("Number of divorces")
		xline(2014.5 2018.5)
		;

#d cr



use "${temp}/divorce_002", clear


gen one = 1

collapse (sum) one, by(tm_divorce)


#d ;
	line one tm if inrange(tm, ym(2014,1), ym(2020,12)),
		xtitle("")
		ytitle("Number of divorces")
		xline(2014.5 2018.5)
		;

#d cr







/*------------------------------------------------------------------------------
	rural CSOK
------------------------------------------------------------------------------*/


global cc_1_post "c.ln_income_2018##i.post_2019 c.U##i.post_2019 c.ln_de01_2018##i.post_2019 " /*c.ln_de01_2018##i.post_2019 */
global cc_1_ty  "c.ln_income_2018##i.ty c.U##i.ty c.ln_de01_2018##i.ty" /* */
 
global cc_2_post "i.rkod##i.post_2019"
global cc_2_ty "i.rkod##i.ty"
 
global cc_3_post "i.mkod##i.post_2019"
global cc_3_ty "i.mkod##i.ty"
  
global cc_4_post "i.jaras##i.post_2019"
global cc_4_ty "i.jaras##i.ty"
  



use "${temp}/divorce_003", clear



eststo clear
eststo q_1 : reghdfe sh i.CSOK_5000##i.post_2019 [aw = de01_2018], absorb(ksh4_wife ty) cluster(ksh4)

eststo q_2 : reghdfe sh i.CSOK_5000##i.post_2019  [aw = de01_2018], absorb(ksh4_wife ty $cc_1_post) cluster(ksh4)

eststo q_3 : reghdfe sh i.CSOK_5000##i.post_2019 [aw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_2_post) cluster(ksh4)

eststo q_4 : reghdfe sh i.CSOK_5000##i.post_2019 [aw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_3_post) cluster(ksh4)

eststo q_5 : reghdfe sh i.CSOK_5000##i.post_2019 [aw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_4_post) cluster(ksh4)


esttab




use "${temp}/divorce_003", clear

replace de01_2018 = round(de01_2018)

eststo clear
eststo q_1 : ppmlhdfe N_divorce i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4_wife ty) cluster(ksh4)

eststo q_2 : ppmlhdfe N_divorce i.CSOK_5000##i.post_2019  [fw = de01_2018], absorb(ksh4_wife ty $cc_1_post) cluster(ksh4)

eststo q_3 : ppmlhdfe N_divorce i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_2_post) cluster(ksh4)

eststo q_4 : ppmlhdfe N_divorce i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_3_post) cluster(ksh4)

eststo q_5 : ppmlhdfe N_divorce i.CSOK_5000##i.post_2019 [fw = de01_2018], absorb(ksh4_wife ty $cc_1_post $cc_4_post) cluster(ksh4)


esttab





use "${temp}/divorce_003", clear


local BW = 5000
reghdfe sh i.CSOK_`BW'##ib2018.ty   if inrange(ty, 2014, 2023) [aw = de01_2018], absorb(ksh4_wife ty $cc_1_ty /* $cc_2_ty */ ) cluster(ksh4)

gen TIME = _n if inrange(_n, 2000, 2023)
gen b = .
gen se = .


forval i = 2008(1)2023 {
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
			xline(2018.5)	
		;
#d cr





