


use ${live_birth}/Szuletes_2023_minta_allomany, clear

ren sz_* *

gen ID_birth = _n
lab var ID_birth "unique birth id"

gen ID_mother = _n

gen baby_birth_date = mdy(esho, esnap, esev)
format baby_birth_date %td

gen father_birth_date = mdy(fiszho, fisznap, fiszev)
format father_birth_date %td

gen mother_birth_date = mdy(noszho, nosznap, noszev)
format mother_birth_date %td

gen marriage_date = mdy(hazho, haznap, hazev)
format marriage_date %td

gen prev_livebirth_date = mdy(eloho, elonap, eloev)
format prev_livebirth_date %td

gen prev_stillbirth_date = mdy(heloho, helonap, heloev)
format prev_stillbirth_date %td


foreach X in no fi {

	if "`X'" == "no" {
		local Y = "mother"
	}
	else if "`X'" == "fi" {
		local Y = "father"
	}

	gen `Y'_educ = .
	replace `Y'_educ = 1 if `X'isk == 1
	replace `Y'_educ = 1 if `X'isk99 == 1
	replace `Y'_educ = 1 if `X'isk99 == 2
	replace `Y'_educ = 1 if `X'isk99 == 3
	replace `Y'_educ = 1 if `X'isk99 == 4
	replace `Y'_educ = 1 if `X'isk21 == 0
	replace `Y'_educ = 1 if `X'isk21 == 1

	replace `Y'_educ = 2 if `X'isk == 2
	replace `Y'_educ = 2 if `X'isk99 == 5
	replace `Y'_educ = 2 if `X'isk21 == 2

	replace `Y'_educ = 3 if `X'isk == 3
	replace `Y'_educ = 3 if `X'isk99 == 6
	replace `Y'_educ = 3 if `X'isk99 == 7
	replace `Y'_educ = 3 if `X'isk21 == 3

	replace `Y'_educ = 4 if `X'isk == 4
	replace `Y'_educ = 4 if `X'isk99 == 8
	replace `Y'_educ = 4 if `X'isk21 == 4

	replace `Y'_educ = 5 if `X'isk == 5
	replace `Y'_educ = 5 if `X'isk99 == 9
	replace `Y'_educ = 5 if `X'isk99 == 10
	replace `Y'_educ = 5 if `X'isk21 == 5
	replace `Y'_educ = 5 if `X'isk21 == 6
	replace `Y'_educ = 5 if `X'isk21 == 7

}

lab def educ 1 "less than 8 grades" 2 "8 grades" 3 "vocational" 4 "high school diploma" 5"tertiary"
lab val mother_educ educ
lab val father_educ educ



foreach X in no fi {

	if "`X'" == "no" {
		local Y = "mother"
	}
	else if "`X'" == "fi" {
		local Y = "father"
	}
	
	gen `Y'_activity = .
	
	replace `Y'_activity = 1 if `X'gazd99 == 1
	replace `Y'_activity = 1 if `X'gazd21 == 1
	
	replace `Y'_activity = 2 if `X'gazd99 == 2
	replace `Y'_activity = 2 if `X'gazd21 == 2
		
	replace `Y'_activity = 3 if `X'gazd99 == 3
	replace `Y'_activity = 3 if `X'gazd21 == 3
	
		
	replace `Y'_activity = 4 if `X'gazd99 == 5
	replace `Y'_activity = 4 if `X'gazd21 == 5
		
	replace `Y'_activity = 5 if `X'gazd99 == 6
	replace `Y'_activity = 5 if `X'gazd21 == 7
	
		
	replace `Y'_activity = 6 if `X'gazd99 == 7
	replace `Y'_activity = 6 if `X'gazd21 == 6
	
	
	replace `Y'_activity = 7 if `X'gazd99 == 4
	replace `Y'_activity = 7 if `X'gazd99 == 8
	replace `Y'_activity = 7 if `X'gazd21 == 7
	
		
	
	
	replace `Y'_activity = 1 if `X'gazd21 == 2
	replace `Y'_activity = 1 if `X'gazd21 == 3
	replace `Y'_activity = 1 if `X'gazd21 == 4
	
	replace `Y'_activity = 2 if `X'gazd == 2
	replace `Y'_activity = 2 if `X'gazd == 2
	

}

01	aktív
02	fogl. nyugdíjas, járadékos
03	fogl. GYES
04	nem dolgozó idény és alk. munkás
05	munkanélküli
06	nem fogl. nyugdíjas, járadékos
07	nem fogl. GYES
08	egyéb inaktív
09	tanuló
10	háztartásbeli
11	egyéb eltartott
99	ismeretlen
	
01	foglalkoztatott
02	nyugdíj vagy megváltozott munkaképességűeknek járó ellátás mellett foglalkoztatott
03	gyermekgondozás (-nevelés) címén ellátás (pl.: gyes, gyed, gyet) mellett foglalkoztatott
04	nappali tanulmányok mellett foglalkoztatott
05	munkanélküli
06	gyermekgondozás (-nevelés) címén ellátásban részesülő (pl.: gyes, gyed, gyet)
07	nyugdíjasok és megváltozott munkaképességűek ellátásaiban részesülők
08	egyéb inaktív kereső
09	nappali tagozatos tanuló
10	háztartásbeli
11	egyéb eltartott
99	ismeretlen



save ${temp}/live_birth_001, replace


