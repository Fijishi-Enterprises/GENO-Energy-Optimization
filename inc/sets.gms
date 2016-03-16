* --- Geography ---------------------------------------------------------------
Sets
    geo "Hubs where different etypes of energy are converted"
    bus(geo) "Electricity buses"
    hydroBus(geo) "Buses with reservoir unitHydro connected"
    bus_to_bus(geo,geo) "Transmission links"
;

alias(geo, from_geo, to_geo, geo_);
alias(bus, from_bus, to_bus);

* --- Fuels & resources -------------------------------------------------------
Sets
    etype "Forms of energy endogenously presented in the model" /elec, heat/
    emission "Emissions"
    fuel "Fuels"
    flow "Flow based energy resources (time series)"
;

Alias(etype, etype_, etype_output);

Set param "Set of data parameters" /
    avg_eff     "Average fuel efficiency"
    avg_fuel_eff "Average fuel efficincy (MWh_fuel/MWh_output)"
    min_load_eff "Fuel usage at minimum load level (MWh_fuel/h/MW_online)"
    min_load    "Minimum load fraction (of maximum power)"
    max_cap     "Maximum output capacity (MW)"
    OaM_costs   "Variable operation and maintenance costs (¤/MWh)"
    gen_costs   "Average generating costs (¤/MWh)"
    max_spill   "Maximum spill rate from storage (MWh/h)"
    min_spill   "Minimum spill rate from storage (MWh/h)"
    max_content "Maximum storage content (MWh)"
    min_content "Minimum storage content (fraction of maximum)"
    charging_eff "Average loading efficiency"
    max_loading "Maximum loading capacity (MW)"
    c_B         "Ratio in energy conversion from A to B and C (B/C), Heat ratio of CHP-plant (MWh_e/MWh_h)"
    c_V         "Potential reduction of energy conversion between B and C, electricity generation due to unitHeat generation (MWh_e/MWh_h)"
    inflow      "Total annual inflow to a storage (MWh)"
    annualDemand      "Total annual energy demand (MWh)"
    availability "Availability of given energy conversion technology (ratio)"
    resUp       "Fraction of online capacity that is available for upward reserves"
    resDown     "Fraction of online capacity that is available for downward reserves"
    startup_cost "Variable start-up costs excluding energy costs (€/MWh)"
    startup_fuelcons "Consumption of start-up fuel per capacity started up (MWh_fuel/MW)"
    max_power   "Maximum power (MW)"
    max_heat    "Maximum unitHeat generation (MW)"
    main        "Main fuel"
    startup     "Start-up fuel"
    leadtime    "Start-up time (h)"
    trans_capacity "Net transfer capacity (NTC) from geo to geo (MW)"
    trans_loss  "Tranmission loss between from geo to geo (ratio)"
    emission_tax "Emission tax (€/tonne)"
    emission_intensity "Intensity of emission from fuel (kg/MWh_fuel)"
    res_timelim "How long should a storage be able to provide reserve without breaching limits (h)"
    conversion_from_eff "Conversion efficiency from input energy to the conversion process (ratio)"
    conversion_to_eff "Conversion efficiency from the conversion process to the output energy (ratio)"
    import "Electricity import from an exogenous region (MWh per year)"
/;

* --- Energy generation and consumption ---------------------------------------
Sets
    unit "Set of generators, storages and loads"
    eg(etype,geo) "Forms of energy in specific geographical locations"
    eg2g(etype,geo,geo) "Transfer capacity between geolocations for specific energy etypes"
    egu(etype, geo, unit) "Units outputting specific energy etypes in geographical locations"
    egu_input(etype, geo, unit) "Forms of energy the unit uses as endogenous inputs"
    ggu(geo, geo, unit) "Link between upper and lower geographical levels for units"
    storage "Storage"
    etype_storage(etype, storage) "The energy etype stored by the storage"
    egs(etype, geo, storage) "Storage units of certain energy type in geographic locations"
    gu(geo, unit) "Units attached to geographical locations"
    gu_fixed_output_ratio(etype, etype, geo, unit) "Units with a fixed ratio between two different etypes of output (e.g. backpressure)"
    gu_constrained_output_ratio(etype, etype, geo, unit) "Units with a constrained ratio between two different etypes of output (e.g. extraction)"
    unitElec(unit) "Units that generate and/or consume electricity"
    unitHeat(unit) "Units that produce and/or consume unitHeat"
    unitVG(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
    unitHydro(unit) "Hydropower generators"
    unitFuel(unit) "Units using a commercial fuel"
    unitMinLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unitOnline(unit) "Units that have an online variable"
    flow_unit(flow, unit) "Units linked to a certain energy flow time series"
    unit_fuel(unit, fuel, param) "Fuel(s) used by the unit"
    unit_storage(unit, storage) "Units attached to storages"
    storageLong(storage) "Long-term energy storages"
    storageHydro(storage)    "Hydropower reservoirs"
;

*alias (generator, generator_);
alias(storage, storage_);


Sets
    genType "Generation technology types"
     / nuclear
       imports
       coal
       unitHydro
       CCGT
       "pumped storage"
       solar
       wind
       OCGT
       dummy /
    genType_g(genType, unit) "Link generation technologies to types"
;

* --- Reserve types -----------------------------------------------------------
Sets
    resType "Reserve types"
        / primary "Automatic frequency containment reserves"
          secondary "Fast frequency restoration reserves"
          tertiary "Replacement reserves"
        /
    resDirection "Reserve direction"
        / resUp "Upward reserves"
          resDown "Downward reserves"
        /
    resTypeAndDir(resType, resDirection) "Different combinations of reserve types and directions"
        / primary.resUp
          primary.resDown
          secondary.resUp
          secondary.resDown
          tertiary.resUp
          tertiary.resDown
        /
    resCapable(resType, resDirection, geo, unit) "Generators capable and available to provide particular reserves"
;


* --- Time & stochastics ------------------------------------------------------


* Sets to define time, forecasts and samples
Sets
    $$include 'input/timeAndSamples.inc'
    m(modelType) "model(s) in use"
    tt(t) "Time steps in the current model"
    mf(modelType, f) "Forecasts present in the models"
    ms(modelType, s) "Samples present in the models"
    mstStart(modelType, s, t) "Start point of samples"
    ft(f, t) "Combination of forecasts and time periods in the current model"
    ft_realized(f, t) "Last realized ft"
    mft(modelType, f, t) "Combination of forecasts and time periods in the models"
    mft_(modelType, f, t) "Combination of forecasts and time periods in the models"
    msft(modelType, s, f, t) "Combination of samples, forecasts and time periods in the models"
    sft(s, f, t) "Combination of samples, forecasts and time periods in the current model"
    mftStart(modelType, f, t) "Start point of simulation"
    mftBind(modelType, f, t) "Time periods/slices where forecasts/samples are coupled, note: t couples samples"
    fRealization(f) "fRealization of the forecasts"
    fCentral(f) "Forecast that continues as sample(s) after the forecast horizon ends"
    sInitial(s) "Sample that presents the realized/forecasted period"
    sCentral(s) "Sample that continues the central forecast after the forecast horizon ends"
    mftLastForecast(modelType, f, t) "Last time period where the forecast extends"
    mftLastSteps(modelType, f, t) "Last time periods of the model (can be end of forecasts or end of samples)"
    modelSolves(modelType, t) "when different models are to be solved"
;


* Set initial values to avoid errors when checking if parameter contents have been loaded from input data
fRealization('f00') = yes;
ms(modelType, s) = no;
modelSolves(modelType, t) = no;

alias(m, m_solve);
alias(t, t_, t__, t_solve, t_fuel);
alias(f, f_, f__);
alias(s, s_, s__);


*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);



