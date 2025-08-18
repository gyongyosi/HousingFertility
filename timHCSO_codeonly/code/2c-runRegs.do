clear
cls
* locals
local homePath "X:\Kimeno\kutato29\Output1\Working_files" 
* log
log close _all
log using "`homePath'\log\runRegs.log", replace  
display c(current_time)

* load data
use "`homePath'\data\mid\censusPanel_vars.dta", replace

/**
** movers analysis
* have you ever moved? 88% have
tab lakev_x
* cross-tab year of move (if never move it is birthday)
tab lakev_x lakev
* cross-tab month of move
tab lakev_x lakho

* look at people who move settlements
gen ldMover = (lakev_x==1) & (eterul!=.) & (terul_long != eterul)
* a little over half of all movers are cross-settlement movers
tab lakev_x ldMover
* look at people who move settlements since 2020
gen ldMover_recent = (lakev_x==1) & (eterul!=.) & (terul_long != eterul) & (lakev>=2020)
* less than 20% of all movers are recent cross-settlement movers
tab lakev_x ldMover_recent
* so overall, about 14% of my sample are recent cross-settlement movers
drop if ldMover_recent

** temporary random sample

sort id date
by id (date): gen test = (_n ==1)
gen rnd = runiformint(1,1000) if test==1
egen rndMax = max(rnd), by(id)
keep if rndMax==1
**/

** definitions *************************************
* define control variables
local numModels 5
local baseVars i.ageCatg i.momBy2019 i.eduCatg i.empCatg hungarian i.relCatg i.owner
local ver2 i.eduCatg#i.ageCatg i.empCatg#i.ageCatg
local ver3 i.small19##i.post##i.ageCatg
local ver4 i.small19##i.post##momBy2019
local ver5 `ver2' `ver3'
* define clustering variable
local clusterVar terul
* post in time
gen post = (date >= 2019)


* loop over rectangular bandwidths 
local labels "1 2 3 4 5 6 7"
local lbList "4000 3000 2000 1000 0 1000 0"
local ubList "6000 7000 8000 9000 10000 10000 20000"
local nn : word count `labels'

forvalues ii = 1/`nn' {

local lb : word `ii' of `lbList'
local ub : word `ii' of `ubList'
local label : word `ii' of `labels'

display `lb'
display `ub'

preserve

* narrow the settlement type here
keep if (pop19>=`lb' & pop19<=`ub')

histogram(pop19Norm)
graph export "`homePath'\fig\popDist_`label'.png", width(1000) height(500) replace

* baseline with imple (no interaction)
reg bDum i.small19##i.post c.pop19Norm `baseVars' i.date i.terul, vce(cluster `clusterVar')
* save coefficients
outreg2 using "`homePath'\tab\LPMsimple_`label'.xls", replace drop(i.terul) label ctitle(Model 1) title(LPM)
* additional specifications
forvalues ii = 2(1)`numModels' {
	* run regression
	reg bDum i.small19##i.post c.pop19Norm `baseVars' i.date i.terul `ver`ii'', vce(cluster `clusterVar')
	* save coefficients
	outreg2 using "`homePath'\tab\LPMsimple_`label'.xls", append drop(i.terul) label ctitle(Model `ii')
}

* baseline dynamic 
reg bDum ib(2019).date##i.small19 c.pop19Norm `baseVars' i.terul, vce(cluster `clusterVar')
outreg2 using "`homePath'\tab\LPMsimple_`label'.xls", append drop(i.terul) label ctitle(Model 6)


* baseline with interaction static
reg bDum i.small19##i.post c.pop19Norm i.small19#c.pop19Norm i.post#c.pop19Norm i.small19#i.post#c.pop19Norm `baseVars' i.date i.terul, vce(cluster `clusterVar')
* save coefficients
outreg2 using "`homePath'\tab\LPMinteract_`label'.xls", replace drop(i.terul) label ctitle(Model 1) title(LPM)
* additional specifications
forvalues ii = 2(1)`numModels' {
	* run regression
	reg bDum i.small19##i.post c.pop19Norm i.small19#c.pop19Norm i.post#c.pop19Norm i.small19#i.post#c.pop19Norm `baseVars' i.date i.terul `ver`ii'', vce(cluster `clusterVar')
	* save coefficients
	outreg2 using "`homePath'\tab\LPMinteract_`label'.xls", append drop(i.terul) label ctitle(Model `ii')
}

* interaction dynamic 
reg bDum ib(2019).date##i.small19 c.pop19Norm i.small19#c.pop19Norm ib(2019).date#c.pop19Norm i.small19#ib(2019).date#c.pop19Norm `baseVars' i.terul, vce(cluster `clusterVar')
outreg2 using "`homePath'\tab\LPMinteract_`label'.xls", append drop(i.terul) label ctitle(Model 6)

restore
}

display c(current_time)