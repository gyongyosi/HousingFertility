


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

foreach BW in 2000 3000 4000 5000 {

	gen CSOK_`BW' = .
	local lower = 5000 - `BW'
	local upper = 5000 + `BW'
	replace CSOK_`BW' = 1 if inrange(de01, `lower', 4999)
	replace CSOK_`BW' = 0 if inrange(de01, 5000, `upper')
	lab var CSOK_`BW' "CSOK indicator, bandwidth = `BW'"
}


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

ren tazon ksh4
ren ev ty

order ksh4 ty jaras mkod rkod CSOK_0 CSOK_2 CSOK_3 CSOK_4 CSOK_5

save "${temp}/tstar_important", replace




