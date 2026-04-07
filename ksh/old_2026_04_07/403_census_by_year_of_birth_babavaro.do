
use "${census}/szemely", clear

keep if neme == 2


gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm

gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td

gen ty_mother_birth = yofd(dofm(tm_mother_birth))
keep if inrange(ty_mother_birth, 1970, 1983)


gen ksh4_bpker = int(terul/10)
gen ksh4 = ksh4_bpker

foreach Y in 956 317 1806 546 1339 1658 2974 2540 2958 1070 1421 2469 2429 1633 1131 820 211 2928 401 602 1318 1021 3413 {
	replace ksh4 = 1357 if ksh4_bpker == `Y'
}


gen tm_child_1 = ym(elszev, elszho)
gen tm_child_2 = ym(maszev, maszho)
gen tm_child_3 = ym(haszev, haszho)
gen tm_child_4 = ym(neszev, neszho)
gen tm_child_5 = ym(otszev, otszho)
gen tm_child_6 = ym(szev6, ho6)
gen tm_child_7 = ym(szev7, ho7)
gen tm_child_8 = ym(szev8, ho8)
gen tm_child_9 = ym(szev9, ho9)
gen tm_child_10 = ym(uszev, uszho)

forval i = 1(1)10 {
	format tm_child_`i' %tm
}


keep szemazon tm_mother_birth  tm* td* ksh4* ty* irelo irelsz lcstip hazev cspot hazev



preserve

	clear
	set obs 3000
	gen ty = _n if inrange(_n, 1983, 2022)
	drop if ty == .	
	
	tempfile timeframe
	save `timeframe'


restore

cross using `timeframe'

gen mother_age_ty = (ty - ty_mother_birth) 


forval i = 1(1)10 {
	gen ty_child_`i' = yofd(dofm(tm_child_`i'))
}

gen N_children = 0
sort szemazon ty 
forval i = 1(1)10 {
	replace N_children = N_children + 1 if ty_child_`i' == ty
}
bysort szemazon : gen C_children = sum(N_children)

drop tm_child* ty_child*


* EDUCATION
gen eduCatg = 0
* no secondary school
replace eduCatg = 1 if inlist(irelsz,0,1)
* secondary-vocational
replace eduCatg = 2 if inlist(irelsz,2,3,4)
* secondary-general + some non-degree tertiary
replace eduCatg = 3 if inlist(irelsz,5,6,7)
* college, university, or grad degree
replace eduCatg = 4 if inlist(irelsz,8,9,10)

* family type
gen ftype = .
replace ftype = 1 if inrange(lcstip, 1, 4)
replace ftype = 2 if inrange(lcstip, 5, 8)
replace ftype = 3 if inrange(lcstip, 9, 11)
replace ftype = 4 if inlist(lcstip, 12)
replace ftype = 5 if inlist(lcstip, 13)


* MARITAL STATUS
gen married = (cspot==2 & ty>hazev)
* gen 2019 dummy
gen marriedBy2019 = (cspot==2 & hazev<2019)



 
tab eduCatg, gen(edu_)
tab ftype, gen(ftype_)
tab irelsz, gen(irelsz_)

compress
save "${temp}/census_201", replace

aaa





use "${temp}/census_201", clear



foreach X in 2014 2015 2016 2017 2018 2019 2020 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}

gen d_C_children = C_children_2022 - C_children_2019
gen d2_C_children = C_children_2021 - C_children_2019
gen d_C_children_placebo = C_children_2019 - C_children_2016
 

 
 
gen cum_2019_0     = (C_children_2019 == 0)
gen cum_2019_1     = (C_children_2019 == 1)
gen cum_2019_2     = (C_children_2019 == 2)
gen cum_2019_3plus = (C_children_2019 >  2)


 
save "${temp}/census_202", replace





 * keep one x-section
*keep if ty == 2022



/*------------------------------------------------------------------------------
	optimal BW calculation
------------------------------------------------------------------------------*/


*rdbwselect d_C_children tm_mother_birth if ty == 2019, c(235.5)
*global H = `e(h_mserd)'
*global B = `e(b_mserd)'

global H_month = 12
global H_day = 365
global B_month = 24
global B_day = 730

global H_month_half = 6
global B_month_half = 12
global H_day_half = 180
global B_day_half = 360



/*------------------------------------------------------------------------------
	balance figures
------------------------------------------------------------------------------*/

use "${temp}/census_202", clear

#d ;
	binscatter edu_1 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother's education: primary school")
	;
#d cr
graph export "${output}/RDD_mother_birth_edu_1.pdf", as(pdf) replace

#d ;
	binscatter edu_2 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother's education: vocational school")
	;
#d cr
graph export "${output}/RDD_mother_birth_edu_2.pdf", as(pdf) replace

#d ;
	binscatter edu_3 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother's education: high school")
	;
#d cr
graph export "${output}/RDD_mother_birth_edu_3.pdf", as(pdf) replace

#d ;
	binscatter edu_4 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother's education: college")
	;
#d cr
graph export "${output}/RDD_mother_birth_edu_4.pdf", as(pdf) replace


#d ;
	binscatter irelo tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother's years of education")
	;
#d cr
graph export "${output}/RDD_mother_birth_yearsofeduc.pdf", as(pdf) replace


#d ;
	binscatter marriedBy2019 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Mother married by 2019")
	;
#d cr
binscatter marriedBy2019 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) , discrete rd(235.5 )
graph export "${output}/RDD_mother_birth_marriedby2019.pdf", as(pdf) replace



#d ;
	binscatter C_children_2018 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Number of children by 2018")
	;
#d cr
graph export "${output}/RDD_mother_birth_C_children_2018.pdf", as(pdf) replace



#d ;
	binscatter C_children_2019 tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Number of children by 2019")
	;
#d cr
graph export "${output}/RDD_mother_birth_C_children_2019.pdf", as(pdf) replace


#d ;
	binscatter d_C_children_placebo tm_mother_birth if ty == 2016 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Change in number of children 2016-2019")
	;
#d cr
graph export "${output}/RDD_mother_birth_d_C_children_placebo.pdf", as(pdf) replace



#d ;
	binscatter d_C_children_placebo tm_mother_birth if ty == 2016 & inrange(tm_mother, 163, 236) ,
	discrete 
	rd(199.5 )
	xtitle("Mother's birth month")
	ytitle("Change in number of children 2016-2019")
	;
#d cr
graph export "${output}/RDD_mother_birth_d_C_children_placebo2.pdf", as(pdf) replace


#d ;
	binscatter d_C_children tm_mother_birth if ty == 2019 & inrange(tm_mother, 199, 272) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Change in number of children 2019-2022")
	;
#d cr
graph export "${output}/RDD_mother_birth_d_C_children.pdf", as(pdf) replace



#d ;
	binscatter d_C_children tm_mother_birth if ty == 2019 & inrange(tm_mother, 221, 245) ,
	discrete 
	rd(235.5 )
	xtitle("Mother's birth month")
	ytitle("Change in number of children 2019-2022")
	;
#d cr




/*------------------------------------------------------------------------------
	histogram of mother's birth date
------------------------------------------------------------------------------*/

use "${temp}/census_202", clear

hist tm_mother_birth if ty == 2019, disc
graph export "${output}/hist_mother_birth_date.pdf", as(pdf) replace




/*------------------------------------------------------------------------------
	balance table
------------------------------------------------------------------------------*/


eststo clear
eststo q_1 : rdrobust edu_1 tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month)

eststo q_2 : rdrobust edu_2 tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month)

eststo q_3 : rdrobust edu_3 tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month)

eststo q_4 : rdrobust edu_4 tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month)

eststo q_5 : rdrobust marriedBy2019 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)




/*------------------------------------------------------------------------------
	main table -- month
------------------------------------------------------------------------------*/

eststo clear

eststo q_1 : rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month)

eststo q_2 : rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h($H_month_half) b($B_month_half)

eststo q_3a : rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month) covs(edu_* marriedBy2019 cum_2019_0 cum_2019_1 cum_2019_2 cum_2019_3plus)

eststo q_3b : rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h($H_month) b($B_month) covs(irelsz_* )




eststo a_1 : rdrobust N_children tm_mother_birth if ty == 2020, c(235.5) all h($H_month) b($B_month)

eststo a_2 : rdrobust N_children tm_mother_birth if ty == 2021, c(235.5) all h($H_month) b($B_month)

eststo a_3 : rdrobust N_children tm_mother_birth if ty == 2022, c(235.5) all h($H_month) b($B_month)




/*------------------------------------------------------------------------------
	main table -- day
------------------------------------------------------------------------------*/

eststo clear

eststo q_1 : rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all h($H_day) b($B_day)

eststo q_2 : rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all h($H_day_half) b($B_day_half)

eststo q_3a : rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all h($H_day) b($B_day) covs(edu_* )

eststo q_3b : rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all h($H_day) b($B_day) covs(irelsz_* )




eststo a_1 : rdrobust N_children td_mother_birth if ty == 2020, c(7182.5) all h($H_month) b($B_month)

eststo a_2 : rdrobust N_children td_mother_birth if ty == 2021, c(7182.5) all h($H_month) b($B_month)

eststo a_3 : rdrobust N_children td_mother_birth if ty == 2022, c(7182.5) all h($H_month) b($B_month)



/*------------------------------------------------------------------------------
	main table -- day
		with various BWs
------------------------------------------------------------------------------*/

gen BW = _n if inrange(_n, 1, 200)
gen b = .
gen se = .

foreach BW in 7 10 14 21 28 30 50 75 100 150 200 {
	local B = 2 * `BW'
	rdrobust d2_C_children td_mother_birth if ty == 2019, c(7182.5) all h(`BW') b(`B')
	replace b = _b[Robust] if BW == `BW'
	replace se = _se[Robust] if BW == `BW'	
}

gen hi = b + 1.96 * se
gen lo = b - 1.96 * se



#d ;
	twoway (scatter b BW) 
			(rcap hi lo BW)
			;
#d cr

drop BW b se hi lo 




/*------------------------------------------------------------------------------
	placebo tests
		number of kids before policy for the same cohorts
------------------------------------------------------------------------------*/

eststo clear


* number of kids born in each year
eststo w_1 : rdrobust C_children_2015 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_2 : rdrobust C_children_2016 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_3 : rdrobust C_children_2017 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_4 : rdrobust C_children_2018 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_5 : rdrobust C_children_2019 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_6 : rdrobust C_children_2020 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_7 : rdrobust C_children_2021 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)

eststo w_7 : rdrobust C_children_2022 tm_mother_birth if ty == 2019  , c(235.5 ) all h($H_month) b($B_month)


* cumulative change in kids, 2016-2019
eststo q_8 : rdrobust d_C_children_placebo tm_mother_birth if ty == 2016 , c(235.5 ) all h($H_month) b($B_month)





/*------------------------------------------------------------------------------
	placebo tests -- month
		number of kids before policy, 
		different cohorts, 
		similar cutoffs (i.e. August)
------------------------------------------------------------------------------*/


*** 1975 August (Stata: 187.5)


eststo clear

* number of kids born in each year
eststo w_1 : rdrobust C_children_2015 tm_mother_birth if ty == 2019  , c(187.5 ) all h($H_month) b($B_month)

eststo w_2 : rdrobust C_children_2016 tm_mother_birth if ty == 2019  , c(187.5 ) all h($H_month) b($B_month)

eststo w_3 : rdrobust C_children_2017 tm_mother_birth if ty == 2019  , c(187.5 ) all h($H_month) b($B_month)

eststo w_4 : rdrobust C_children_2018 tm_mother_birth if ty == 2019  , c(187.5 ) all h($H_month) b($B_month)

eststo w_5 : rdrobust C_children_2019 tm_mother_birth if ty == 2019  , c(187.5 ) all h($H_month) b($B_month)


* cumulative change in kids, 2016-2019
* !!! this is significant !!!
eststo w_6 : rdrobust d_C_children_placebo tm_mother_birth if ty == 2016 , c(187.5 ) all h($H_month) b($B_month)





*** 1976 August (Stata: 199.5)


eststo clear

* number of kids born in each year
eststo w_1 : rdrobust C_children_2015 tm_mother_birth if ty == 2019  , c(199.5 ) all h($H_month) b($B_month)

eststo w_2 : rdrobust C_children_2016 tm_mother_birth if ty == 2019  , c(199.5 ) all h($H_month) b($B_month)

eststo w_3 : rdrobust C_children_2017 tm_mother_birth if ty == 2019  , c(199.5 ) all h($H_month) b($B_month)

eststo w_4 : rdrobust C_children_2018 tm_mother_birth if ty == 2019  , c(199.5 ) all h($H_month) b($B_month)

eststo w_5 : rdrobust C_children_2019 tm_mother_birth if ty == 2019  , c(199.5 ) all h($H_month) b($B_month)


* cumulative change in kids, 2016-2019
eststo w_6 : rdrobust d_C_children_placebo tm_mother_birth if ty == 2016 , c(199.5 ) all h($H_month) b($B_month)




*** 1977 August (Stata: 211.5)

eststo clear

* number of kids born in each year
eststo w_1 : rdrobust C_children_2015 tm_mother_birth if ty == 2019  , c(211.5 ) all h($H_month) b($B_month)

eststo w_2 : rdrobust C_children_2016 tm_mother_birth if ty == 2019  , c(211.5 ) all h($H_month) b($B_month)

eststo w_3 : rdrobust C_children_2017 tm_mother_birth if ty == 2019  , c(211.5 ) all h($H_month) b($B_month)

eststo w_4 : rdrobust C_children_2018 tm_mother_birth if ty == 2019  , c(211.5 ) all h($H_month) b($B_month)

eststo w_5 : rdrobust C_children_2019 tm_mother_birth if ty == 2019  , c(211.5 ) all h($H_month) b($B_month)


* cumulative change in kids, 2016-2019
eststo w_6 : rdrobust d_C_children_placebo tm_mother_birth if ty == 2016 , c(211.5 ) all h($H_month) b($B_month)






/*------------------------------------------------------------------------------
	placebo tests -- day
		number of kids before policy, 
		different cohorts, 
		similar cutoffs (i.e. August)
------------------------------------------------------------------------------*/


*** 1975 August 31 (Stata: 5721.5)


eststo clear

* number of kids born in each year
eststo w_1 : rdrobust C_children_2015 td_mother_birth if ty == 2019  , c(5721.5 ) all h($H_day) b($B_day)

eststo w_2 : rdrobust C_children_2016 td_mother_birth if ty == 2019  , c(5721.5 ) all h($H_day) b($B_day)

eststo w_3 : rdrobust C_children_2017 td_mother_birth if ty == 2019  , c(5721.5 ) all h($H_day) b($B_day)

eststo w_4 : rdrobust C_children_2018 td_mother_birth if ty == 2019  , c(5721.5 ) all h($H_day) b($B_day)

eststo w_5 : rdrobust C_children_2019 td_mother_birth if ty == 2019  , c(5721.5 ) all h($H_day) b($B_day)


* cumulative change in kids, 2016-2019
* !!! this is significant !!!
eststo w_6 : rdrobust d_C_children_placebo td_mother_birth if ty == 2016 , c(5721.5 ) all h($H_day) b($B_day)





/*------------------------------------------------------------------------------
	heterogeneity
------------------------------------------------------------------------------*/

* by education
eststo a_1 : rdrobust d_C_children tm_mother_birth if ty == 2019 & inrange(eduCatg, 1, 1)  , c(235.5 ) all h($H_month) b($B_month)

eststo a_2 : rdrobust d_C_children tm_mother_birth if ty == 2019 & inrange(eduCatg, 2, 2)  , c(235.5 ) all h($H_month) b($B_month)

eststo a_3 : rdrobust d_C_children tm_mother_birth if ty == 2019 & inrange(eduCatg, 3, 3)  , c(235.5 ) all h($H_month) b($B_month)

eststo a_4 : rdrobust d_C_children tm_mother_birth if ty == 2019 & inrange(eduCatg, 4, 4)  , c(235.5 ) all h($H_month) b($B_month)


* by parity
eststo a_1 : rdrobust d_C_children tm_mother_birth if ty == 2019 & C_children_2019 == 0  , c(235.5 ) all h($H_month) b($B_month)

eststo a_2 : rdrobust d_C_children tm_mother_birth if ty == 2019 & C_children_2019 == 1  , c(235.5 ) all h($H_month) b($B_month)

eststo a_3 : rdrobust d_C_children tm_mother_birth if ty == 2019 & C_children_2018 == 2  , c(235.5 ) all h($H_month) b($B_month)

eststo a_4 : rdrobust d_C_children tm_mother_birth if ty == 2019 & C_children_2018 > 2  , c(235.5 ) all h($H_month) b($B_month)




/*------------------------------------------------------------------------------
	kink design?
------------------------------------------------------------------------------*/




rdrobust d_C_children tm_mother_birth if ty == 2019  , c(235.5 ) all deriv(1)
rdrobust d_C_children tm_mother_birth if ty == 2019  , c(235.5 ) all deriv(1) covs(edu_*)



rdrobust d_C_children tm_mother_birth if ty == 2019  , c(235.5 ) all deriv(1)
rdrobust d_C_children td_mother_birth if ty == 2019  , c(7182.5 ) all deriv(1)





/*------------------------------------------------------------------------------
	diff-in-diff
------------------------------------------------------------------------------*/

gen TREATED_1y = .
replace TREATED_1y = 0 if inrange(tm_mother_birth, 224, 235)
replace TREATED_1y = 1 if inrange(tm_mother_birth, 236, 247)

gen TREATED_6m = .
replace TREATED_6m = 0 if inrange(tm_mother_birth, 230, 235)
replace TREATED_6m = 1 if inrange(tm_mother_birth, 236, 241)


gen TREATED_3m = .
replace TREATED_3m = 0 if inrange(tm_mother_birth, 233, 235)
replace TREATED_3m = 1 if inrange(tm_mother_birth, 236, 238)

gen POST = (ty > 2019)




eststo clear
eststo q_1 : reghdfe N_children i.TREATED_1y##i.POST  if  inrange(ty, 2014, .) , absorb(szemazon ty )

eststo q_2 : reghdfe N_children i.TREATED_6m##i.POST  if  inrange(ty, 2014, .) , absorb(szemazon ty )

eststo q_3 : reghdfe N_children i.TREATED_3m##i.POST  if  inrange(ty, 2014, .) , absorb(szemazon ty )



eststo clear
eststo q_1 : reghdfe N_children i.TREATED_3m##ib2019.ty mother_age_ty if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty )


eststo q_2 : reghdfe N_children i.TREATED_3m##i.POST if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.POST)


eststo q_3 : reghdfe N_children i.TREATED_3m##i.POST if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.POST i.marriedBy2019##i.POST)


eststo dyn : reghdfe N_children i.TREATED##ib2019.ty if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.ty i.marriedBy2019##i.ty)




 
  
  
 
* searching for the cutoff
binscatter d_C_children tm_mother_birth if ty == 2019, rd(235.5) ylabel(0 0.05 0.1 0.15 0.2 0.25) nq(50)
graph export "${output}/RDD_mother_birth_change_in_kids.pdf", as(pdf) replace















binscatter d_C_children_place tm_mother_birth if ty == 2016, rd(199.5)  ylabel(0 0.05 0.1 0.15 0.2 0.25) nq(50)
graph export "${output}/RDD_mother_birth_change_in_kids_placebo.pdf", as(pdf) replace

reg d_C_children ib37.mother_age_tm if ty == 2019
reg d_C_children_place ib37.mother_age_tm if ty == 2016
 
 
 binscatter d_C_children mother_age_tm if ty == 2019, nq(50)
 binscatter d_C_children tm_mother_birth if ty == 2019 , discrete xline(235.5 251.5)
 binscatter d_C_children_place tm_mother_birth if ty == 2016 , discrete xline(199.5 )

binscatter d_C_children tm_mother_birth if ty == 2019 & inrange(tm_mother, 220, 250) , discrete rd(235.5 )

 binscatter edu_4 tm_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255) , discrete rd(235.5 )
 binscatter edu_1 tm_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255) , discrete rd(235.5 )


rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(8) b(16)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25) covs(edu_*)


rdrobust C_children_2019 tm_mother_birth if ty == 2019, c(235.5) all h(15) b(25)
 
 
* placebo 
rdrobust d_C_children tm_mother_birth if ty == 2019, c(247.5) all h(15) b(25)
rdrobust d_C_children tm_mother_birth if ty == 2019, c(223.5) all h(15) b(25)


rdrobust d_C_children_place tm_mother_birth if ty == 2016, c(199.5) all h(15) b(25)
 
 
 
* day level birth date
 
 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) discrete
 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) nq(100)

 binscatter d_C_children td_mother_birth if ty == 2019 & inrange(tm_mother, 210, 255), rd(7182.5) nq(100)

 rdrobust d_C_children td_mother_birth if ty == 2019, c(7182.5) all

 
 * diff-in-diff
 gen TREATED = (tm_mother_birth > 235.5)
 gen POST = (ty > 2019)
 reghdfe N_children i.TREATED##i.POST if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.POST)
 
  reghdfe N_children i.TREATED##ib2019.ty mother_age_ty if inrange(tm_mother, 220, 240) & inrange(ty, 2014, .) , absorb(szemazon ty i.eduCatg##i.ty)

  
  


use "${temp}/census_201", clear


/*
foreach X in 2016 2019 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}

gen d_C_children = C_children_2022 - C_children_2019
gen d_C_children_place = C_children_2019 - C_children_2016
 
 
*tab eduCatg, gen(edu_)
*/  
  
collapse (mean) C_children N_chi, by( tm_mother_birth mother_age_ty)
ren C_children C_
ren N_chi N_
reshape wide C_ N_ , i(mother_age_ty) j(tm_mother)
  
  
line C_234 C_235 C_236 C_237 mothe
line N_235 N_236 N_237 N_238 N_239 mothe
line N_235 N_236 mothe
line C_235 C_236 mothe, xline(39)
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(50)
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(100)

 
binscatter d_C_children tm_mother_birth if ty == 2022, xline(239)
binscatter d_C_children tm_mother_birth if ty == 2022, rd(251.5)

binscatter C_children_2014 tm_mother_birth if ty == 2022, rd(191.5)


rdrobust d_C_children tm_mother_birth if ty == 2022, c(251.5) all
rdrobust d_C_children td_mother_birth if ty == 2022, c(7182.5) all
rdrobust C_children_2018 td_mother_birth if ty == 2022, c(7182.5) all
rdrobust C_children_2019 td_mother_birth if ty == 2022, c(7182.5) all


rdrobust C_children_2019 td_mother_birth if ty == 2022, c(6817.5) all
rdrobust d_C_children_place td_mother_birth if ty == 2022, c(6817.5) all

rdrobust d_C_children_place2 td_mother_birth if ty == 2022, c(6452.5) all


