clear
cls
* locals
local homePath "\\apporto.com\dfs\NTHW\Users\tas2998_nthw\Desktop\Hungary"  
* log
log close _all
log using "`homePath'\log\createPanelVars.log", replace  

* load data
use "`homePath'\data\mid\censusPanel_raw.dta", replace

* variable for any birth, twins or otherwise
gen bDum = b>0
replace bDum = bDum*100
order id date b bDum

* data housekeeping
* xtset id date

* sample: unbalanced panel of women 15-44
keep if (date>=2008 & date<=2021) // start 2008, end 2021 bc 10/01/22 cutoff
keep if neme==2 // women only
gen age = date - szev
keep if (age>=15 & age<=49) // for now, keep women 45-49 to match Gyozo

********************************************************************************
* AGE: generate age variable (and age squared)
gen age2 = age^2
* generate categorical version
gen ageCatg = 0
replace ageCatg = 1 if (age>=15 & age<=19)
replace ageCatg = 2 if (age>=20 & age<=24)
replace ageCatg = 3 if (age>=25 & age<=29)
replace ageCatg = 4 if (age>=30 & age<=34)
replace ageCatg = 5 if (age>=35 & age<=39)
replace ageCatg = 6 if (age>=40 & age<=44)

* # OF KIDS: generate number of kids variables, counting twins, etc. via b>1
bysort id (date): gen kids = sum(b)
* do NOT count contemporaneous births
replace kids = kids - b
* generate categorical version
gen kidCatg = 0
replace kidCatg = 1 if (kids==0)
replace kidCatg = 2 if (kids==1)
replace kidCatg = 3 if (kids==2)
replace kidCatg = 4 if (kids>=3)
* gen 2019 dummy 
gen kidsBy2019 = kids if date==2019
gen momby2019init = 0
replace momby2019init = (kidsBy2019!=. & kidsBy2019>0)
egen momBy2019 = max(momby2019init), by(id)
drop kidsBy2019 momby2019init

** detour **********************************************************************
* save data for aggregate Gyozo checks
preserve
by id date, sort: gen womenThatYear = (_n==1)
gen average_age = age if b>0
gen average_age_first = age if (b>0 & kids==0)
collapse (sum) b womenThatYear (mean) average_age average_age_first, by(date)
rename b live_birth_all
gen bPer1Kw = 1000 * (live_birth_all / womenThatYear)	
* to fix 10% sample for comparability
replace live_birth_all = 10*live_birth_all
* to avoid dealing with decimals converting to dates in Excel
replace average_age = 100 * average_age
replace average_age_first = 100 * average_age_first	
export excel "`homePath'\data\summs\GyozoChecks.xlsx", firstrow(variables) replace
restore
********************************************************************************
keep if (age>=15 & age<=44) // drop women 44-49 here
********************************************************************************

* MARITAL STATUS
gen married = (cspot==2 & date>hazev)
* gen 2019 dummy
gen marriedBy2019 = (cspot==2 & hazev<2019)

* ETHNICITY: binary variable for Hungarian ethnicities
gen hungarian = (enemzv>=100 & enemzv<200)

* RELIGION
* base case (=0) is no response + others not listed here
gen relCatg = 0 
* Catholic
replace relCatg = 1 if inlist(vallasv,100,111,200,300,311,400,410,420,440,480,510,530)
* Calvinist
replace relCatg = 2 if inlist(vallasv,1100,1101,1110,1111,1181)
* Lutheran
replace relCatg = 3 if inlist(vallasv,1200,1210,1211,1220)
* None
replace relCatg = 4 if inlist(vallasv,0,50,51)
** create binary version
gen relXn = inlist(relCatg,1,2,3)

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
** create binary version
gen eduHigh = inlist(irelsz,5,6,7,8,9,10)
** generate interaction with age
egen eduAgeInt = group(eduCatg ageCatg) 

* EMPLOYMENT STATUS
* base case includes receiving payments, dependents, etc.
gen empCatg = 0
* employed
replace empCatg = 1 if inlist(gakt,11,12,13,14)
* unemployed
replace empCatg = 2 if inlist(gakt,21,22,23,24)
* full-time student
replace empCatg = 3 if inlist(gakt,43)
* child payments or homemaker
replace empCatg = 4 if inlist(gakt,31,44)
** create binary version
gen empHome = inlist(gakt,31,44)
** generate interaction with age
egen empAgeInt = group(empCatg ageCatg) 

* HOME OWNERSHIP
gen owner = (jc==1)

* LOCATION
* EXTRA: merge in names of settlements
merge m:1 terul using "`homePath'\data\mid\settlementNamesTrim.dta"
* everything in the micro-data found a match, but 60-70ish settlements from data dictionary did not find a match--for now, save a list of these settlements
preserve
keep if _merge==2
keep terul name 
sort name
export excel "`homePath'\data\mid\missing_basedOnNames.xlsx", firstrow(variables) replace
restore
* move on for now, dropping settlement names that are not in micro-data
drop if _merge==2
drop _merge

* trim the last digit from the HCSO settlement ID, to mimic the T-STAR settlement ID
rename terul terul_long
tostring(terul_long), gen(terul_long_string)
gen terul_long_string_length = strlen(terul_long_string)
gen terul_string = substr(terul_long_string,1,4)
replace terul_string = substr(terul_long_string,1,3) if terul_long_string_length==4
destring terul_string, generate(terul)
drop terul_long_string terul_string
* T-STAR combines 23 Budapest units into 1 (terul number of 1357), so mimic that here
gen budapest = strpos(name,"Budapest") 
replace terul = 1357 if budapest==1

* bring in settlement dummies from Gyozo
merge m:1 terul using "`homePath'\data\mid\settlementDummies.dta"
drop if _merge==2
drop _merge
* 3 categories for settlement: budapest on its own, then 5K cutoff
gen locType = 0
replace locType = 1 if inlist(settlement_type,1)
replace locType = 2 if inlist(settlement_type,2,3,4,5)
replace locType = 3 if inlist(settlement_type,6,7,8)
* drop obs whose settlement is missing its type (just two: 24703, 34412)
drop if settlement_type==.
tab locType

* create interaction of county and location type 
egen countyTypeInt = group(varmegye locType)

* save data
save "`homePath'\data\mid\censusPanel_vars.dta", replace