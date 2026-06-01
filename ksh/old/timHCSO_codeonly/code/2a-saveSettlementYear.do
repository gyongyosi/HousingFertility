clear
cls
* locals
local homePath "X:\Kimeno\kutato29\Output1\Working_files" 
* log
log close _all
log using "`homePath'\log\getSettlementYear.log", replace  

* load micro-data
use "`homePath'\data\mid\censusPanel_vars.dta", replace

* T-STAR is settlement-level within year, so mimic that here
local splitVar terul

* by settlement-age-year: compute rate and count
collapse (firstnm) name (sum) births=bDum (count) women=bDum (mean) rate=bDum, by(`splitVar' ageCatg date)
* within settlement-year: compute births, women, and naive births/woman
egen birthsYearly = total(births), by(`splitVar' date)
egen womenYearly = total(women), by(`splitVar' date)
gen rateYearly = birthsYearly / womenYearly
* within settlement-year: compute TFR
egen summation = total(rate), by(`splitVar' date) //sum to simulate life cycle
gen tfr = 5 * (summation) / 100 // multiply by width of age bins
* collapse: delete age-specific births, women, and summation 
collapse (firstnm) name (mean) birthsYearly womenYearly rateYearly tfr, by(`splitVar' date)

save "`homePath'\data\mid\settlmentYearFertility.dta", replace