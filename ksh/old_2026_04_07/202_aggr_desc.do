

use "${temp}/LB_001", clear



#d ;
	twoway 
		(hist mother_age_tm if birth_ty == 2014 ,  
			color(green) start(11) width(1) )
		(hist mother_age_tm if birth_ty == 2016 , 
			fcolor(none) lcolor(black) start(11) width(1)
			legend(order(1 "2014" 2 "2016"))
			graphregion(color(white)))
		;
#d cr

sum mother_age_tm if birth_ty == 2015, d


