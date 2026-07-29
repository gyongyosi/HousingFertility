cls
clear

* define which bandwidth (seems robust, though)
local bw 0000_10000

* load data
use "${temp}/census_002_unbal_filled_moreTSTAR", clear
* restrict to relevant bandwidth
keep if P_CSOK_`bw'!=.

* CHOOSE: flag births of the relevant parity slice (change excel label too!)
* gen paritySlice = N_childrenNEW==1 //all births
* gen paritySlice = (N_childrenNEW==1 & C_childrenNEW==1) //1st births
* gen paritySlice = (N_childrenNEW==1 & C_childrenNEW==2) //2nd births
gen paritySlice = (N_childrenNEW==1 & C_childrenNEW>=3) //3rd births

* construct year of birth variable
gen yearOfBirth = ty if paritySlice==1
* construct moms age at birth variable
gen momAgeAtBirth = (yearOfBirth - ty_mother_birth) if paritySlice==1

* count by eligility, pre/post, and maternal age
collapse (count) yearOfBirth, by(P_CSOK_`bw' post momAgeAtBirth)
rename yearOfBirth count
drop if momAgeAtBirth==.

* get totals within eligibility-post
egen g = group(P_CSOK_`bw' post)
egen total=total(count), by(g)
* get cumulative sum across mom births
bysort g (momAgeAtBirth): gen cumul = sum(count)
* compute CDF
gen share = 100*(cumul / total)
* clean out
export excel "${output}/maternalAge_TOT_3rd.xlsx",  firstrow(variables) replace
drop count total cumul P_CSOK_`bw' post
* reshape
reshape wide share, i(momAgeAtBirth) j(g)

* no diffs
line share1 share2 share3 share4 momAgeAtBirth, ///
	legend(order(1 "Control: Pre" 2 "Control: Post" 3 "Treated: Pre" 4 "Treated: Post"))
graph export "${output}/maternalAge_cdfs_TOT_3rd.pdf", as(pdf) replace

* one diff
gen diff_pre = share3 - share1
gen diff_post = share4 - share2 
line diff_pre diff_post momAgeAtBirth, legend(order(1 "Diff: Pre" 2 "Diff: Post"))
graph export "${output}/maternalAge_diff_TOT_3rd.pdf", as(pdf) replace


/**
****************************************************************************
* compute average maternal age at birth, broken out by treatment + year
collapse (mean) momAgeAtBirth, by(P_CSOK_`bw' yearOfBirth)
* compute yearly difference between treatment and control
reshape wide momAgeAtBirth, i(yearOfBirth) j(P_CSOK_`bw')
gen diff = momAgeAtBirth1 - momAgeAtBirth0

* rescale diff to be zero in 2019
gen diff0_tmp = diff if year==2019
egen diff0 = max(diff0_tmp)
drop diff0_tmp
replace diff = diff - diff0
drop if year==.
* plot
scatter diff year 

* all: increase, tho big pre-trend
* 1st births: inconclusive
* 2nd births: increases
* 3rd+ births: increases
****************************************************************************
* compute average maternal age at birth, broken out by treatment + year
collapse (mean) momAgeAtBirth, by(P_CSOK_0000_`bw' yearOfBirth)
* compute yearly difference between treatment and control
reshape wide momAgeAtBirth, i(yearOfBirth) j(P_CSOK_0000_`bw')
gen diff = momAgeAtBirth1 - momAgeAtBirth0

* rescale diff to be zero in 2019
gen diff0_tmp = diff if year==2019
egen diff0 = max(diff0_tmp)
drop diff0_tmp
replace diff = diff - diff0
drop if year==.
* plot
scatter diff year // post-2019 decrease consistent w/ tempo

* all: increase, tho big pre-trend and tails off at end a bit
* 1st births: inconclusive
* 2nd births: increases
* 3rd+ births: increases