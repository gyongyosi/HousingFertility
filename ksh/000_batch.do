

dis "`c(username)'"

if "`c(username)'" == "mta37_529" {
	
	
	global root "x:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY"
	global code "${root}\code\"
	global temp "${root}\temp\"
	global output "${root}/output"
	global log "${root}/output/log"
	
	sysdir set PERSONAL "x:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY\code\ado_personal\"
	
}


do "${code}/000_set_path"




