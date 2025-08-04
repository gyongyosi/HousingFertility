

use ${disadv}/komplex_2014, clear
keep jaras_kod komplex_2014
tempfile komplex
save `komplex'


use ${hnk}/hnk_2018, clear

ren jaras_kod J
gen jaras_kod = substr(J, 1, 3)
destring jaras_kod, replace

merge m:1 jaras_kod using `komplex', nogen keep(1 3)

keep ksh4 komplex_2014
duplicates drop ksh4, force /* Budapest districts */

tempfile komplex_ksh4
save `komplex_ksh4'




use ${homeownership}/homeownership, clear

foreach v of var * {
	local l`v' : variable label `v'
	if `"`l`v''"' == "" {
		local l`v' "`v'"
	}
}

collapse (sum) v_* , by(ksh4)




foreach v of var * {
	label var `v' `"`l`v''"'
}

gen sh_homeownership_a = v_5 / (v_5 + v_6 + v_7)
gen sh_homeownership_b = v_8 / (v_8 + v_9 + v_10)
forval i = 1(1)4 {
	gen sh_room_`i' = v_`i' / (v_1 + v_2 + v_3 + v_4)
}

tempfile home
save `home'


use ${educ}/education, clear

collapse (sum) abs_t* , by(ksh4)

gen SH_t_1 = (abs_t_1 + abs_t_2 + abs_t_3) / abs_t_7
gen SH_t_2 = abs_t_4 / abs_t_7
gen SH_t_3 = abs_t_5 / abs_t_7
gen SH_t_4 = abs_t_6 / abs_t_7

lab var SH_t_1 "share of grade 1-8"
lab var SH_t_2 "share of vocational"
lab var SH_t_3 "share of high school"
lab var SH_t_4 "share of college+uni"

tempfile educ
save `educ'

use ${tstar}/de, clear

merge 1:1 tazon ev using ${tstar}/mn, nogen keep(1 3) keepusing(mn*)
merge 1:1 tazon ev using ${tstar}/tx, nogen keep(1 3) keepusing(tx*)
merge 1:1 tazon ev using ${tstar}/ok, nogen keep(1 3) keepusing(ok*)
merge 1:1 tazon ev using ${tstar}/eu, nogen keep(1 3) keepusing(eu*)
merge 1:1 tazon ev using ${tstar}/la, nogen keep(1 3) keepusing(la*)

gen ksh4 = tazon

merge m:1 ksh4 using `educ', nogen keep(1 3)
merge m:1 ksh4 using `home', nogen keep(1 3)
merge m:1 ksh4 using `komplex_ksh4', nogen keep(1 3)

lab lang en

save ${temp}/tstar_01, replace


