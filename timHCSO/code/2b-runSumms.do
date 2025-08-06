clear
cls
* locals
local homePath "\\apporto.com\dfs\NTHW\Users\tas2998_nthw\Desktop\Hungary" 
* log
log close _all
log using "`homePath'\log\runSumms.log", replace  

* load data
use "`homePath'\data\mid\censusPanel_vars.dta", replace


** overall aggregates **********************************************************

preserve
* within age-year: compute total births, total women, and births/woman
collapse (sum) births=bDum (count) women=bDum (mean) rate=bDum, by(ageCatg date)
* replace births = births / 100
* replace rate = rate / 100
* within year: compute births, women, and naive births/woman
egen birthsYearly = total(births), by(date)
egen womenYearly = total(women), by(date)
gen rateYearly = birthsYearly / womenYearly
* with year: compute TFR
egen summation = total(rate), by(date) //sum to simulate life cycle
gen tfr = 5 * (summation) / 100 // multiply by width of age bins
* collapse to yearly
collapse (mean) birthsYearly womenYearly rateYearly tfr, by(date)
* save data
export excel "`homePath'\data\summs\trends.xlsx", firstrow(variables) replace
* save rate graph
twoway connected rateYearly date
graph export "`homePath'\fig\summs\rate.png", width(1000) height(500) replace
* save tfr graph
twoway connected tfr date
graph export "`homePath'\fig\summs\tfr.png", width(1000) height(500) replace
* restore
restore

** 1-var breakdowns ************************************************************

local splitVars ageCatg kidCatg momBy2019 married marriedBy2019 eduCatg eduHigh eduAgeInt empCatg empHome empAgeInt hungarian relCatg relXn owner varmegye locType countyTypeInt  
foreach splitVar in `splitVars' {

preserve
* compute rate and count by var-age-year
collapse (sum) births=bDum (count) women=bDum (mean) rate=bDum, by(`splitVar' ageCatg date)
* replace births = births / 100
* replace rate = rate / 100
* within var-year: compute births, women, and naive births/woman
egen birthsYearly = total(births), by(`splitVar' date)
egen womenYearly = total(women), by(`splitVar' date)
gen rateYearly = birthsYearly / womenYearly
* within var-year: compute TFR
egen summation = total(rate), by(`splitVar' date) //sum to simulate life cycle
gen tfr = 5 * (summation) / 100 // multiply by width of age bins
* collapse: delete age-specific births, women, and summation 
collapse (mean) birthsYearly womenYearly rateYearly tfr, by(`splitVar' date)

* save data
reshape wide birthsYearly womenYearly rateYearly tfr, i(date) j(`splitVar')
export excel "`homePath'\data\summs\trends`splitVar'.xlsx", firstrow(variables) replace
* save tfr graph
twoway connected tfr* date, legend(size(medsmall))	msymbol(circle)
graph export "`homePath'\fig\summs\tfrBy`splitVar'.png", width(1000) height(500) replace
* save rate graph
twoway connected rateYearly* date, legend(size(medsmall))	msymbol(circle)
graph export "`homePath'\fig\summs\rateBy`splitVar'.png", width(1000) height(500) replace
* save count graph
twoway connected womenYearly* date, legend(size(medsmall)) msymbol(circle)
graph export "`homePath'\fig\summs\nBy`splitVar'.png", width(1000) height(500) replace
* restore
restore
}

** cell-based breakdown: settlement-CSOK-age *********************************** 

* within districts, combine small settlements with same csok status  
gen jarasNeg = -1*jaras
replace terul = jarasNeg if inlist(settlement_type,6,7,8)

* compute births and women by each cell where...
* ... cell = settlement, its CSOK status, age category for TFR, and year
collapse (sum) births=bDum (count) women=bDum, by(terul village_csok ageCatg date)

* combine sparse cells
gen sparseObs = women < 3
* combine any settlement that ever has a sparse cell
egen sparseStl = max(sparseObs), by(terul)
* define new variable for the combined terul code
gen comboTerul = terul
* combine settlements here
replace comboTerul = -999.5 if sparseStl==1
* collapse using newly defined combo settlement code
collapse (sum) births women, by(comboTerul village_csok ageCatg date)

* within cell: compute yearly rate of births per woman
gen rate = (births / women)
* within settlement-CSOK-year (across age categories): compute TFR
egen summation = total(rate), by(comboTerul village_csok date) 
* after summing to simulate life cycle, multiply by width of age bins
gen tfr = 5 * (summation) / 100

* clean data
drop summation
order comboTerul village_csok ageCatg date births women rate tfr 
sort comboTerul village_csok ageCatg date
* save data
export excel "`homePath'\data\summs\trendsCell_Settlement.xlsx", firstrow(variables) replace

/**
** cell-based breakdown: others ************************************************ 
* 2,880x14yrs!
local cellList ageCatg married momBy2015 eduCatg locType village_csok 

replace married = -99 if ageCatg==1
replace momBy2015 = -99 if ageCatg==1
replace momBy2015 = -99 if ageCatg==2

egen cell = group(`cellList')

* compute rate and count by var-age-year
collapse (firstnm) `cellList' (sum) births=bDum (count) women=bDum (mean) rate=bDum, by(cell date)
* within cell-year: compute births, women, and naive births/woman
egen birthsYearly = total(births), by(cell date)
egen womenYearly = total(women), by(cell date)
gen rateYearly = birthsYearly / womenYearly
* within var-year: compute TFR
egen summation = total(rate), by(cell date) //sum to simulate life cycle
gen tfr = 5 * (summation) / 100 // multiply by width of age bins

* combine sparse cells
gen sparseObs = women < 3
* combine any settlement that ever has a sparse cell
egen sparseStl = max(sparseObs), by(cell)