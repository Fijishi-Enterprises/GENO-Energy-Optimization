$title Plot backbone output with R
$ontext
Plot backbone output with R for energy modelling of buildings

1. Reads backbones full output, e.g. debug.gdx
2. Uses do_r_plot.r do create figures of seleceted parameters

Toni Lastusilta (VTT) ,

Change Log

2022-01-09 , first version
2022-11-30 , conforming to new input format (Backbone downloaded  21.11.2022)
$offtext

$if not set run_title $set run_title TEST
$if not set year $set year 2000
$if not set t_jump $set t_jump ERR
$if not set t_horizon $set t_horizon ERR

* ARCHIVE SETTING
* Set TRUE or FALSE
$set archive TRUE
* Set file name prefix for archivation
$set archive_prefix 2022-12-16_%run_title%_elec_price_%year%__t_jump_%t_jump%__t_horizon_%t_horizon%_CBC
$set output_dir plots\archive\%archive_prefix%
$if not dExist %output_dir% $call mkdir %output_dir%
$set archive_exec 0
$if "%archive%"=="TRUE" $set archive_exec 1

* TEST RUN SETTING (0==False 1==True), if TRUE then time consuming R-script to create plots is called.
$if not set testrun $set testrun 0

* Script to call R for making plots
$onechoV > runR.inc
 $$log runR.inc creates line graphs with R from a two-dimensional parameter in a GDX file
 $$log It can also plot a second parameter
 $$log The file uses compile time variables %Ylabel%, %Ylabel2% and %Xlabel% in case they are set ($set)
 $$log Usage:   $batInclude runR.gms GDXfile GDXparam GDXparam2
 $$log Example: $batInclude runR.gms plot4r.gdx p p2
 $$log Now:     $batInclude runR.gms %1 %2 %3
 $$set r_param2
 $$if not "%3"=="" $set r_param2 -s %3
 $$set r_ylabel
 $$if set Ylabel  $set r_ylabel -y "%Ylabel%"
 $$set r_ylabel2
 $$if set Ylabel2  $set r_ylabel2 -z "%Ylabel2%"
 $$set r_xlabel
 $$if set Xlabel  $set r_xlabel -x "%Xlabel%"
 execute 'Rscript "%gams.wDir%plots\do_r_plot.r" -i "%gams.wDir%plots/%1" -o "%gams.wDir%output/%2.pdf"  -p %2 %r_param2% -w 168 -a archive/%archive_prefix% %r_ylabel% %r_ylabel2% %r_xlabel%  ';
 myerrorlevel = errorlevel;
 if(myerrorlevel=0,
   Execute.ASyncNC 'SumatraPDF.exe  "%gams.wDir%output/%2.pdf"';
 else
   abort "Execution error in Rscript with input argument %1 )";
)
$offecho

* Load sets and parameter definition from backbone
$if not set input_file_gdx $set input_file_gdx inputDataAdjusted1.gdx
$batinclude backbone_definitions_4plots.gms

* Define source GDX for plotting data
$if not set backbone_output_GDX $set backbone_output_GDX "output/out.gdx"
$if "%archive%"=="TRUE"  $call cp "%backbone_output_GDX%" "%output_dir%/%archive_prefix%_backbone_out.gdx"

* Define common sets and parameters
$set GDXparam2         priceElec
$set GDXparam2set2     price_2013
$set GDXparam2alt2     TempOut
$set GDXparam2set2alt2 temp

* Define sets and parameters to be used to prepare data for plots or in ggplots in R
Set
  tparam(t)                      "Time steps (in hours)"
  %GDXparam2set2%                "Electricity price (EUR/MWh)"                /price/
  %GDXparam2set2alt2%            "Outside temperature (C)"                    /temp_out/
  out_temp                       "Outside temperature (C)"

;
Parameter
  myerrorlevel                           "Save Rscript callback error level"          / 0 /
  w2kw                                   "Convert whatt to kilowhatt"                 / 0.001 /
  sign                                   "Switch sign"                                / -1 /
  %GDXparam2%(t,%GDXparam2set2%)         "Electricity spot price (EUR/MWh)"
  %GDXparam2alt2%(t,%GDXparam2set2alt2%) "Temperature outside (Celcius)"
  temp_out(t)                            "Outside temperature (C)"
;

* CREATE PLOTS:
* Read common sets and parameters
* note that  ts_priceElspot is already read in backbone_definitions_4plots.gms
Sets
* --- Energy modelling for buildings ---------------------------------------------------------------
    node_building
    node_building_DHWT_daily
    node_building_light_fabrics
    node_building_load_bearing_fabrics
    node_building_interior_air_and_furniture
    node_building_internal_mass
    node_building2node
    unit_heat
    unit_cool
    unit_DHW
    unit_heat_and_cool
    node_building2unit
Parameters
    ts_priceElspot(t)               "Elspot prices (EUR/MWh)"
    ts_priceElspot_backup(t)        "Elspot Prices_2013 inc. tarifs and taxes (backup) (EUR/MWh)"
    building_squares                "Building square meters (m2)"
    c2k                             "Convert celcius to kelvin degrees"
    p_price_el_select               "Use flat price 1 EUR/MWh (set 0). Use elspot price (set 1)"
;

* Get data from output
*$exit
*$gdxin %backbone_output_GDX%
*$load node_building_DHWT_daily,node_building_light_fabrics,node_building_load_bearing_fabrics
*$load node_building_interior_air_and_furniture,node_building_internal_mass,node_building2node
*$load unit_heat,unit_cool,unit_DHW,unit_heat_and_cool,node_building2unit
*$gdxin

* Adding temperature data
Sets grid,f,t,t_temp(t);
Parameter
  temp_out "Outside temperature (C)"
  ambient_temperature_K(grid,f,t);
$gdxin input/%year%/buildings_auxiliary_data.gdx
$load  t_temp<ambient_temperature_K.dim3 ambient_temperature_K
$gdxin
temp_out(t_temp)= ambient_temperature_K('heat_AB','f00',t_temp) - c2k;

* Read tparam : what is visible in plots
execute_loaddc "%backbone_output_GDX%", mSettings ;
*tparam(t)=(ord(t)<=(min(mSettings('building','dataLength'),mSettings('building','t_end')) - (mSettings('building','t_horizon')-mSettings('building','t_jump'))));
tparam(t)= (ord(t)>mSettings('building','t_start')) and (ord(t)<=(mSettings('building','t_end') - (mSettings('building','t_horizon')-mSettings('building','t_jump'))));
* Read Elspot
%GDXparam2%(tparam,%GDXparam2set2%)=ts_priceElspot(tparam) + eps  ;
$set Ylabel2_alt1 "Price of electricity (EUR/MWh) :"
* Read temp_out
%GDXparam2alt2%(tparam,%GDXparam2set2alt2%)= temp_out(tparam)+ eps ;
$set Ylabel2_alt2 "Outside temperature (C) :"

* Create summary_emob.gdx
$batinclude plots/summary_emob.inc %output_dir%

* CREATE INDIVIDUAL PLOTS
* Input for runR.inc : %GDXfile% for R, %GDXparam% parameter to plot, %TMPParam% two-dimensional counterpart to %GDXparam%
*                      %GDXparam2% is an additional two-dimensional parameter to plot on right-hand side Y-axis

* Plots 1 : ts_influx
* The influence of external power (weather) on building, namely envelope_mass due outside temperature changes and interior air due to ventilation
* Plot ts_influx_absolute *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam ts_influx
$set TMPparam ts_influx_absolute
$set Ylabel "Track exogenous commodities (kWh) :"
$set Ylabel2 %Ylabel2_alt2%
Parameter %TMPparam%(t,node)   "External power (weather) influencing building" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),node)=sum((building_heat_storage(grid,node),f)$(sameas(f,'f00')),w2kw*%GDXparam%(grid,node,f,t) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2alt2%, %GDXparam2alt2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2alt2%
* Plot ts_influx_normalized *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam ts_influx
$set TMPparam ts_influx_normalized
$set Ylabel "Track exogenous commodities per m2 (kWh) :"
$set Ylabel2 %Ylabel2_alt2%
Parameter %TMPparam%(t,node)   "External power (weather) influencing building - normalized by bulding m2" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),node)=sum((building_heat_storage(grid,node),f)$(sameas(f,'f00')), w2kw*%GDXparam%(grid,node,f,t)/building_squares(grid) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2alt2%, %GDXparam2alt2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2alt2%

* Plots 2 : r_gen
* Electric power consumption for heating and cooling of air and heating of domestic hot water
* Plot r_gen heat absolute *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_gen_gnuft
$set TMPparam r_gen_heat_absolute
$set Ylabel Electricity usage (kW) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,unit)   "Electric power consumption for heating and cooling of air" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
display unit_heat_and_cool;
%TMPparam%(tparam(t),unit_heat_and_cool(unit))=sum((grid2node(grid,node),f)$(sameas(grid,"elec") and sameas(f,'f00') ),sign* w2kw* %GDXparam%(grid,node,unit,f,t) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, unit, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_gen_heat_normalized *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_gen_gnuft
$set TMPparam r_gen_heat_normalized
$set Ylabel Electricity usage per m2(kW) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,unit)   "Electric power consumption for heating and cooling of air - normalized by bulding m2" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),unit_heat_and_cool(unit))=sum((grid2node2unit(grid,node,unit),f)$(sameas(grid,"elec") and sameas(f,'f00')),sign* w2kw* %GDXparam%(grid,node,unit,f,t)/building_squares4elec(node) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, unit, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%

* Plot r_gen DHW absolute *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_gen_gnuft
$set TMPparam r_gen_dhw_absolute
$set Ylabel Electricity usage (kW) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,unit)   "Electric power consumption for domestic hot water" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),unit_DHW(unit))=sum((grid2node2unit(grid,node,unit),f)$(unit_DHW(unit) and sameas(f,'f00')),sign* w2kw* %GDXparam%(grid,node,unit,f,t) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, unit, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_gen DHW normalized *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_gen_gnuft
$set TMPparam r_gen_dhw_normalized
$set Ylabel Electricity usage per m2(kW) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,unit)   "Electric power consumption for domestic hot water - normalized by bulding m2" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),unit_DHW(unit))=sum((grid2node2unit(grid,node,unit),f)$(unit_DHW(unit) and sameas(f,'f00')),sign* w2kw* %GDXparam%(grid,node,unit,f,t)/building_squares4elec(node) + eps);
execute_unload 'plots/%GDXfile%', tparam=t, unit, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%

* Plots 3 r_state
* Current building temperature for interior_air_and_furniture, internal_mass, envelope_mass and DHWT
* Plot r_state(interior_air) *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_interior_air
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Temperature at interior_air_and_furniture (Celcius)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_interior_air_and_furniture(node))=sum((building_heat_interior_air_and_furniture(grid,node),f)$(sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_state(light_fabrics) *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_light_fabrics
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Temperature at internal_mass: inside walls  (Celcius)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_light_fabrics(node))=sum((building_heat_light_fabrics(grid,node),f)$(sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_state(load_bearing_fabrics) *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_load_bearing_fabrics
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Temperature at envelope_mass: outside walls (Celcius)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_load_bearing_fabrics(node))=sum((building_heat_load_bearing_fabrics(grid,node),f)$(sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_state(DHWT) *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_DHWT
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Temperature at Domestic Hot Water Tank (Celcius)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_DHWT_daily(node))=sum((building_heat_DHWT_daily(grid,node),f)$(sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%

* Plots 4 Building specific plots
* Plot r_state: Building DH1 *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_DH1
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Detached House 1 (DH1)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_interior_air_and_furniture(node)) = sum((building_heat_interior_air_and_furniture(grid,node),f)$(sameas(grid,"heat_DH") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_light_fabrics(node)) =                           sum((building_heat_light_fabrics(grid,node),f)$(sameas(grid,"heat_DH") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_load_bearing_fabrics(node))=              sum((building_heat_load_bearing_fabrics(grid,node),f)$(sameas(grid,"heat_DH") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_DHWT_daily(node)) =                                 sum((building_heat_DHWT_daily(grid,node),f)$(sameas(grid,"heat_DH") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%
* Plot r_state: Building AB  *******************************************************
$set GDXfile  plot4r.gdx
$set GDXparam r_state_gnft
$set TMPparam r_state_AB
$set Ylabel Temperture (Celcius) :
$set Ylabel2 %Ylabel2_alt1%
Parameter %TMPparam%(t,*)   "Apartment Building (AB)" ;
execute_loaddc "%backbone_output_GDX%", %GDXparam%;
* Below line is adjusted for each paramGDX and paramPlot pair
%TMPparam%(tparam(t),'out_temp')=temp_out(t);
%TMPparam%(tparam(t),heat_interior_air_and_furniture(node)) = sum((building_heat_interior_air_and_furniture(grid,node),f)$(sameas(grid,"heat_AB") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_light_fabrics(node)) =                           sum((building_heat_light_fabrics(grid,node),f)$(sameas(grid,"heat_AB") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_load_bearing_fabrics(node))=              sum((building_heat_load_bearing_fabrics(grid,node),f)$(sameas(grid,"heat_AB") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
%TMPparam%(tparam(t),heat_DHWT_daily(node)) =                                 sum((building_heat_DHWT_daily(grid,node),f)$(sameas(grid,"heat_AB") and sameas(f,'f00')),%GDXparam%(grid,node,f,t) - c2k + eps);
execute_unload 'plots/%GDXfile%', tparam=t, node, %TMPparam%, %GDXparam2set2%, %GDXparam2% ;
$ifE %testrun%==0 $batInclude runR.inc %GDXfile% %TMPparam% %GDXparam2%

Parameter supplementary_info(*);
supplementary_info('plot_building.gms runtime (secs)')=timeelapsed

execute_unload 'plots/plot_building.gdx';
$if "%archive%"=="TRUE"  execute 'cp "plots/plot_building.gdx" "%output_dir%/%archive_prefix%_plot_building_out.gdx"'
$if "%archive%"=="TRUE"  execute 'cp "input/inputDataAdjusted1.gdx" "%output_dir%/%archive_prefix%_inputDataAdjusted1.gdx"'

