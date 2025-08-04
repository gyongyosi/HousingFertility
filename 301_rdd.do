

/*==============================================================================
	map of village CSOK eligible settlements
==============================================================================*/

use ${temp}/tstar_03, clear

keep if ty == 2018

maptile village_csok, geo(ksh4) cutv(0.5) rangecolor("$color1" "$color2")

graph export ${output}/map_village_csok.pdf, as(pdf) replace



/*==============================================================================
	what is the running variable?
		population in 2018
		change in population (2003-2018)
==============================================================================*/

use ${temp}/tstar_03, clear


keep if ty == 2018


* 1) population in 2018 
binscatter village_csok de01_2018 if inrange(de01_2018, . , 10000), nq(50)
binscatter village_csok de01_2018 if inrange(de01_2018, 4000 , 6000), nq(50)

* 2) population change (percent)
binscatter village_csok pop_change_percent , nq(50)
binscatter village_csok pop_change_percent if inrange(pop_change_percent, -0.2, 0.2), nq(50)

* 3) how strong is the first stage? 
* strong, level is somewhat better than the change

gen I_pop2018 = (de01_2018<5000)
gen I_popchange = (pop_change_percent < 0)

reghdfe village_csok I_pop2018, noabsorb
reghdfe village_csok I_pop2018 [aw = de01_2018], noabsorb 

reghdfe village_csok I_popchange, noabsorb
reghdfe village_csok I_popchange [aw = de01_2018], noabsorb 

reghdfe village_csok I_pop2018 I_popchange, noabsorb
reghdfe village_csok I_pop2018 I_popchange [aw = de01_2018], noabsorb 



/*==============================================================================
	McCrary test
==============================================================================*/


use ${temp}/tstar_03, clear

keep if ty == 2018

rddensity  de01_2018 , c(5000) plot
graph export ${output}/manipulation_level.pdf, as(pdf) replace


rddensity  pop_change_percent , c(0) plot
graph export ${output}/manipulation_change.pdf, as(pdf) replace



/*==============================================================================
	calculate optimal bandwith
==============================================================================*/

use ${temp}/tstar_03, clear

keep if ty == 2018
drop if ksh4 == 1357

rdbwselect SH_t_1 de01_2018, c(5000) weights(de01_2018)

global H_level = `e(h_mserd)'
global B_level = `e(b_mserd)' 

rdbwselect village_csok pop_change_percent, c(0) weights(de01_2018)


global H_change = `e(h_mserd)'
global B_change = `e(b_mserd)'


/*==============================================================================
	create balance figures (level)
==============================================================================*/

use ${temp}/tstar_03, clear

keep if ty == 2018
keep if inrange(de01_2018, 0, 10000)

local bin_size = 100
local weight = de01_2018
local vars_to_use "SH_t_1 SH_t_2 SH_t_3 SH_t_4 ln_income komplex_2014 village_csok sh_homeownership_b fertility U_rate ln_hp transaction_per_pop"

gen de01_2018_bin = floor(de01_2018 / `bin_size') * `bin_size'

tempfile orig 
save `orig'


collapse (mean)  `vars_to_use' [aweight = `weight'], by(de01_2018_bin)

foreach X of varlist `vars_to_use' {
	ren `X' `X'_bin
}

tempfile collapsed
save `collapsed'



use `orig', clear
merge m:1 de01_2018_bin using `collapsed', nogen keep(1 3)



foreach OUTCOME of varlist `vars_to_use' {

	local label : variable label `OUTCOME'


	#d ;
	twoway 	(lpolyci `OUTCOME' de01_2018_bin if de01_2018 < 5000 [aw = `weight'], degree(5) lcolor("$color1")) 
		(lpolyci `OUTCOME' de01_2018_bin if de01_2018 >= 5000 [aw = `weight'], degree(5) lcolor("$color2")) 
		(scatter `OUTCOME'_bin de01_2018_bin if de01_2018 < 5000, mcolor("$color1") ) 
		(scatter `OUTCOME'_bin de01_2018_bin if de01_2018 >= 5000, mcolor("$color2") ), 
			graphregion(color(white)) 
			xtitle("Population") ytitle("`label'") 
			legend(off)
		;
	#d cr
	graph export ${output}/rdd_pop_level_`OUTCOME'.pdf, as(pdf) replace

}




/*==============================================================================
	create balance figures (change)
	
==============================================================================*/


use ${temp}/tstar_03, clear

keep if ty == 2018
keep if inrange(pop_change_percent, -0.5, 0.5)

local bin_size = 0.01
local weight = de01_2018
local vars_to_use "SH_t_1 SH_t_2 SH_t_3 SH_t_4 ln_income komplex_2014 village_csok sh_homeownership_b fertility U_rate ln_hp transaction_per_pop"

gen pop_change_percent_bin = floor(pop_change_percent / `bin_size') * `bin_size'

tempfile orig 
save `orig'


collapse (mean)  `vars_to_use' [aweight = `weight'], by(pop_change_percent_bin)

foreach X of varlist `vars_to_use' {
	ren `X' `X'_bin
}

tempfile collapsed
save `collapsed'



use `orig', clear
merge m:1 pop_change_percent_bin using `collapsed', nogen keep(1 3)



foreach OUTCOME of varlist `vars_to_use' {

	local label : variable label `OUTCOME'


	#d ;
	twoway 	(lpolyci `OUTCOME' pop_change_percent_bin if pop_change_percent < 0 [aw = `weight'], degree(1) lcolor("$color1")) 
		(lpolyci `OUTCOME' pop_change_percent_bin if pop_change_percent >= 0 [aw = `weight'], degree(1) lcolor("$color2")) 
		(scatter `OUTCOME'_bin pop_change_percent_bin if pop_change_percent < 0, mcolor("$color1") ) 
		(scatter `OUTCOME'_bin pop_change_percent_bin if pop_change_percent >= 0, mcolor("$color2") ), 
			graphregion(color(white)) 
			xtitle("Population change") ytitle("`label'") 
			legend(off)
		;
	#d cr
	graph export ${output}/rdd_pop_change_`OUTCOME'.pdf, as(pdf) replace

}


/*==============================================================================
	create balance table (level)
==============================================================================*/

use ${temp}/tstar_03, clear

keep if ty == 2018
keep if inrange(de01_2018, 0, 10000)

eststo clear
eststo q_1 : rdrobust SH_t_1 de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_2 : rdrobust SH_t_2 de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_3 : rdrobust SH_t_3 de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_4 : rdrobust SH_t_4 de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_5 : rdrobust ln_income de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_6 : rdrobust U_rate de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_7 : rdrobust sh_homeownership_b de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_8 : rdrobust ln_hp de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_9 : rdrobust transaction_per_po de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)
eststo q_10 : rdrobust fertility de01_2018, c(5000) all weights(de01_2018) h($H_level) b($B_level)



/*==============================================================================
	create balance table (change)
==============================================================================*/

use ${temp}/tstar_03, clear

keep if ty == 2018

eststo clear
eststo q_1 : rdrobust SH_t_1 pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_2 : rdrobust SH_t_2 pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_3 : rdrobust SH_t_3 pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_4 : rdrobust SH_t_4 pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_5 : rdrobust ln_income pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_6 : rdrobust U_rate pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_7 : rdrobust sh_homeownership_b pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_8 : rdrobust ln_hp pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_9 : rdrobust transaction_per_po pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)
eststo q_10 : rdrobust fertility pop_change_percent, c(0) all weights(de01_2018) h($H_change) b($B_change)




/*==============================================================================
	average house price in TREATED vs CONTROL settlements (within BW, level)
==============================================================================*/

use ${temp}/tstar_03, clear

local lower = 5000 - $H_level
local upper = 5000 + $H_level

keep if inrange(de01_2018, `lower', `upper')
gen TREAT = (de01_2018 < 5000)

collapse (mean) ln_hp total_price [aw = total_transaction], by(TREAT ty)
ren ln_hp ln_hp_
ren total_price total_price_
reshape wide ln_hp_ total_price_, i(ty) j(TREAT)

#d ;
	twoway connected ln_hp_1 ln_hp_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average log house price")
		;
#d cr



#d ;
	twoway connected total_price_1 total_price_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average house price")
		;
#d cr



/*==============================================================================
	average house price in TREATED vs CONTROL settlements (within BW, change)
==============================================================================*/

use ${temp}/tstar_03, clear

local lower = 0 - $H_change
local upper = 0 + $H_change

keep if inrange(pop_change_percent, `lower', `upper')
gen TREAT = (pop_change_percent < 0)

collapse (mean) ln_hp total_price [aw = total_transaction], by(TREAT ty)
ren ln_hp ln_hp_
ren total_price total_price_
reshape wide ln_hp_ total_price_, i(ty) j(TREAT)

#d ;
	twoway connected ln_hp_1 ln_hp_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average log house price")
		;
#d cr



#d ;
	twoway connected total_price_1 total_price_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average house price")
		;
#d cr






/*==============================================================================
	number of transactions in TREATED vs CONTROL settlements (within BW, level)
==============================================================================*/

use ${temp}/tstar_03, clear

keep if inrange(ty, 2015, .)

local lower = 5000 - $H_level
local upper = 5000 + $H_level

keep if inrange(de01_2018, `lower', `upper')
gen TREAT = (de01_2018 < 5000)

collapse (mean) transaction_per_pop [aw = de01], by(TREAT ty)
ren transaction_per_pop transaction_per_pop_
reshape wide transaction_per_pop_, i(ty) j(TREAT)

#d ;
	twoway connected transaction_per_pop_1 transaction_per_pop_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Number of transactions relative to population")
		;
#d cr





/*==============================================================================
	number of transactions in TREATED vs CONTROL settlements (within BW, change)
==============================================================================*/


use ${temp}/tstar_03, clear

keep if inrange(ty, 2015, .)


local lower = 0 - $H_change
local upper = 0 + $H_change

keep if inrange(pop_change_percent, `lower', `upper')
gen TREAT = (pop_change_percent < 0)


collapse (mean) transaction_per_pop [aw = de01], by(TREAT ty)
ren transaction_per_pop transaction_per_pop_
reshape wide transaction_per_pop_, i(ty) j(TREAT)

#d ;
	twoway connected transaction_per_pop_1 transaction_per_pop_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Number of transactions relative to population")
		;
#d cr




/*==============================================================================
	average births per women (15-49) in TREATED vs CONTROL settlements (within BW, level)
==============================================================================*/

use ${temp}/tstar_03, clear

local lower = 5000 - $H_level
local upper = 5000 + $H_level

keep if inrange(de01_2018, `lower', `upper')
gen TREAT = (de01_2018 < 5000)

collapse (mean) fertility [aw = women_childbearing_age], by(TREAT ty)
ren fertility fertility_
reshape wide fertility_ , i(ty) j(TREAT)

#d ;
	twoway connected fertility_1 fertility_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average number of births per women aged 15-49")
		;
#d cr



/*==============================================================================
	average births per women (15-49) in TREATED vs CONTROL settlements (within BW, change)
==============================================================================*/

use ${temp}/tstar_03, clear

local lower = 0 - $H_change
local upper = 0 + $H_change

keep if inrange(pop_change_percent, `lower', `upper')
gen TREAT = (pop_change_percent < 0)


collapse (mean) fertility [aw = women_childbearing_age], by(TREAT ty)
ren fertility fertility_
reshape wide fertility_ , i(ty) j(TREAT)

#d ;
	twoway connected fertility_1 fertility_0 ty, 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Average number of births per women aged 15-49")
		;
#d cr






/*==============================================================================
	average economic conditions in TREATED vs CONTROL settlements (within BW, level)
==============================================================================*/


* 1) unemployment

use ${temp}/tstar_03, clear

local lower = 5000 - $H_level
local upper = 5000 + $H_level

keep if inrange(de01_2018, `lower', `upper')
gen TREAT = (de01_2018 < 5000)



collapse (mean) U_rate [aw = de09], by(TREAT ty)
ren U_rate U_rate_
reshape wide U_rate_, i(ty) j(TREAT)


#d ;
	twoway connected U_rate_1 U_rate_0 ty , 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Unemployment rate")
		;
#d cr


* 2) log income
use ${temp}/tstar_03, clear

keep if inrange(ty, 2008, .)

local lower = 5000 - $H_level
local upper = 5000 + $H_level

keep if inrange(de01_2018, `lower', `upper')
gen TREAT = (de01_2018 < 5000)



collapse (mean) ln_income [aw = de01], by(TREAT ty)
ren ln_income ln_income_
reshape wide ln_income_, i(ty) j(TREAT)


#d ;
	twoway connected ln_income_1 ln_income_0 ty , 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Log income per capita")
		;
#d cr






/*==============================================================================
	average economic conditions in TREATED vs CONTROL settlements (within BW, change)
==============================================================================*/


* 1) unemployment

use ${temp}/tstar_03, clear

keep if inrange(ty, 2008, .)

local lower = 0 - $H_change
local upper = 0 + $H_change

keep if inrange(pop_change_percent, `lower', `upper')
gen TREAT = (pop_change_percent < 0)

collapse (mean) U_rate [aw = de09], by(TREAT ty)
ren U_rate U_rate_
reshape wide U_rate_, i(ty) j(TREAT)


#d ;
	twoway connected U_rate_1 U_rate_0 ty , 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Unemployment rate")
		;
#d cr


* 2) log income
use ${temp}/tstar_03, clear

keep if inrange(ty, 2008, .)

local lower = 0 - $H_change
local upper = 0 + $H_change

keep if inrange(pop_change_percent, `lower', `upper')
gen TREAT = (pop_change_percent < 0)

collapse (mean) ln_income [aw = de01], by(TREAT ty)
ren ln_income ln_income_
reshape wide ln_income_, i(ty) j(TREAT)


#d ;
	twoway connected ln_income_1 ln_income_0 ty , 
		legend(order(1 "Treated" 2 "Control"))
		graphregion(color(white))
		lpattern(solid _)
		lcolor("$color1" "$color2")
		mcolor("$color1" "$color2")
		xtitle("")
		ytitle("Log income per capita")
		;
#d cr













/*==============================================================================
	some regression
==============================================================================*/

global X1_post "c.SH_t_1##i.POST c.SH_t_2##i.POST c.SH_t_3##i.POST c.SH_t_4##i.POST "
global X3_post "i.kist175##i.POST"

global X1_ty "c.SH_t_1##i.ty c.SH_t_2##i.ty c.SH_t_3##i.ty c.SH_t_4##i.ty "
global X3_ty "i.kist175##i.ty"


use ${temp}/tstar_03, clear

eststo clear

eststo q_1 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty)

eststo q_2 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty $X1_post )

eststo q_3 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty $X1_post $X3_post)


eststo q_4 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000), absorb(ksh4 ty)

eststo q_5 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000), absorb(ksh4 ty $X1_post )

eststo q_6 : reghdfe fertility i.village_csok##i.POST [aw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000) , absorb(ksh4 ty $X1_post $X3_post)

esttab



use ${temp}/tstar_03, clear

eststo clear

eststo q_1 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty)

eststo q_2 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty $X1_post )

eststo q_3 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty $X1_post $X3_post)


eststo q_4 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000), absorb(ksh4 ty)

eststo q_5 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000), absorb(ksh4 ty $X1_post )

eststo q_6 : ppmlhdfe de55 i.village_csok##i.POST [pw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 3000, 7000) , absorb(ksh4 ty $X1_post $X3_post)

esttab



use ${temp}/tstar_03, clear

ppmlhdfe de55 i.village_csok##ib2018.ty [pw = de01] if inrange(ty, 2015, .), absorb(ksh4 ty $X1_ty )

ppmlhdfe de55 i.village_csok##ib2018.ty [pw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 2000, 8000), absorb(ksh4 ty $X1_ty )

reghdfe fertility i.village_csok##ib2018.ty [pw = de01] if inrange(ty, 2015, .) & inrange(de01_2018, 2000, 8000), absorb(ksh4 ty $X1_ty )



rdrobust fertility de01_2018 if ty == 2017, c(5000) all

rdrobust fertility de01_2018 if ty == 2018, c(5000) all

rdrobust fertility de01_2018 if ty == 2019, c(5000) all

rdrobust fertility de01_2018 if ty == 2020, c(5000) all
