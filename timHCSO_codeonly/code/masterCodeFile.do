** this is the MASTER file that runs all of the other files
clear
cls
* locals
local homePath "X:\Kimeno\kutato29\Output1\Working_files" 
* log
log close _all
log using "`homePath'\log\masterCodeFile.log", replace  
cd "X:\Kimeno\kutato29\Output1\Program_files" 
display c(current_time)

** calls start here **********************************************************

* this file converts raw census into a panel--takes a few hours to run!
do 0a-savePanel.do

* this file saves type and CSOK status from the T-STAR file
do 0b-saveTSTARSettlementCharacteristics.do

* this file saves Working_files\data\mid\settlementNames.xlsx as dta
do 0c-saveSettlementNames.do

* this file creates control variables (and saves Gyozo agg stats)
do 1-createPanelVars.do

* this file saves settlement-year-level fertility from micro-data
do 2a-saveSettlementYear.do

* this file creates summary stats
do 2b-runSumms.do

* this file runs regression--takes a long time to run!
do 2c-runRegs.do

* this file creates TSTAR pictures
* do t-wrangleTSTAR.do

display c(current_time)
