***
* Climate index insurance project
* Purpose: yield and rainfall
* Date: 2022 March 5
* Update: 2022 March 30
***

cd "/Users/kodam1/Documents/GitHub/Basis-risk"

**************************
**** Yiled and rainfall **
**************************
*** Prep ***
// Maize yield data from Crop Forecast Survey
import delimited "data/cfs/yield_1975_2010.csv", varnames(1) clear 
// different units of maize production
gen prdctn_exp = prdctn_expctd*90/1000 if source == "sheet1" | source == "sheet2"
replace prdctn_exp = prdctn_expctd ///
	if source == "sheet3" | source == "sheet4" | source == "sheet5"
// drop inconsistent data
drop if source == "sheet1" & year==1996
// summarizing category
tab year district
collapse (sum) area_planted area_harvested prdctn_exp sales_expctd basal top, by(district year)
tab  year district

label var year "survey year"
label var district "district"
label var area_planted "area planted (ha)"
label var area_harvested "area to be harvested (ha)"
label var prdctn_exp "expected production ((MT)"
label var sales_expctd "expected sales (MT)"
label var basal "quantity of basal fertilizer used (MT)"
label var top "quantity of top fertilizer used (MT)"
      
gen choma = district == "Choma" 
label var choma "dummy taking 1 if choma"
tab year
gen trend = year - 1975
label var trend "linear trend (1975=0)"
gen yield = prdctn_exp/area_planted 
label var yield "Maize yield (MT/ha)"
tempfile temp_yield
save `temp_yield', replace

// Rainfall data: Choma
import delimited "rawdata/rainfall/Choma_1949-2012.csv", varnames(1) clear 
rename ay year

merge m:1 year using $data/statadata/choma2.dta
drop _merge
egen rain = rowtotal(nov dec jan feb mar apr) // annual (11-4)
egen rain_fl = rowtotal(jan feb) // flowering season
egen rain_pl = rowtotal(nov dec) // planting season
keep rain rain_fl rain_pl year nov dec jan feb
rename nov rain11
rename dec rain12
rename jan rain1
rename feb rain2
tempfile choma
save `choma', replace

// Rainfall data: Malima
import excel $data/rawdata/rainfall/Malima/rainfall＿BuleyaMalima.xlsx, ///
	 sheet("Malima_rainfall") firstrow clear
rename rainfall_irrigation rain 
keep year month rain
replace year = year - 1 if month <= 10
replace rain = 0 if rain == . & (month == 5 | month == 6 | month == 7)
replace rain = 0 if rain == . & (month == 8 | month == 9 | month == 10)
reshape wide rain, i(year) j(month)
egen mrain = rowtotal(rain11 rain12 rain1 rain2 rain3 rain4) // annual (11-4)
egen mrain_fl = rowtotal(rain1 rain2) // flowering season
egen mrain_pl = rowtotal(rain11 rain12) // planting season
drop if year == 2013| year== 1971
keep year mrain mrain_fl mrain_pl rain11 rain12 rain1 rain2
tempfile malima
save `malima', replace

// merge 
use `temp_yield', clear 
merge m:1 year using `choma'
drop _merge
merge m:1 year using `malima'
drop _merge

drop if choma == .
 
 	
	
***** Graphs *****
twoway kdensity yield if choma == 0, lpattern(solid) lcolor(gs7) ///
	xlabel(0(0.5)1.5 0.59) graphregion(color(white)) bgcolor(white) ///
	xtitle("") ytitle("") title("") ///
	xline(0.59, lcolor(maroon) lpattern(solid)) scheme(s2mono)
graph export $paper/manuscript/figure/kdensity-yield.eps, as(eps) name("Graph") replace

/*
twoway connected ///
	yield year if choma == 0 , ///
		graphregion(color(white)) bgcolor(white) xlabel(1990(3)2010) color(gs0) ///
		lpattern(solid) yaxis(1) xt(Crop year) yt(Maize yield (tonnes/ha), axis(1)) ///
	|| connected rain_fl year if year >= 1975 & year < 2011 & choma == 0, ///
		xlabel(1990(3)2010) color(ltblue) lpattern(solid) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	|| connected rain_pl year if year >= 1975 & year < 2011 & choma == 0, ///
		xlabel(1990(3)2010) color(ltblue) lpattern(dash) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	legend(order(1 "Yield" 2 "Flower season rainfall" 3 "Planting season rainfall") cols(4) pos(6)) yline(0.6) title(Yield in Sinazongwe vs. Rainfall in Malima)
graph export $paper/manuscript/figure/yield-rain_a1.jpg, as(eps) name("Graph") replace

twoway connected ///
	yield year if choma == 1 , ///
		graphregion(color(white)) bgcolor(white) xlabel(1975(2)2010) color(gs0) ///
		lpattern(solid) yaxis(1) xt(Crop year) yt(Maize yield (tonnes/ha), axis(1)) ///
	|| connected rain_fl year if year >= 1975 & year < 2011 & choma == 1, ///
		xlabel(1975(2)2010) color(ltblue) lpattern(solid) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	|| connected rain_pl year if year >= 1975 & year < 2011 & choma == 1, ///
		xlabel(1975(2)2010) color(ltblue) lpattern(dash) yaxis(2) xt(Crop year) ///
		yt(Rainfall amounts (mm), axis(2)) ///
	legend(order(1 "Yield" 2 "Flower season rainfall" 3 "Planting season rainfall")  cols(4) pos(6)) yline(1) title(Yield in Choma vs. Rainfall in Choma)
graph export $paper/manuscript/figure/yield-rain_a2.jpg, as(eps) name("Graph") replace

twoway kdensity yield if choma == 0, lpattern(solid) lcolor(gs7) ///
	|| kdensity yield if choma == 1 & year >= 1992, lpattern(dash) lcolor(gs7) ///
	|| kdensity yield if choma == 1 & year >= 1975, lpattern(longdash) lcolor(gs7) ///
	graphregion(color(white)) bgcolor(white) xtitle("Yield ton/ha") ytitle("") ///
	title(Kernel density distribution of yield) ///
	legend(order(1 "Sinazongwe (1992–2010)" 2 "Choma (1992–2010)"  3 "Choma (1975–2010)")  cols(3) pos(6))
graph export $paper/manuscript/figure/yield.jpg, as(eps) name("Graph") replace

reg yield rain_fl trend if choma == 0
reg yield rain_pl trend if choma == 0
*/


***** Optimal threshold *****
gen rain_fl_choma = rain_fl
replace rain_fl_choma = . if choma == 0
bysort year: replace rain_fl_choma = rain_fl_choma[_n+1] if rain_fl_choma == .
gen rain_pl_choma = rain_pl
replace rain_pl_choma = . if choma == 0
bysort year: replace rain_pl_choma = rain_pl_choma[_n+1] if rain_pl_choma == .
gen rain_choma = rain
replace rain_choma = . if choma == 0
bysort year: replace rain_choma = rain_choma[_n+1] if rain_choma == .
keep if choma == 0
//drop if year == 1995

forvalues n = 100(5)500 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain_fl > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain_fl < `n' & yield > 0.59
	egen false_negative_fl`n' = sum(f_negative`n')
	egen false_positive_fl`n' = sum(f_positive`n')
	gen false_fl`n' = false_negative_fl`n' + false_positive_fl`n'
	drop f_negative`n' f_positive`n'
	}

forvalues n = 100(5)500 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain_pl > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain_pl < `n' & yield > 0.59
	egen false_negative_pl`n' = sum(f_negative`n')
	egen false_positive_pl`n' = sum(f_positive`n')
	gen false_pl`n' = false_negative_pl`n' + false_positive_pl`n'
	drop f_negative`n' f_positive`n'
	}

forvalues n = 300(5)1000 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain < `n' & yield > 0.59
	egen false_negative`n' = sum(f_negative`n')
	egen false_positive`n' = sum(f_positive`n')
	gen false`n' = false_negative`n' + false_positive`n'
	drop f_negative`n' f_positive`n'
	}
	
forvalues n = 100(5)500 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain_fl_choma > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain_fl_choma < `n' & yield > 0.59
	egen false_negative_fl_choma`n' = sum(f_negative`n')
	egen false_positive_fl_choma`n' = sum(f_positive`n')
	gen false_fl_choma`n' = false_negative_fl_choma`n' + false_positive_fl_choma`n'
	drop f_negative`n' f_positive`n'
	}

forvalues n = 100(5)500 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain_pl_choma > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain_pl_choma < `n' & yield > 0.59
	egen false_negative_pl_choma`n' = sum(f_negative`n')
	egen false_positive_pl_choma`n' = sum(f_positive`n')
	gen false_pl_choma`n' = false_negative_pl_choma`n' + false_positive_pl_choma`n'
	drop f_negative`n' f_positive`n'
	}
	
forvalues n = 300(5)1000 {
	gen f_negative`n' = 0
	replace f_negative`n' = 1 if rain_choma > `n' & yield < 0.59
	gen f_positive`n' = 0
	replace f_positive`n' = 1 if rain_choma < `n' & yield > 0.59
	egen false_negative_choma`n' = sum(f_negative`n')
	egen false_positive_choma`n' = sum(f_positive`n')
	gen false_choma`n' = false_negative_choma`n' + false_positive_choma`n'
	drop f_negative`n' f_positive`n'
	}
	
keep district false_negative_fl100 - false_choma700
duplicates drop district, force
reshape long false_negative false_positive false false_negative_fl false_positive_fl false_fl false_negative_pl false_positive_pl false_pl false_negative_choma false_positive_choma false_choma false_negative_fl_choma false_positive_fl_choma false_fl_choma false_negative_pl_choma false_positive_pl_choma false_pl_choma, i(district) j(threshold)

stop

// Malima: flowering season
twoway line false_fl threshold if threshold < 420 & threshold > 140, ///
		graphregion(color(white)) bgcolor(white) color(black) lpattern(solid) ///
		xlabel(150(50)420 275) ylabel(0(1)8) xt(Threshold) yt(Count #) ///
	|| line false_negative_fl threshold if threshold < 420 & threshold > 140, ///
		xlabel(150(50)420 275) lpattern(shortdash) lcolor(black*0.5) ///
	|| line false_positive_fl threshold if threshold < 420 & threshold > 140, ///
		xlabel(150(50)420 275) lpattern(shortdash) lcolor(ebblue*0.5) ///
	legend(order(2 "False negative"  3 "False positive" 1 "False negative + false positive" ) cols(3) pos(6)) xline(275, lcolor(maroon) lpattern(solid)) title("") 
graph export $paper/manuscript/figure/threshold-malima.eps, as(eps) name("Graph") replace

// Choma: flowering season
twoway line false_fl_choma threshold if threshold < 505, ///
		graphregion(color(white)) bgcolor(white) color(gs0) lpattern(solid) ///
		xlabel(100(50)500) ylabel(0(1)8) xt(Threshold) yt(Probability) ///
	|| line false_negative_fl_choma threshold if threshold < 505, ///
		xlabel(100(50)500) lpattern(dash) lcolor(gs7) ///
	|| line false_positive_fl_choma threshold if threshold < 505, ///
		xlabel(100(50)500 275) lpattern(longdash) lcolor(gs7) ///
	legend(order(1 "False negative + False positive" 2 "False negative"  3 "False positive")  cols(3) pos(6)) xline(275, lcolor(maroon) lpattern(solid)) title("")

// Malima: planting season
twoway line false_pl threshold if threshold < 505, ///
		graphregion(color(white)) bgcolor(white) color(gs0) lpattern(solid) ///
		xlabel(100(50)500) ylabel(0(1)8) xt(Threshold) yt(Probability) ///
	|| line false_negative_pl threshold if threshold < 505, ///
		xlabel(100(50)500) lpattern(dash) lcolor(gs7) ///
	|| line false_positive_pl threshold if threshold < 505, ///
		xlabel(100(50)500 175) lpattern(shortdash) lcolor(gs7) ///
	text(0.12 165 "0.13", size(vsmall)) ///
	legend(order(1 "False negative + False positive" 2 "False negative"  3 "False positive")  cols(3) pos(6)) xline(175 180 205 220, lcolor(maroon) lpattern(solid)) ///
	title(Optimal threshold for planting seaosn rainfall at Malima)

// Choma: planting season
twoway line false_pl_choma threshold if threshold < 505, ///
		graphregion(color(white)) bgcolor(white) color(gs0) lpattern(solid) ///
		xlabel(100(50)500) ylabel(0(1)8) xt(Threshold) yt(Probability) ///
	|| line false_negative_pl_choma threshold if threshold < 505, ///
		xlabel(100(50)500) lpattern(dash) lcolor(gs7) ///
	|| line false_positive_pl_choma threshold if threshold < 505, ///
		xlabel(100(50)500) lpattern(longdash) lcolor(gs7) ///
	legend(order(1 "False negative + False positive" 2 "False negative"  3 "False positive")  cols(3) pos(6)) xline(175 180, lcolor(maroon) lpattern(solid)) ///
	title(Optimal threshold for planting seaosn rainfall at Choma)

// Malima: rainy season
twoway line false threshold if threshold > 300, ///
		graphregion(color(white)) bgcolor(white) color(gs0) lpattern(solid) ///
		xlabel(300(50)1000) ylabel(0(1)8) xt(Threshold) yt(Probability) ///
	|| line false_negative threshold if threshold > 300, ///
		xlabel(300(50)1000) lpattern(dash) lcolor(gs7) ///
	|| line false_positive threshold if threshold > 300, ///
		xlabel(300(50)1000 630 650) lpattern(shortdash) lcolor(gs7) ///
	legend(order(1 "False negative + False positive" 2 "False negative"  3 "False positive")  cols(3) pos(6)) xline(630 650 780 795, lcolor(maroon) lpattern(solid)) ///
	title(Optimal threshold for rainy seaosn rainfall at Malima)

// Choma: rainy season
twoway line false_choma threshold if threshold > 300, ///
		graphregion(color(white)) bgcolor(white) color(gs0) lpattern(solid) ///
		xlabel(300(50)700) ylabel(0(1)8) xt(Threshold) yt(Probability) ///
	|| line false_negative_choma threshold if threshold > 300, ///
		xlabel(300(50)700) lpattern(dash) lcolor(gs7) ///
	|| line false_positive_choma threshold if threshold > 300, ///
		xlabel(300(50)700 615 650) lpattern(shortdash) lcolor(gs7) ///
	legend(order(1 "False negative + False positive" 2 "False negative"  3 "False positive")  cols(3) pos(6)) xline(615 650, lcolor(maroon) lpattern(solid)) ///
	title(Optimal threshold for rainy seaosn rainfall at Choma)
	
	
