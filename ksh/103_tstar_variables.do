

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



duplicates drop ksh4, force

keep ksh4 agglomeration

ren ksh4 tazon
compress
save "${temp}/agglomeration_2003", replace



/*------------------------------------------------------------------------------
	put together a file from T-Star with most important variables
	(easier merging on later; 1 file instead of many
------------------------------------------------------------------------------*/

use "${csok}/village_csok", clear
keep ksh4 village_csok
ren ksh4 tazon
ren village_csok CSOK_0000
lab var CSOK_0000 "Rural CSOK indicator (original)"
tempfile csok
save `csok'

use ${tstar}/de, clear
keep  tazon ev de01 jaras175 mkod2018 rkod2018

* missing if outside bandwidth, 1 just below 5K and 0 just above 5K
foreach BW in 2000 3000 4000 5000 {

	gen CSOK_`BW' = .
	local lower = 5000 - `BW'
	local upper = 5000 + `BW'
	replace CSOK_`BW' = 1 if de01!=. & inrange(de01, `lower', 4999)
	replace CSOK_`BW' = 0 if de01!=. & inrange(de01, 5000, `upper')
	lab var CSOK_`BW' "CSOK indicator, bandwidth = `BW'"
}
* TIM addition 10/02/2025
gen CSOK_all = .
replace CSOK_all = 1 if de01!=. & de01<=4999 
replace CSOK_all = 0 if de01!=. & de01>=4999
lab var CSOK_all "CSOK indicator, bandwidth = all"

tempfile de
save `de'


use ${tstar}/mn, clear
keep  tazon ev mn01
tempfile mn
save `mn'


use ${tstar}/tx, clear
keep  tazon ev tx01 tx02 tx03
tempfile tx
save `tx'




use `de', clear
merge 1:1 tazon ev using `mn', nogen keep(1 3)
merge 1:1 tazon ev using `tx', nogen keep(1 3)
merge m:1 tazon  using `csok', nogen keep(1 3)
merge m:1 tazon using "${temp}/agglomeration_2003", nogen keep( 1 3)

ren tazon ksh4
ren ev ty

order ksh4 ty jaras mkod rkod CSOK_0 CSOK_2 CSOK_3 CSOK_4 CSOK_5 CSOK_all

save "${temp}/tstar_important", replace