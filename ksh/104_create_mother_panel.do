
/*------------------------------------------------------------------------------

	some descriptives to understand number of previous live births, still births and pregnancies

------------------------------------------------------------------------------*/

use ${temp}/live_birth_001, clear

tab ossz1 elve1
tab ossz1 elo1





/*------------------------------------------------------------------------------
	create a panel of women 
		based on
			date of birth of the women
			the date of birth of the previous kid
			education
			citizenship
		maybe 
			father characteristics
			location
			
------------------------------------------------------------------------------*/


* 1) slice the data by number of live births

use ${temp}/live_birth_001, clear
tab elve1
sum elve1, d
local max_elve1 = `r(max)'

forval i = 0(1)`max_elve1' {
	use ${temp}/live_birth_001, clear

	keep if elve1 == `i'
	
	if `i' == 0 {
		gen first_baby_date = baby_birth_date
	}
	else if `i' == 1 {
		gen first_baby_date = prev_livebirth_date
		gen second_baby_date = baby_birth_date
	}
	else if `i' == 2 {
		gen second_baby_date = prev_livebirth_date
		gen third_baby_date = baby_birth_date
	}
	
	save ${temp}/live_birth_elve1_`i', replace
}

* 2) what identifies an observation?

* first 
use ${temp}/live_birth_elve1_0, clear
duplicates tag mother_educ mother_birth_date , gen(tag)
tab tag

duplicates tag mother_educ mother_birth_date first_birth_date, gen(tag2)
tab tag2


* second
use ${temp}/live_birth_elve1_1, clear
duplicates tag mother_educ mother_birth_date , gen(tag)
tab tag

duplicates tag mother_educ mother_birth_date second_baby_date, gen(tag2)
tab tag2

duplicates tag mother_educ mother_birth_date second_baby_date first_baby_date , gen(tag3)
tab tag3


* third
use ${temp}/live_birth_elve1_2, clear
duplicates tag mother_educ mother_birth_date baby_birth_date, gen(tag)
tab tag

duplicates tag mother_educ mother_birth_date baby_birth_date first_baby_date, gen(tag2)
tab tag2

duplicates tag mother_educ mother_birth_date baby_birth_date first_baby_date second_baby_date, gen(tag3)
tab tag3



* 3) matching 
use ${temp}/live_birth_elve1_0, clear

merge 1:1 mother_educ mother_birth_date using ${temp}/live_birth_elve1_1,  keep(1 2 3)
tab _
ren _merge _merge1

merge 1:1 mother_educ mother_birth_date first_baby_date using ${temp}/live_birth_elve1_1, keep(1 2 3)
tab _
ren _merge _merge2

tab _merge1 _merge2






