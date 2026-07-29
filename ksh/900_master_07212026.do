* RUN BATCH FIRST
cls
clear
capture log close
do "${code}/900_runRegs_comprehensive.do"
capture log close
do "${code}/900_firstRegs_heteroInteract.do"
capture log close