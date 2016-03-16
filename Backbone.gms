$title Backbone
$ontext
Backbone - chronological energy systems model
===================================
Created by:
    Juha Kiviluoma <juha.kiviluoma@vtt.fi>
    Erkka Rinne <erkka.rinne@vtt.fi>

Based on Stochastic Model Predictive Control method [1]. Improved by
generalising the idea of storages and adding the ability to load storages.
Can handle multiple stochastic parameters.


GAMS command line arguments
---------------------------
--debug=[yes|no]
    Switch on/off debugging mode. In debug mode, writes ‘debug.gdx’
    with all symbols as well as a gdx file for each solution containing
    model parameters, variables and equations.

--dummy=[yes|no]
    Do not solve the model, just do preliminary calculations.
    For testing purposes.

--<name of model parameter>=<value>
    Set model parameter value. See file ‘settings.inc’ for available
    parameters.

--<name of model feature>=[yes|no]
    Switch model features on/off. See file ‘settings.inc’ for available
    features.


References
----------
[1] K. Nolde, M. Uhr, and M. Morari, ‘Medium term scheduling of a hydro-thermal
    system using stochastic model predictive control, ’ Automatica, vol. 44,
    no. 6, pp. 1585–1594, Jun. 2008.

$offtext

* === Settings ================================================================
* Activate end of line comments and set comment character to '//'
$oneolcom
$eolcom //

* Set log file (output to IDE process window)
file log /''/;

* Allow empty data definitions
$onempty
option profile = 3;

* Load model settings
$include 'settings.inc'

* === Sets ====================================================================
$include 'inc/sets.gms'

* === Parameters ==============================================================
$include 'inc/parameters.gms'
$include 'inc/results.gms'


Scalars
    errorcount /0/
    elapsed "Model time elapsed since simulation start (t)" /0/
    t_solveOrd "ord of t_solve"
;

* Debug arrays
Parameters
    x_stoContent(storage, f, t) "Storage content at the end of the time period in a sample (ratio of max)"
    x_storageControl(storage, f, t) "Storage control value during a time period in a sample (MWh)"
;

* === Macros ==================================================================
$include 'inc/macros.gms'


options
    solvelink = %Solvelink.Loadlibrary%
$ifi not '%debug%' == 'yes'
    solprint = Silent
;

* Load updates made for BackBone
$gdxin  'input/inputData.gdx'
$loadm  param
$loaddc geo
$loaddc flow
$loaddc bus
$loaddc unit
$loaddc fuel
$loaddc storage
*$loaddc eg
*$loaddc unitVG
$loaddc hydroBus
*$loaddc gu
$loaddc egu
$loaddc egu_input
$loaddc ggu
$loaddc egs
$loaddc flow_unit
$loaddc unit_fuel
$loaddc unit_storage
$loaddc gu_fixed_output_ratio
$loaddc gu_constrained_output_ratio
*$loaddc resCapable
$loaddc emission
$loaddc ts_energyDemand
$loaddc ts_import
*$load   ts_reserveDemand
$loaddc ts_cf
$loaddc ts_stoContent
$loaddc ts_fuelPriceChange
$loaddc ts_inflow
$loaddc p_data2d
$loaddc uData
$loaddc usData
$loaddc uReserveData
$loaddc p_transferCap
$loaddc p_transferLoss
*$loaddc etype_storage
$gdxin

* Generate sets based on parameter data
eg(etype, geo)$sum(unit, egu(etype, geo, unit)) = yes;
gu(geo, unit)$sum(etype, egu(etype, geo, unit)) = yes;
*egu(etype,geo,unit)$(gu(geo,unit) and eg(etype,geo)) = YES;
ggu(geo, geo_, unit)$(gu(geo, unit) and ord(geo) = ord(geo_)) = yes;
eg2g(etype, from_geo, to_geo)$p_transferCap(etype, from_geo, to_geo) = yes;
bus_to_bus(from_geo, to_geo)$p_transferCap('elec', from_geo, to_geo) = yes;

ts_fuelPriceChangeGeo(fuel, geo, t) = ts_fuelPriceChange(fuel, t);

unitOnline(unit)$[ sum(egu(etype, geo, unit), udata(etype, geo, unit, 'startup_cost') or udata(etype, geo, unit, 'startup_fuelcons') or udata(etype, geo, unit, 'leadtime') ) ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
*unitConversion(unit)$sum(eg(etype, geo), egu_input(etype, geo, unit)) = yes;
unitElec(unit)$sum(egu(etype, geo, unit), udata('elec', geo, unit, 'max_cap')) = yes;
unitHeat(unit)$sum(egu(etype, geo, unit), udata('heat', geo, unit, 'max_cap')) = yes;
unitFuel(unit)$sum[ (fuel, geo)$sum(t, ts_fuelPriceChangeGeo(fuel, geo, t)), unit_fuel(unit, fuel, 'main') ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
unitMinload(unit)$sum(egu(etype, geo, unit), p_data2d(etype, unit, 'min_load')) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER','main'), 1) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER_RES','main'), 1) = yes;
storageHydro(storage)$sum(unitHydro, unit_storage(unitHydro, storage)) = yes;
resCapable(resType, resDirection, geo, unit)$uReserveData(geo, unit, resType, resDirection) = yes;

* === Variables ===============================================================
$include 'inc/variables.gms'


* === equations ===============================================================
$include 'inc/equations.gms'


* Load stochastic scenarios
$batinclude 'inc/gdxload_fluctuation.inc' wind
$batinclude 'inc/gdxload_fluctuation.inc' solar
$ifthen exist 'input/scenarios_hydro.gdx'
    $$gdxin 'input/scenarios_hydro.gdx'
$endif
$gdxin


* --- Data corrections etc. ---------------------------------------------------
$if exist 'extra_data.gms' $include 'extra_data.gms'


$include 'inc/schedule.gms'



* === Calculations ============================================================

* Define long-term storages
loop(egs(etype, geo, storage) $(usData(etype, geo, storage, 'max_content') > 0
               and sum(unit_storage(unit, storage),
                       uData('elec', geo, unit, 'max_cap')
                       + uData('heat', geo, unit, 'max_cap')) > 0),
    storageLong(storage) = yes$(usData(etype, geo, storage, 'max_content')
                                 / sum(unit_storage(unit, storage),
                                       uData('elec', geo, unit, 'max_cap')
                                       + uData('heat', geo, unit, 'max_cap'))
                                > 0.5 * modelSolveRules('schedule', 't_horizon') );
);


* Link units to genTypes
$iftheni '%genTypes%' == 'yes'
loop(gu_fuel(geo, unit, fuel, 'main'),
    genType_g('pumped storage', unit) = yes$(sameas(fuel, 'water')
                                          and p_data(unit, 'max_loading') > 0);
    genType_g('hydropower', unit) = yes$(sameas(fuel, 'water')
                                      and not genType_g('pumped storage', unit));
    genType_g('nuclear', unit) = yes$sameas(fuel, 'nuclear');
    genType_g('coal', unit) = yes$sameas(fuel, 'coal');
    genType_g('OCGT', unit) = yes$(sameas(g, 'OCGT') or sameas(unit, 'DoE_Peaker'));
    genType_g('CCGT', unit) = yes$(sameas(fuel, 'nat_gas')
                                and not genType_g('OCGT', unit));
    genType_g('solar', unit) = yes$sameas(fuel, 'solar');
    genType_g('wind', unit) = yes$sameas(fuel, 'wind');
    genType_g('imports', unit) = yes$(not sameas(area, 'SA'));
    genType_g('dummy', unit) = yes$sameas(unit, 'dummy');
);
$endif

* Calculate average hourly loads from demand
ts_energyDemand(etype, geo, f, t)$ts_energyDemand(etype, geo, f, t)
    = ts_energyDemand(etype, geo, f, t) * p_data2d(etype, geo, 'annualDemand') / 1;

* Calculate power based time series for ramp scheduling
*if(active('rampSched'),
*    $$include 'inc/rampSched/rampSchedTimeSeries_rampSearch.gms'
*);
*$include 'inc/rampSched/killStuff.gms'


* --- Use input data to select which samples are included in the model run
*$include 'input/samples_in_model.inc';

* --- Calculate trees ---------------------------------------------------------
*$include 'inc/treeCalc.inc'

* --- Extra calculations ------------------------------------------------------
$if exist 'extra_calculations.gms' $include 'extra_calculations.gms'


* === Files ===================================================================
files gdx, cmd;
file f_info /'output/info.txt'/;

* === Simulation ==============================================================

* --- Generate model rules ----------------------------------------------------

* Check the modelSolves for preset patterns for model solve timings
* If not found, then use modelSolveRules to set the model solve timings
loop(modelType,
    if(sum(t$modelSolves(modelType, t), 1) = 0,
        t_skip_counter = 0;
        loop(t$( ord(t) = modelSolveRules(modelType, 't_start') + modelSolveRules(modelType, 't_jump') * t_skip_counter and ord(t) <= modelSolveRules(modelType, 't_end') ),
            modelSolves(modelType, t)=yes;
            t_skip_counter = t_skip_counter + 1;
        );
    );
);

* Select models to be used
m(modelType)=no;
loop(modelType,
    // If there are solves for a model, then the model is turned on
    if(sum(t$modelSolves(modelType, t), 1) > 0,
        m(modelType) = yes;
    );
);

* Select samples for the model
loop(m,
    // Set scenarios in use for the models, if they haven't been provided in the data
    if (not sum(s, ms(m, s)),
        ms(m, s)$(ord(s) <= modelSolveRules(m, 'samples')) = yes;
        // Use all scenarios if modelSolveRules/scenarios is 0
        if (modelSolveRules(m, 'samples') = 0,
            ms(m, s) = yes;
        );
    );
);

// If the model does not have preset step lengths...
loop(m,
    if(sum[(ms(m,s), f, t)$fRealization(f), p_stepLength(m, f, t)] = 0,
        // ...and if there is a t_interval for the model, then use it to set constant step lengths
        if(modelSolveRules(m, 't_interval'),
            p_stepLength(mf(m, f), t) = modelSolveRules(m, 't_interval');
        );
    );
);



loop(modelSolves(m_solve, t_solve),
    t_solveOrd = ord(t_solve);
    elapsed = t_solveOrd - modelSolveRules(m_solve, 't_start');

    // Set mft for the modelling period and model forecasts
    mft(m_solve,f,t) = no;
    mft(m_solve, f, t)${ [ord(t) >= ord(t_solve)]
                         and [ord(t) <= ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')]
                         and mf(m_solve, f)
                       } = yes;
    mftStart(m_solve,f,t) = no;
    mftStart(m_solve,fRealization,t)$[ord(t) = ord(t_solve)] = yes;
    mftLastForecast(m_solve,f,t) = no;
    mftLastForecast(m_solve,f,t)$[ord(f)-1 <= modelSolveRules(m_solve, 'forecasts') and ord(t) = ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')] = yes;
    mftLastSteps(m_solve,f,t) = no;
    mftLastSteps(m_solve,f,t)$[ord(f)-1 <= modelSolveRules(m_solve, 'forecasts') and ord(t) = ord(t_solve) + max(modelSolveRules(m_solve, 't_forecastLength'), modelSolveRules(m_solve, 't_horizon'))] = yes;
    mftBind(m_solve,f,t) = no;
    mft_bind(m_solve,f,t) = no;
    mt_bind(m_solve,t) = no;
*    mftBind(mft(m_solve,f,t))$[ord(t) = ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')] = yes;
*    mft_bind(mft(m_solve,f,t))$[ord(t) = ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')] = 1 - ord(f);
*    mt_bind(m_solve,t)$[ord(t) = ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')] = -1;
    msft(m_solve, s, f, t) = no;
    msft(m_solve, 's000', f, t) = mft(m_solve,f,t);
    msft(m_solve, 's000', fRealization(f), t)${ [ord(t) >= ord(t_solve) + modelSolveRules(m_solve, 't_forecastLength')]
                             and [ord(t) <= ord(t_solve) + modelSolveRules(m_solve, 't_horizon')]
                             and mf(m_solve, f)
                           } = yes;
    ft(f,t) = no;
    ft(f,t) = mft(m_solve, f, t);
    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) = ord(t_solve)] = yes;
    pf(ft(f,t))$(ord(t) eq ord(t_solve) + 1) = 1 - ord(f);
    pt(t)$[ ord(t) > ord(t_solve) and ord(t) <= ord(t_solve) + modelSolveRules(m_solve, 't_horizon') ] = -1;

    // Arbitrary value for energy in storage
    p_storageValue(egs(etype, geo, storage), t)$sum(fRealization(f), ft(f,t)) = 50;
    // PSEUDO DATA
    ts_reserveDemand(resType, resDirection, bus, fRealization(f), t) = 50;

* --- Set variable limits (.lo and .up) ---------------------------------------
    $$include 'inc/set_variable_limits.gms'

* --- Solve Model -------------------------------------------------------------
    if (m_solve('schedule'),
        solve schedule using lp minimizing v_obj;
    );

* --- Output debugging inetypeation --------------------------------------------
    $$ifi '%debug%' == 'yes'
    execute_unload 'output/debug.gdx';


*--- Store results ------------------------------------------------------------
    // Deterministic stage
    loop(ft(fRealization(f), t),
*        p_stoContent(f, t)$(p_data(storage, 'max_content') > 0)
*            = v_stoContent(storage, f, t) / p_data(f, 'max_content');
            r_gen(etype, unit, t) = sum(geo$egu(etype, geo, unit), v_gen.l(etype, geo, unit, f, t));
$iftheni.genTypes '%genTypes%' == 'yes'
            r_elec_type(genType, t) = sum(g $genType_g(genType, unit),
                                          v_gen.l('elec', unit, f, t));
$endif.genTypes
            r_demand(bus, t)
                = sum(eg('elec', bus), ts_energyDemand('elec', bus, f, t));
$ontext
            r_transmission(h, from_bus, to_bus, t)
                = v_transmission(from_bus, to_bus, t);
            r_elecConsumption(h, consuming(elec))
                = v_elecConsumption.l(elec, t);
            r_elecPrice(h, bus)
                = q_elecDemand.m(bus, f, t) / p_blockLength(t);
            r_heat(h, heat) = v_heat.l(heat, t);
            r_storageControl(h, storage)
               = v_stoCharge.l(storage, f, t) / p_blockLength(t);
            r_onlineCap(h, elec) = v_gen.l('elec', elec, fCentral(f), t);
            r_onlineCap(h, unitMinLoad(elec)) = v_online.l(elec, f, t);
            r_onlineCap(h, unitVG(elec)) = p_unitVG(elec, f, t);
            r_onlineCap(h, unitVG(elec))
               = v_elec.l(unitVG, t);
        loop(step_hour(h, t),
           r_stoContent(h, f)$p_data(f, 'max_content')
              = r_stoContent(h - 1, f)
                + (r_storageControl(h, f)
                   + ts_inflow(h, f)
                   + sum(unit_storage(unitVG, f),
                         ts_inflow(h, unitVG)
                     )
                  ) / p_data(f, 'max_content');
           r_storageValue(h, f) = p_storageValue(f, t);
           r_elecLoad(h, bus)
               = sum(load_in_hub(load, bus), ts_elecLoad(h, load));
        );
$offtext
    );
    r_totalCost = r_totalCost + v_obj.l;


// Debugging results
$iftheni.debug '%debug%' == 'yes'

*    putclose gdx;
*    put_utility 'gdxout' / 'output\'m_solve.tl:0, '-', t_solve.tl:0, '.gdx';
*    execute_unload
*    $$include inc/debug_symbols.inc
*    ;
$endif.debug

);

* Time independent results
$iftheni '%genTypes%' == 'yes'
    r_capacity_type(genType)
        = sum(g$genType_g(genType, g), p_data(g, 'max_power'));
$endif

* === Output ==================================================================

* Get model version
$echon "'StoSSch version' " > 'stosschver'
$call 'git describe --dirty=+ --always >> stosschver'

* Create metadata
set metadata(*) /
   'User' '%sysenv.username%'
   'Date' '%system.date%'
   'Time' '%system.time%'
   'GAMS version' '%system.gamsrelease%'
   'GAMS system' '%system.gstring%'
$include 'stosschver'
/;
if(errorcount > 0, metadata('FAILED') = yes);

put f_info
put "***********************************************************************"/;
put "* MODEL RUN DETAILS                                                   *"/;
put "***********************************************************************"/;
loop(metadata,
    put metadata.tl:20, metadata.te(metadata) /;
);
put /;
put "time (s)":> 21 /;
put "---------------------"/;
put "Compilation", system.tcomp:> 10 /;
put "Execution  ", system.texec:> 10 /;
put "Total      ", system.elapsed:> 10 /;
put /;
put "***********************************************************************"/;
put "* MODEL FEATURES                                                      *"/;
put "***********************************************************************"/;
loop(feature $active(feature),
    put feature.tl:20, feature.te(feature):0 /;
);
put /;
f_info.nd = 0; // Set number of decimals to zero
put "Start time:                 ", modelSolveRules('schedule', 't_start')/;
put "Length of forecasts:        ", modelSolveRules('schedule', 't_forecastLength')/;
put "Model horizon:              ", modelSolveRules('schedule', 't_horizon')/;
put "Model jumps after solve:    ", modelSolveRules('schedule', 't_jump')/;
put "Last time period to solve:  ", modelSolveRules('schedule', 't_end')/;
put "Length of each time period: ", modelSolveRules('schedule', 't_interval')/;
put "Number of samples:          ", modelSolveRules('schedule', 'samples')/;

putclose;
* -----------------------------------------------------------------------------

* Post-process results
$if exist 'postprocess.gms' $include 'postprocess.gms'

execute_unload 'output/results.gdx',
    $$include 'inc/result_symbols.inc'
;

$ifi '%debug%' == 'yes'
    execute_unload 'output/debug.gdx';

if(errorcount > 0, abort errorcount);

* === THE END =================================================================
