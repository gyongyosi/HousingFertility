

use ${temp}/live_birth_001, clear


keep if inlist(ty, 2014, 2021) 

#d ;
	twoway (hist suly if ty == 2014, start(1500) width(25) color(green))
		(hist suly if ty == 2019, start(1500) width(25) fcolor(none) lcolor(black)),
		graphregion(color(white))
		legend(order(1 "2014" 2 "2021" ))
	;
#d cr



use ${temp}/live_birth_001, clear

keep if inlist(ty, 2014, 2021) 


gen cohort_tm = mofd(mother_birth_date)
format cohort_tm %tm

gen tm_baby_birth_date = mofd(baby_birth_date)
format tm_baby_birth_date %tm

gen age_tm = (tm_baby_birth_date - cohort_tm)/12



#d ;
	twoway (hist age_tm if ty == 2014, start(180) width(6) color(green))
		(hist age_tm if ty == 2019, start(180) width(6) fcolor(none) lcolor(black)),
		graphregion(color(white))
		legend(order(1 "2014" 2 "2021" ))
	;
#d cr





use ${temp}/live_birth_001, clear

keep if elve1 == 0

gen cohort_tm = mofd(mother_birth_date)
format cohort_tm %tm

gen tm_baby_birth_date = mofd(baby_birth_date)
format tm_baby_birth_date %tm

gen age_tm = (tm_baby_birth_date - cohort_tm)/12

collapse (mean) age_tm , by(ty)

#d ;
	line age_tm ty, 
		lcolor($color1)
		graphregion(color(white))
		xtitle("")
		ytitle("Average age at first birth")
		;
#d cr




* is apgrar meaningful?
use ${temp}/live_birth_001, clear


keep if inlist(ty, 2014, 2021) 

sum apgar, d 

#d ;
	twoway (hist apgar if ty == 2014, start(0) width(1) color(green))
		(hist apgar if ty == 2019, start(0) width(1) fcolor(none) lcolor(black)),
		graphregion(color(white))
		legend(order(1 "2014" 2 "2021" ))
	;
#d cr


