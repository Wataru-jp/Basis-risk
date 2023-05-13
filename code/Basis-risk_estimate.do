***
* Climate index insurance project
* Purpose: rainfall data clearning & organizing
* Date: 2021 June 17
* Update: 2023 April 11
***

cd "/Users/kodam1/Documents/GitHub/Basis-risk"

********************************************
**** Combine Choma and plot-level data *****
********************************************

**** Rainfall data at Choma ****
// import Choma data
import delimited "data/rainfall/Choma_1949-2012.csv", varnames(1) clear 
// prep
rename ay year
rename nov rain11
rename dec rain12
rename jan rain1
rename feb rain2
rename mar rain3
rename apr rain4
rename may rain5
rename jun rain6
rename jul rain7
rename aug rain8
rename sep rain9
rename oct rain10
drop cropyear
for num 5/9: replace rainX = 0 if rainX == .
// jan-feb (month=0) and annual (month=13)
egen rain0 = rowtotal(rain1 rain2)
egen rain14 = rowtotal(rain11 rain12)
replace rain14 = . if year == 1949
egen rain13 = rowtotal(rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9 ///
				rain10 rain11 rain12)
// distribution of rainfall
twoway hist rain0, width(45) fcolor(gs12) lcolor(black) ///
	|| kdensity rain0, lcolor(black) legend(off)
graph export figure/flower-rain.jpg, as(jpg) name("Graph") ///
	width(1500) height(1000) quality(100) replace
swilk rain0
sktest rain0
su rain0
ksmirnov rain0 = normal((rain0 - r(mean))/ r(sd))
su rain0
ksmirnov rain0 = normal((rain0 - r(mean))/ r(sd))
gen ln_rain0 = log(rain0)
su rain0
ksmirnov ln_rain0 = normal((ln_rain0 - r(mean))/ r(sd))

// reshape
reshape long rain, i(year) j(month) 
// define monthly mean & sd
gen mean_fifty = . // 1949-2012
gen sd_fifty = .
gen mean_ten = . // 2002-2012
gen sd_ten = .
gen mean0712 = . // 2007-2012
gen sd0712 = .
forvalues i = 0/14 {
	qui su rain if month == `i'
	replace mean_fifty = r(mean) if month == `i'
	replace sd_fifty = r(sd) if month == `i'
	qui su rain if month == `i' & year >= 2002
	replace mean_ten = r(mean) if month == `i'
	replace sd_ten = r(sd) if month == `i'
	qui su rain if month == `i' & year >= 2007
	replace mean0712 = r(mean) if month == `i'
	replace sd0712 = r(sd) if month == `i'
}
// define time variable
tostring year, replace
tostring month, replace
gen time = year + "-" + month
// temp save
rename rain rain_choma
save data/rainfall/Choma.dta, replace


**** Rainfall data at Malima ****
// import Malima data
import excel "data/rainfall/rainfall＿BuleyaMalima.xlsx", sheet("Malima_rainfall") firstrow clear
// prep
rename rainfall_irrigation rain 
keep year month rain
replace year = year - 1 if month <= 10
replace rain = 0 if rain == . & (month == 5 | month == 6 | month == 7)
replace rain = 0 if rain == . & (month == 8 | month == 9 | month == 10)
reshape wide rain, i(year) j(month)
// jan-feb (month=0) and annual (month=13)
egen rain0 = rowtotal(rain1 rain2)
egen rain14 = rowtotal(rain11 rain12)
egen rain13 = rowtotal(rain1 rain2 rain3 rain4 rain5 rain6 rain7 rain8 rain9 ///
				rain10 rain11 rain12)
drop if year == 2013| year== 1971


// reshape
reshape long rain, i(year) j(month) 
// define monthly mean & sd
gen mean_fifty_malima = . // 1973-2012
gen sd_fifty_malima = .
gen mean_ten_malima = . // 2002-2012
gen sd_ten_malima = .
gen mean0712_malima = . // 2007-2012
gen sd0712_malima = .
forvalues i = 0/14 {
	qui su rain if month == `i'
	replace mean_fifty_malima = r(mean) if month == `i'
	replace sd_fifty_malima = r(sd) if month == `i'
	qui su rain if month == `i' & year >= 2002
	replace mean_ten_malima = r(mean) if month == `i'
	replace sd_ten_malima = r(sd) if month == `i'
	qui su rain if month == `i' & year >= 2007
	replace mean0712_malima = r(mean) if month == `i'
	replace sd0712_malima = r(sd) if month == `i'
} 
// define time variable
tostring year, replace
tostring month, replace
gen time = year + "-" + month
// temp save
rename rain rain_malima
save data/rainfall/Malima.dta, replace


**** Rainfall data at plot level ****
// import plot-level data
import delimited "data/rainfall/rainfall_2007-2012.csv", varnames(1) clear
// monthly rainfall
forvalues i = 1/3{
	forvalues j = `i'01/`i'16 {
	bysort year month: egen plot_rain`j' = sum(rain`j')
	drop rain`j'
}
}
drop rain401 rain602 day
// drop duplicates
duplicates drop year month, force
replace year = year - 1 if month <= 10
drop if year == 2006
// define time variable
tostring year, replace
tostring month, replace
gen time = year + "-" + month
// reshape file
reshape long plot_rain, i(time) j(hhid) 
tempfile plot_level
save `plot_level', replace
// add jan-feb
use `plot_level', clear
keep if month == "1" | month == "2"
collapse (sum) plot_rain, by(hhid year)
gen time = year + "-" + "0"
gen month = "0"
tempfile temp1
save `temp1', replace
// add nov-dec
use `plot_level', clear
keep if month == "11" | month == "12"
collapse (sum) plot_rain, by(hhid year)
gen time = year + "-" + "14"
gen month = "14"
tempfile temp2
save `temp2', replace
// add annual
use `plot_level', clear
collapse (sum) plot_rain, by(hhid year)
gen time = year + "-" + "13"
gen month = "13"
tempfile temp3
save `temp3', replace
// append
use `plot_level', clear
append using `temp1'
append using `temp2'
append using `temp3'
tempfile plot_level2
save `plot_level2', replace
// define corr 1-2 and 11-12
destring month, replace
keep if month == 0 | month == 14
keep hhid month year plot_rain
reshape wide plot_rain, i(hhid year) j(month)
qui corr plot_rain0 plot_rain14
gen corr_fl_ger = r(rho)
duplicates drop hhid, force 
keep hhid corr_fl_ger
tempfile temp4
save `temp4', replace
use `plot_level2', clear
merge m:1 hhid using `temp4'
drop _merge 
// define site 
gen site = .
replace site = 1 if hhid < 200
replace site = 2 if hhid > 200 & hhid < 300
replace site = 3 if hhid > 300 &  hhid < 400
// define monthly mean & sd at individual level
destring month, replace
gen mean0712_plot = .
gen sd0712_plot = .
forvalues i = 1/3 {
forvalues j = `i'01/`i'16 {
	forvalues k = 0/14 {
	qui su plot_rain if hhid == `j' & month == `k'
	replace mean0712_plot = r(mean) if hhid == `j' & month == `k'
	replace sd0712_plot = r(sd) if hhid == `j' & month == `k'
	}
}
}
// define monthly mean & sd at site level
gen mean0712_vil = .
gen sd0712_vil = .
forvalues i = 1/3 {
forvalues j = 0/14 { 
	su mean0712_plot if site == `i' & month == `j'
	replace mean0712_vil = r(mean) if site == `i' & month == `j'
	su sd0712_plot if site == `i' & month == `j'
	replace sd0712_vil = r(mean) if site == `i' & month == `j'
} 
}
drop year month


**** Combine rainfall ****
// merge
merge m:1 time using data/rainfall/Choma.dta
drop if _merge == 2
drop _merge
merge m:1 time using data/rainfall/Malima.dta
drop if _merge == 2 
// create hh and site specific mean & sd for dist.
gen mean_plot = mean_fifty*mean0712_plot/mean0712
gen mean_vil = mean_fifty*mean0712_vil/mean0712
gen sd_plot = sd_fifty*sd0712_plot/sd0712
gen sd_vil = sd_fifty*sd0712_vil/sd0712
keep hhid site time year month plot_rain rain_choma rain_malima ///
	mean_plot sd_plot mean_vil sd_vil mean_fifty sd_fifty mean_ten sd_ten ///
	mean_fifty_malima sd_fifty_malima mean_ten_malima sd_ten_malima corr_fl_ger
order hhid site time year month plot_rain rain_choma rain_malima ///
	mean_plot sd_plot mean_vil sd_vil mean_fifty sd_fifty mean_ten sd_ten ///
	mean_fifty_malima sd_fifty_malima mean_ten_malima sd_ten_malima corr_fl_ger
gsort hhid year month
// label
label var hhid "ID" 
label var site "Site ID" 
label var rain_choma "Rainfall, Choma" 
label var rain_malima "Rainfall, Malima" 
label var plot_rain "Rainfall, plot-level" 
label var mean_fifty "mean rainfall 1949-2012, Choma" 
label var sd_fifty "sd rainfall 1949-2012, Choma" 
label var mean_ten "mean rainfall 2002-12, Choma" 
label var sd_ten "sd rainfall 2002-12, Choma" 
label var mean_fifty_malima "mean rainfall 1972-2012, Malima" 
label var sd_fifty_malima "sd rainfall 1972-2012, Malima" 
label var mean_ten_malima "mean rainfall 2002-12, Malima" 
label var sd_ten_malima "sd rainfall 2002-12, Malima" 
label var mean_plot "mean rainfall, plot-level" 
label var sd_plot "sd rainfall, plot-level" 
label var mean_vil "mean rainfall, site-level" 
label var sd_vil "sd rainfall, site-level" 

tempfile rain_combined
save `rain_combined', replace

// Table 5
use data/rain_combined.dta, clear
keep if month == "0"
destring year, replace
forvalues i = 1/3 {
gen rain_plot`i' = plot_rain
replace rain_plot`i' = . if site != `i'
}
for num 2007/2011: eststo rainX: ///
	qui estpost su rain_plot1 rain_plot2 rain_plot3 plot_rain rain_choma rain_malima if year == X
* output	 
label var rain_choma "Choma meteorological station"
label var rain_malima "Malima meteorological station"
label var rain_plot1 "Site A (16 households)"
label var rain_plot2 "Site B (16 households)"
label var rain_plot3 "Site C (16 households)"
label var plot_rain "Total (48 households)"
esttab rain2007 rain2008 rain2009 rain2010 rain2011 /// 
	using table/table5-rain-plot.tex, ///
	label main(mean) aux(sd) nogap nonotes nonumber b(%4.1f) ///
	mtitles("2007/08" "2008/09" "2009/10" "2010/11" "2011/12") replace
 

**************************
**** Estimate (p, r) *****
**************************
use `rain_combined', clear
** estimate correlation
gen corr_rain2011 = . // corr between Choma (annual) vs. Plot (jan & feb)
gen corr_rain2012 = . // corr between Choma (jan & feb) vs. Plot (jan & feb)
gen corr_rain2013 = . // corr between Malima (nov & dec) vs. Plot (jan & feb)
gen corr_rain_opt = . // corr between Malima (jan & feb) vs. Plot (jan & feb)

gen rain_choma0 = rain_choma // flowering season
gen rain_malima0 = rain_malima // flowering season
replace rain_choma0 = 0 if month != "0"
replace rain_malima0 = 0 if month != "0"
bysort year hhid: egen rain_choma1 = sum(rain_choma0)
bysort year hhid: egen rain_malima1 = sum(rain_malima0)

gen choma13 = rain_choma // rainy season
replace choma13 = 0 if month != "13"
bysort year hhid: egen rain_choma2 = sum(choma13)
gen malima1112 = rain_malima // planting season
replace malima1112 = 0 if month != "14"
bysort year hhid: egen rain_malima2 = sum(malima1112)

destring month, replace
forvalues i = 1/3 {
	forvalues j = `i'01/`i'16 {
	qui corr plot_rain rain_choma2 if hhid == `j' & (month==1|month==2)
	replace corr_rain2011 = r(rho) if hhid == `j'
//	qui corr plot_rain rain_choma if hhid == `j' & (month == 0)
	qui corr plot_rain rain_choma1 if hhid == `j' & (month==1|month==2)
	replace corr_rain2012 = r(rho) if hhid == `j'
	qui corr plot_rain rain_malima2 if hhid == `j' & (month==1|month==2)
	replace corr_rain2013 = r(rho) if hhid == `j'
//	qui corr plot_rain rain_malima if hhid == `j' & (month == 11| month == 12) 
//	qui corr plot_rain rain_malima if hhid == `j' & (month == 11 | month == 12) & year!= "2010"
	qui corr plot_rain rain_malima if hhid == `j' & (month==1|month==2)
	replace corr_rain_opt = r(rho) if hhid == `j'
		}
	}
keep if (month == 0 | month == 13 | month == 14) & year == "2008"
keep hhid site month corr_rain2011 corr_rain2012 corr_rain2013 corr_rain_opt ///
	mean_plot sd_plot mean_vil sd_vil mean_fifty sd_fifty mean_ten sd_ten ///
	mean_fifty_malima sd_fifty_malima mean_ten_malima sd_ten_malima corr_fl_ger
// reshape
destring month, replace
reshape wide mean_fifty sd_fifty mean_fifty_malima sd_fifty_malima ///
	mean_ten sd_ten mean_ten_malima sd_ten_malima mean_vil sd_vil ///
	mean_plot sd_plot, i(hhid) j(month)

** estimate (p, r)
// standardize
gen z_dr = (280 - mean_plot0)/sd_plot0 // plot jan-feb (drought)
gen z_dr0 = (0 - mean_plot0)/sd_plot0 // plot jan-feb (drought)
// estimate p
gen p1 = normal(z_dr)
gen p0 = normal(z_dr0)
gen p = (p1-p0)/(1-p0)
// standardize
gen z_choma1 = - (601 - mean_fifty13)/sd_fifty13 // choma annual (drought)
gen z_choma2 = - (281 - mean_fifty0)/sd_fifty0 // choma jan-feb (drought)
gen z_malima1 = - (215 - mean_fifty_malima14)/sd_fifty_malima14 // malima dec-nov (drought)
gen z_malima2 = - (276 - mean_fifty_malima0)/sd_fifty_malima0 // malima jan-feb (drought)
gen c2011 = - corr_rain2011
gen c2012 = - corr_rain2012
gen c2013 = - corr_rain2013
gen c_opt = - corr_rain_opt
// estimate r
//gen r2011 = binormal(z_dr0, z_choma1, c_choma)
gen r11_1 = binormal(z_dr, z_choma1, c2012)
gen r12_1 = binormal(z_dr, z_choma2, c2012)
gen r13_1 = binormal(z_dr, z_malima1, c2013)
gen r_opt1 = binormal(z_dr, z_malima2, c_opt)
gen r11_2 = binormal(z_dr0, z_choma1, c2012)
gen r12_2 = binormal(z_dr0, z_choma2, c2012)
gen r13_2 = binormal(z_dr0, z_malima1, c2013)
gen r_opt2 = binormal(z_dr0, z_malima2, c_opt)
gen r2011 = (r11_1-r11_2)/(1-r11_2)
gen r2012 = (r12_1-r12_2)/(1-r12_2)
gen r2013 = (r13_1-r13_2)/(1-r13_2)
gen r_opt = (r_opt1-r_opt2)/(1-r_opt2)

gen dr2011 = r2011 - r_opt
gen dr2012 = r2012 - r_opt
gen dr2013 = r2013 - r_opt

* save
keep hhid site p r2011 r2012 r2013 r_opt dr2011 dr2012 dr2013
reshape long r dr, i(hhid) j(year)
gen dr2 = dr
replace dr2 = 0 if dr<0
label var p "probability of drought"
label var r "probability of false negative"
label var r_opt "Basis risk, optimal index"
label var dr "Deductible spatial basis risk"
stop 


// histogram drought by site
set scheme s1mono
set scheme s1color
twoway hist p if site == 1 & year == 2012, freq width(0.015) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.25) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist p if site == 2 & year == 2012, freq width(0.015) color(gs13) lcolor(gs7) ///
	|| hist p if site == 3 & year == 2012, freq width(0.015) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Plot-level drought") name(g1, replace)
twoway hist r if site == 1 & year == 2011, freq width(0.008) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2011, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2011, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2011/12") name(g2, replace)
twoway hist r if site == 1 & year == 2012, freq width(0.008) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) color(gs8) lcolor(black) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2012, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2012, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2012/13") name(g3, replace)
twoway hist r if site == 1 & year == 2013, freq width(0.008) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r if site == 2 & year == 2013, freq width(0.008) color(gs13) lcolor(gs7) ///
	|| hist r if site == 3 & year == 2013, freq width(0.008) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk 2013/14") name(g4, replace)
grc1leg g1 g2 g3 g4 
graph export figure/prob-drought.eps, as(eps) name("Graph") replace // eps format


twoway hist r_opt if site == 1 & year == 2011, freq width(0.007) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.05)0.15) ylabel(0(2)8) ///
	ytitle("") xtitle("") ///
	|| hist r_opt if site == 2 & year == 2011, freq width(0.007) color(gs13) lcolor(gs7) ///
	|| hist r_opt if site == 3 & year == 2011, freq width(0.007) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Spatial basis risk, optimal index") name(g1, replace)
twoway hist dr2 if site == 1 & year == 2011, freq width(0.003) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) ///
	ytitle("") xtitle("") ///
	|| hist dr2 if site == 2 & year == 2011, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr2 if site == 3 & year == 2011, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2011/12") name(g2, replace)
twoway hist dr if site == 1 & year == 2012, freq width(0.003) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) color(gs8) lcolor(black) ///
	ytitle("") xtitle("") ///
	|| hist dr if site == 2 & year == 2012, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr2 if site == 3 & year == 2012, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2012/13") name(g3, replace)
twoway hist dr2 if site == 1 & year == 2013, freq width(0.003) color(gs8) lcolor(black) ///
	graphregion(color(white)) xlabel(0(0.02)0.07) ylabel(0(2)10) ///
	ytitle("") xtitle("") ///
	|| hist dr2 if site == 2 & year == 2013, freq width(0.003) color(gs13) lcolor(gs7) ///
	|| hist dr2 if site == 3 & year == 2013, freq width(0.003) color(none) lcolor(gs10) ///
	legend(order(1 "Site A" 2 "Site B" 3 "Site C") cols(3)) ///
	title("Deductible spatial basis risk 2013/14") name(g4, replace)
grc1leg g1 g2 g3 g4 
graph export figure/basis-risk-opt.eps, as(eps) name("Graph") replace // eps format
 

// Table 7
forvalue i = 1/3 {
gen p`i' = p
gen r`i' = r
replace p`i' = . if site != `i'
replace r`i' = . if site != `i'
}
gen year2011 = (year==2011)
gen year2012 = (year==2012)
gen year2013 = (year==2013)
label var p "p, probability of drought" 
label var r "r, probability of false negative" 
label var p1 "~~Site A (16 households)"
label var p2 "~~Site B (16 households)"
label var p3 "~~Site C (16 households)"
label var r1 "~~Site A (16 households)"
label var r2 "~~Site B (16 households)"
label var r3 "~~Site C (16 households)"
for num 2011/2013: eststo prob_statX: qui estpost su p p1 p2 p3 r r1 r2 r3 if year == X
eststo prob_test1: qui estpost ttest r r1 r2 r3 if year2013 == 0, by(year2011)
eststo prob_test2: qui estpost ttest r r1 r2 r3 if year2013 == 0, by(year2012)
eststo prob_test3: qui estpost ttest r r1 r2 r3 if year2011 == 0, by(year2013)
* output	 
esttab prob_stat2011 prob_stat2012 prob_stat2013 /// 
	using table/table7-probability-stat.tex, ///
	label cells("mean(pattern(1 1 1 1) fmt(3) label(Mean)) sd(par label(Std.Dev.))") ///cells("mean sd")
	nogap nonotes nonumber nomtitles ///
	mgroups("2011/12" "2012/13" "2013/14", pattern(1 1 1) ///
	span prefix(\multicolumn{@span}{c}{) suffix(}) /// 
	erepeat(\cmidrule(lr){@span})) replace

