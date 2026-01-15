

use "${census}/szemely", clear

keep if neme == 2


gen tm_mother_birth = ym(szev, ho)
format tm_mother_birth %tm

gen td_mother_birth = mdy(ho, nap, szev)
format td_mother_birth %td

gen ty_mother_birth = yofd(dofm(tm_mother_birth))
keep if inrange(ty_mother_birth, 1973, 1977)


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


keep szemazon tm_mother_birth  tm* td* ksh4* ty* irelo irelsz lcstip hazev cspot



preserve

	clear
	set obs 3000
	gen ty = _n if inrange(_n, 1983, 2022)
	drop if ty == .	
	
	tempfile timeframe
	save `timeframe'


restore

cross using `timeframe'

gen mother_age_tm = (ty - ty_mother_birth) 


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
save "${temp}/census_101", replace

aaa



use "${temp}/census_101", clear



foreach X in 2011 2012 2014 2015 2019 2021 2022 {
	gen tmp_C_children_`X' = C_children if ty == `X'
	egen C_children_`X' = mean(tmp_C_children_`X' ), by(szemazon)
	drop tmp_C_children_`X'
}




gen d_C_children = C_children_2021 - C_children_2015
gen d2_C_children = C_children_2019 - C_children_2015
 
save "${temp}/census_102", replace

 
/*------------------------------------------------------------------------------
	searching for the age cutoff for CSOK (2015)
		5478 : december 31, 1974
		5721 : august 31, 1975
------------------------------------------------------------------------------*/

use "${temp}/census_102", clear


binscatter C_children_2015 td_mother_birth if ty == 2022 ,  nq(100) xline(5478.5)
binscatter d_C_children td_mother_birth if ty == 2022 ,  nq(100) xline(5478.5)




binscatter C_children_2015 td_mother_birth if ty == 2022 ,  nq(100) xline(5721.5)
binscatter d_C_children td_mother_birth if ty == 2022 ,  nq(100) xline(5721.5)
binscatter d_C_children tm_mother_birth if ty == 2022 ,  nq(100) xline(187.5)



binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(50)
binscatter d_C_children td_mother_birth if ty == 2022, xline(5478) nq(100)

 
binscatter d_C_children tm_mother_birth if ty == 2022, xline(191)
binscatter d_C_children tm_mother_birth if ty == 2022, rd(191.5)

binscatter C_children_2014 tm_mother_birth if ty == 2022, rd(191.5)


rdrobust d_C_children tm_mother_birth if ty == 2022 ,  all c(187.5)
rdrobust d2_C_children tm_mother_birth if ty == 2022 ,  all c(187.5) h(8) b(12)


rdrobust d_C_children td_mother_birth if ty == 2022 ,  all c(5721.5) h(180) b(360)
rdrobust d_C_children td_mother_birth if ty == 2022 ,  all c(5721.5) h(90) b(180)
rdrobust C_children_2015 td_mother_birth if ty == 2022 ,  all c(5721.5) h(180) b(360)


