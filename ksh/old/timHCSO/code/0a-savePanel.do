clear
cls
* locals
local homePath "\\apporto.com\dfs\NTHW\Users\tas2998_nthw\Desktop\Hungary" 
* log
log close _all
log using "`homePath'\log\createPanel.log", replace  

* load data
use "`homePath'\data\raw\personal_2022_10% sample.dta", replace

* define sample period
local firstY 1978 //to have accurate #kids count: 2008-(44-14)
local lastY 2022 //really, 2021 (trimmed in next file)

* read in data
destring *, replace
rename szemazon id

* generate long version's variables
local yearsList `firstY':`lastY'
local monthsList 1-12
* loop over year-months
forvalues yy = `firstY'/`lastY' {
* forvalues mm = 1/12 {

	* gen b`yy'`mm' = 0
	gen b`yy' = 0

* }
}

* get list of year-month variables for each successive birth
local birthYVars "elszev maszev haszev neszev otszev szev6 szev7 szev8 szev9 uszev"
* local birthYVars "ELSZEV MASZEV HASZEV NESZEV OTSZEV SZEV6 SZEV7 SZEV8 SZEV9 USZEV"
local birthMVars "elszho maszho haszho neszho otszho ho6 ho7 ho8 ho9 uszho"
* local birthMVars "ELSZHO MASZHO HASZHO NESZHO OTSZHO HO6 HO7 HO8 HO9 USZHO"

local numBirthVars: word count `birthYVars'
* loop over year-months looking for birth dates
forvalues yy = `firstY'/`lastY' {
* forvalues mm = 1/12 {
forvalues i = 1/`numBirthVars' {
	local birthY: word `i' of `birthYVars'
	local birthM: word `i' of `birthMVars'
	* does this i-th birth happen in yy-mm--now just yy?
	* replace b`yy'`mm' = 1 if (`birthY'==`yy' & `birthM'==`mm')	
	replace b`yy' = b`yy' + 1 if `birthY'==`yy' //will equal 2 for twins
}	
* }
}

* reshape from wide to long
reshape long b, i(id) j(date)
* generate date variable
* tostring(date), generate(dateStr)
* gen y = substr(dateStr,1,4)
* gen m = substr(dateStr,5,.)
* destring(y), replace
* destring(m), replace
* gen date2 = ym(y,m)
* format date2 %tm
* drop date dateStr y m 
* rename date2 date
order id date b

* save data
save "`homePath'\data\mid\censusPanel_raw.dta", replace