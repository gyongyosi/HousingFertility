/*------------------------------------------------------------------------------
  Cross-country scatter: change in housing affordability vs change in TFR
  Data: produced by 204_cross_country_change_afford_tfr.py
  Output: draft/fig/cross_country_affordability_tfr.pdf
------------------------------------------------------------------------------*/


/*--- paths ------------------------------------------------------------------*/

global DB   "/home/gyozo/Dropbox"
global root "${DB}/claude/research/HousingFertility"

global cc_data "${root}/data/cross_country"
global fig     "${root}/draft/fig"


/*--- color scheme (matches project palette) ---------------------------------*/

local c1  "17 112 170"    // OECD – blue
local c3  "163 172 185"   // BIS + World Bank – grey-blue
local c2  "252 125 11"    // Hungary – orange
local c4  "87 96 108"     // OLS line – dark grey


/*--- load data --------------------------------------------------------------*/

import delimited "${cc_data}/cross_country_affordability.csv", ///
    stringcols(1 2 5) clear


/*--- label text and clock positions -----------------------------------------*/

* vlabel: country name shown in the figure (empty = no label)
gen vlabel = ""
foreach iso in HUN KOR IRL NZL ISL NOR FIN ITA GRC ESP ///
               DEU FRA USA GBR JPN CHN HKG IND {
    replace vlabel = label if iso3 == "`iso'"
}

* label clock position (3 = right, 9 = left)
gen byte lpos = 3
replace lpos = 9 if inlist(iso3, "FIN", "ITA", "GRC", "ESP", "JPN", "CHN", "FRA", "USA")


/*--- figure -----------------------------------------------------------------*/

#delimit ;

twoway
    /* OECD dots (excluding Hungary) */
    (scatter dtfr dpti if iso3 != "HUN",
        msymbol(circle) mcolor("`c1'") msize(small))

    /* Hungary */
    (scatter dtfr dpti if iso3 == "HUN",
        msymbol(circle) mcolor("`c2'") msize(medsmall)
        mlabel(label) mlabvpos(lpos) mlabsize(vsmall) mlabcolor("`c2'"))

    /* OLS fit */
    (lfit dtfr dpti,
        lcolor("`c4'") lpattern(dash) lwidth(thin))

    /* Labels for selected non-Hungary countries */
    (scatter dtfr dpti if vlabel != "" & iso3 != "HUN",
        msymbol(none)
        mlabel(vlabel) mlabvpos(lpos) mlabsize(vsmall) mlabcolor("`c1'"))

    ,
    xline(0, lcolor(gs14) lwidth(thin))
    yline(0, lcolor(gs14) lwidth(thin))
    ylabel(-0.6(0.2)0.4, format(%3.1f) labsize(small))
    xlabel(-80(20)40, labsize(small))
    xtitle(
        "Change in housing affordability, 2010-2019"
        "(+ = less affordable; pp change in PTI relative to long-run avg.)",
        size(small))
    ytitle("Change in TFR, 2010-2019", size(small))
    legend(
        order(1 "OECD countries" 2 "Hungary")
        ring(0) position(1) cols(1)
        size(small) symxsize(small) symysize(small))
    note("Source: OECD Analytical House Price Indicators; World Bank WDI.",
        size(vsmall))
    graphregion(color(white)) plotregion(color(white))
    ;

#delimit cr

graph export "${fig}/cross_country_affordability_tfr.pdf", as(pdf) replace
