

dis "`c(username)'"

if "`c(username)'" == "mta37_529" {
	
	
	global root "x:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY"
	global code "${root}\code\"
	global temp "${root}\temp\"
	global output "${root}/output"
	global log "${root}/output/log"
	
	sysdir set PERSONAL "x:\PROJECTS\Project37_A magyarországi családpolitikák fertilitásra gyakorolt hatásának vizsgálata\GYGY\code\ado_personal\"
	
	
	do "${code}/000_set_path_KSH"
}



if "`c(username)'" == "gyozo" {

	global DB "/home/gyozo/Dropbox"
	global root ${DB}/_babavaro
	global code /home/gyozo/GitHub/HousingFertility/ksh

	sysdir set PERSONAL /home/gyozo/ado/personal/
	sysdir set PLUS "/home/gyozo/ado/plus/"
	
	
	do ${code}/001_set_path_dropbox
}













