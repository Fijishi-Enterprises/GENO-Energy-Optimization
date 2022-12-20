$ontext
Dynamic buildings for backbone for backbone energy modeling framework

We make some adjustments to backbone input data

Input: inputData.gdx, buildings_auxiliary_data.gdx
Output: inputDataAdjusted.gdx, buildings_auxiliary_data2.gdx

inputDataAdjusted1.gdx
- New lower and upper temperature limits
- Elspot prices for some year

2021-12-28 Toni Lastusilta (VTT)
$offtext

$if not exist %GAMS.curDir%Backbone.gms $abort GAMS Project or curDir command line parameter must point to Backbone.gms location
* e.g. in GAMS STUDIO use command line parameter curDir=<C:\...\Backbone.gms> without the file reference Backbone.gms
$set proj_dir %GAMS.curDir%

* Create elspot_prices
$if not set year $set year 2015
$if not set run_title $set run_title spot
* year is used also for input folder name
$if 1==0 $call gams input/elspot_price_xls2gdx.gms --year=%year%

*Use backbone definition of sets and parameters
$if not set input_dir $setglobal input_dir 'input'
$if not set output_dir $setglobal output_dir 'output'
$if not set input_file_gdx $setglobal input_file_gdx 'inputData.gdx'
$if not set input_excel_index $setglobal input_excel_index 'INDEX'
$if not set input_excel_checkdate $setglobal input_excel_checkdate ''
$oneolcom
$eolcom //
$onempty   // Allow empty data definitions
$include 'inc\1a_definitions.gms'   // Definitions for possible model settings
$include 'inc\1b_sets.gms'          // Set definitions used by the models
$include 'inc\1c_parameters.gms'    // Parameter definitions used by the models

*Read data from inputData.gdx
$onmultiR
$gdxIn %input_dir%/%year%/%input_file_gdx%
$load grid node unit unittype unitUnittype effLevelGroupUnit
$load ts_influx p_gnBoundaryPropertiesForStates p_gnn p_s_discountFactor
$offmulti
$load  p_gnu_io p_gn p_unit
$gdxin


* Adding exogenous commodity electricity prices : ts_priceElspot
Set
  tsIso Time-stamp in ISO8601 format
;
Parameters
 elspotIsoBB(t,tsIso)     "Elspot Prices_%year% (EUR/MWh) with backbone timestamp and ISO date"
 ts_priceElspotNP(t)      "Elspot price EntsoE_%year% (EUR/MWh)"
 ts_priceElspot(t)        "Elspot Prices_%year% inc. tarifs and taxes (EUR/MWh)"
 ts_priceElspot_backup(t) "Elspot Prices_%year% inc. tarifs and taxes (backup) (EUR/MWh)"
;
$gdxIn %input_dir%/%year%/elspot_prices_%year%.gdx
$load tsIso elspotIsoBB ts_priceElspotNP=elspotBB
$gdxin
* Add taxes Sahko snt/kWh � veroluokka I : 2,253 snt/kWh --> 22,53 e/MWh
* https://www.vero.fi/yritykset-ja-yhteisot/verot-ja-maksut/valmisteverotus/sahkovero/verotaulukot/
* Considering Lumo tarif:  Margin call: 0,24 snt/kWh + Basic fee 1,90 e/month
* Ignoring basic fee: 0,24 snt/kWh --> 2,4 e/MWh
* https://www.sahkon-kilpailutus.fi/en/market-electricity-price/

* we use a temporary set to ensure that if price is zero, then eps is written. Hence, adding taxes to eps makes the cost positive
option tt<elspotIsoBB;
ts_priceElspot(tt(t))=eps + ts_priceElspotNP(t) + 22.53 + 2.4 ;
ts_priceElspot_backup(t)=ts_priceElspot(t);

*Settings
Parameter
  p_price_el_select "Use flat price <avg. price> EUR/MWh (set 0). Use elspot price (set 1)" /1/;
$ifThen %run_title%=="spot" p_price_el_select=1;
$elseIf %run_title%=="flat" p_price_el_select=0;
$else $abort invalid run_title value %run_title%. Valid spot and flat
$endIf

Scalar
  flat_elec_price        Calculated average price from spot price
  cardt_flat_elec_price  Number of non-zeroes in ts_priceElspot
;
cardt_flat_elec_price = sum(t$ts_priceElspot(t),1);
flat_elec_price       = sum(t$ts_priceElspot(t),ts_priceElspot(t))/cardt_flat_elec_price;
;

if(0=p_price_el_select,
     ts_priceElspot(t)=flat_elec_price$ts_priceElspot(t);
   elseif 1=p_price_el_select,
     ts_priceElspot(t)=ts_priceElspot(t);
   else
     abort "Error, invalid value for p_price_el_select, set 0 or 1";
);

* Modify Input (optional)
Parameters
  modify_input      "Modify input (0=no, 1=yes: to set new limits)"                     / 1      /
  c2k               "Convert celcius to kelvin degrees"                                 / 273.15 /
;

display grid,node,unit;
*grids: DH1_LBM, elec, AB_LBM

Sets
 dir   "Direction: lo ,reference ,up"                / lo, ref, up/
 place "Measurement place in building"               / interior_air_and_furniture, internal_mass, envelope_mass, DHWT_daily  /
 grid2node(grid,node) Connect grids to relevant nodes /
  "heat_DH"."heat_DH__interior_air_and_furniture"
  "heat_DH"."heat_DH__load-bearing_fabrics"
  "heat_DH"."heat_DH__light_fabrics"
  "heat_DH"."heat_DH__DHWT_daily_YM"
  "heat_AB"."heat_AB__interior_air_and_furniture"
  "heat_AB"."heat_AB__load-bearing_fabrics"
  "heat_AB"."heat_AB__light_fabrics"
  "heat_AB"."heat_AB__DHWT_daily_YM"
  "elec"."elec_DH"
  "elec"."elec_AB"
 /
 grid2node2unit(grid,node,unit) "Connect electric grid to relevant nodes and units" /
  "elec"."elec_DH"."heat_DH__ideal_cooling"
  "elec"."elec_DH"."heat_DH__G2WHP_DHW"
  "elec"."elec_DH"."heat_DH__G2WHP_radiators"
  "elec"."elec_AB"."heat_AB__G2WHP_DHW"
  "elec"."elec_AB"."heat_AB__G2WHP_radiators"
  "elec"."elec_AB"."heat_AB__ideal_cooling"
 /
 node2unit(node,unit)  "Connect electric nodes and units"

 building_heat(grid) Grid elements for building temperature / "heat_DH","heat_AB"/
 heat_interior_air_and_furniture(node)                      / "heat_DH__interior_air_and_furniture", "heat_AB__interior_air_and_furniture" /
 building_heat_interior_air_and_furniture(grid,node)        / #building_heat:#heat_interior_air_and_furniture /
 heat_light_fabrics(node)                                   / "heat_DH__light_fabrics","heat_AB__light_fabrics"/
 building_heat_light_fabrics(grid,node)                     / #building_heat:#heat_light_fabrics  /
 heat_load_bearing_fabrics(node)                            / "heat_DH__load-bearing_fabrics","heat_AB__load-bearing_fabrics" /
 building_heat_load_bearing_fabrics(grid,node)              / #building_heat:#heat_load_bearing_fabrics /
 heat_DHWT_daily(node)                                      / "heat_DH__DHWT_daily_YM","heat_AB__DHWT_daily_YM" /
 building_heat_DHWT_daily(grid,node)                        / #building_heat:#heat_DHWT_daily /
 elec(node)                                                 / "elec_DH","elec_AB" /
 building_elec(grid,node) "Nodes using electricity"         / #building_heat:#elec /
 elec_trans2building(grid,node) "Nodes transfering electricty to buildings"  /"elec".#elec/
 building_nodes(grid,node)         /
  heat_DH.("heat_DH__interior_air_and_furniture","elec_DH","heat_DH__load-bearing_fabrics","heat_DH__light_fabrics","heat_DH__DHWT_daily_YM")
  heat_AB.("heat_AB__interior_air_and_furniture","elec_AB","heat_AB__load-bearing_fabrics","heat_AB__light_fabrics","heat_AB__DHWT_daily_YM")/
 unit_heat(unit)
  / "heat_DH__G2WHP_radiators", "heat_AB__G2WHP_radiators" /
 unit_cool(unit)
  / "heat_DH__ideal_cooling", "heat_AB__ideal_cooling" /
 unit_DHW(unit)
  / "heat_DH__G2WHP_DHW" , "heat_AB__G2WHP_DHW" /
 unit_heat_and_cool(unit)
  / "heat_DH__G2WHP_radiators", "heat_AB__G2WHP_radiators" , "heat_DH__ideal_cooling", "heat_AB__ideal_cooling" /
 building2unit(grid,unit)
  / heat_DH.("heat_DH__ideal_cooling","heat_DH__G2WHP_DHW","heat_DH__G2WHP_radiators")
    heat_AB.("heat_AB__ideal_cooling","heat_AB__G2WHP_DHW","heat_AB__G2WHP_radiators")/
 building_heat_storage(grid,node) "All nodes for buildings, except for electricity"
;
option node2unit < grid2node2unit;
building_heat_storage(grid,node) =  building_nodes(grid,node) and not building_elec(grid,node);

* Indoor air temperature between 21-27C as per Finnish guidelines.
* DHW preheating to 60C from heat pump, topping 60 -> 90C with resistance heaters.

Table
  temp_limit(place,dir)   "Limit temperatures in Celcius"
                             lo      ref        up
interior_air_and_furniture   21      21         25
internal_mass                0       20         50
envelope_mass                -90     20         50
DHWT_daily                   60      60         90
;

Parameter building_squares(grid) Building square meters by grid /
"heat_DH"  135.56
*"IDA_ESBO_DH2"  145.33
"heat_AB"  1608.19
/;
Parameter building_squares4elec(node) Building square meters by node;
* copy information to electric nodes (one way to get elec consumption per m2)
building_squares4elec("elec_DH")= building_squares("heat_DH");
building_squares4elec("elec_AB")= building_squares("heat_AB");

* Changing Backbone Settings like t_jump, t_horizon, dataLength, etc.
* See file input/buildingInit.gms

if(modify_input=1,
* Defintion: p_gnBoundaryPropertiesForStates(grid,node,param_gnBoundaryTypes,param_gnBoundaryProperties)
  display grid,node,building_heat_DHWT_daily,building_heat_load_bearing_fabrics,building_heat_interior_air_and_furniture,building_heat_light_fabrics,param_gnBoundaryTypes,param_gnBoundaryProperties,p_gnBoundaryPropertiesForStates;
* Set temperature (Celcius) limits for building_interior_air_and_furniture in Celcius
  p_gn(building_heat_interior_air_and_furniture(grid,node), 'boundStart') = 1;
  p_gnBoundaryPropertiesForStates(building_heat_interior_air_and_furniture(grid,node),'downwardLimit','constant') = c2k + temp_limit('interior_air_and_furniture' ,'lo');
  p_gnBoundaryPropertiesForStates(building_heat_interior_air_and_furniture(grid,node),'reference','constant')     = c2k + temp_limit('interior_air_and_furniture' ,'ref');
  p_gnBoundaryPropertiesForStates(building_heat_interior_air_and_furniture(grid,node),'upwardLimit','constant')   = c2k + temp_limit('interior_air_and_furniture' ,'up');
* Set temperature (Celcius) limits for building_internal_mass in Celcius
  p_gn(building_heat_light_fabrics(grid,node), 'boundStart') = 1;
  p_gnBoundaryPropertiesForStates(building_heat_light_fabrics(grid,node),'downwardLimit','constant') = c2k + temp_limit('internal_mass','lo');
  p_gnBoundaryPropertiesForStates(building_heat_light_fabrics(grid,node),'reference','constant')     = c2k + temp_limit('internal_mass','ref');
  p_gnBoundaryPropertiesForStates(building_heat_light_fabrics(grid,node),'upwardLimit','constant')   = c2k + temp_limit('internal_mass','up');
* Set temperature limits for building_envelope_mass in Celcius
  p_gn(building_heat_load_bearing_fabrics(grid,node), 'boundStart') = 1;
  p_gnBoundaryPropertiesForStates(building_heat_load_bearing_fabrics(grid,node),'downwardLimit','constant') = c2k + temp_limit('envelope_mass' ,'lo ');
  p_gnBoundaryPropertiesForStates(building_heat_load_bearing_fabrics(grid,node),'reference','constant')     = c2k + temp_limit('envelope_mass' ,'ref');
  p_gnBoundaryPropertiesForStates(building_heat_load_bearing_fabrics(grid,node),'upwardLimit','constant')   = c2k + temp_limit('envelope_mass' ,'up');
* Set temperature limits for Domestic Hot Water Tank (DHWT)
  p_gn(building_heat_DHWT_daily(grid,node), 'boundStart') = 1;
  p_gnBoundaryPropertiesForStates(building_heat_DHWT_daily(grid,node),'reference','useConstant')  = 1;
  p_gnBoundaryPropertiesForStates(building_heat_DHWT_daily(grid,node),'downwardLimit','constant') = c2k + temp_limit('DHWT_daily' ,'lo');
  p_gnBoundaryPropertiesForStates(building_heat_DHWT_daily(grid,node),'reference','constant')     = c2k + temp_limit('DHWT_daily' ,'ref');
  p_gnBoundaryPropertiesForStates(building_heat_DHWT_daily(grid,node),'upwardLimit','constant')   = c2k + temp_limit('DHWT_daily' ,'up');
* Set electricity price with ts_price modifier
  p_gn( 'elec', elec(node), 'nodeBalance')=0;
  p_gn( 'elec', elec(node), 'usePrice')=1;
*Warning, we have not considered properly the case that price is exactly 0, i.e. missing
  ts_price(elec(node),t) = ts_priceElspot(t);
) ;


* Write input with domains at execution time to take in consideration modifications
execute_unloaddi "input\inputDataAdjusted1.gdx";

$ontext
* Add specific symbols to input GDX
* Not currently working the add_to_gdx.gms can not handle variables correctly, nor can it handle set increments.
  execute_unload "%proj_dir%input\indata2.gdx" modify_input;
  $$set inFile1 inputData.gdx
  $$set inFile2 indata2.gdx
  $$set outFile1 %proj_dir%input\inputDataAdjusted2.gdx
  execute "gams %proj_dir%input\add_to_gdx.gms curDir=%proj_dir%input --inFile1=%inFile1% --inFile2=%inFile2% --outFile1=%outFile1% " ;
$offtext


