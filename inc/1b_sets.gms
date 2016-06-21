* --- Geography ---------------------------------------------------------------
Sets
    node "Nodes where different types of energy are converted"
    node_to_node(node,node) "Transmission links"
;

alias(node, from_node, to_node, node_, node_input);
alias(node, from_node, to_node);

* --- Fuels & resources -------------------------------------------------------
Sets
    grid "Forms of energy endogenously presented in the model" /elec, heat/
    emission "Emissions"
    fuel "Fuels"
    flow "Flow based energy resources (time series)"
;

Alias(grid, grid_, grid_output);

Sets param_eg  "Set of possible data parameters for grid, node" /
    maxState    "Maximum energy in the node (MWh)"
/

Sets param_egu "Set of possible data parameters for grid, node, unit" /
    maxCap      "Maximum output capacity (MW)"
    maxCharging "Maximum loading capacity (MW)"
    cB          "Ratio in energy conversion between primary output and secondary outputs, e.g. heat ratio of a CHP-plant (MWh_e/MWh_h)"
    cV          "Reduction in primary output when increasing secondary output, e.g. reduction of electricity generation due to heat generation in extraction CHP (MWh_e/MWh_h)"
/
param_gu "Set of possible data parameters for node, unit" /
    unitCount   "Number of units if aggregated"
    slope       "Slope of the fuel use"
    section     "Section of the fuel use at zero output"
    minLoad     "Minimum loading of a unit (p.u)"
    omCosts     "Variable operation and maintenance costs (€/MWh)"
    startupCost "Variable start-up costs excluding energy costs (€/MWh)"
    startupFuelCons "Consumption of start-up fuel per capacity started up (MWh_fuel/MW)"
    availability "Availability of given energy conversion technology (p.u.)"
    coldStart   "Start-up time from cold to warm (h)"
    warmStart   "Start-up time from warm to hot (h)"
    hotStart    "Start-up time from hot to minLoad (h)"
    fullLoadEff "Efficiency at full load (electric efficiency for CHP units)"
    minLoadEff  "Efficiency at minimum load (electric efficiency for CHP units)"
    minOperation "Minimum operation time (h)"
    minShutDown "Minimum shut down time (h)"
    rampUp      "Speed to ramp up (p.u. / min)"
    SO2         "SO2 emissions (tonne per MWh_fuel)"
    NOx         "NOx emissions (tonne per MWh_fuel)"
    CH4         "CH4 emissions (tonne per MWh_fuel)"
    rampCost    "Wear and tear cost of ramping (€/MW)"
    inflow      "Total annual inflow to a storage (MWh)"
    resTimelim  "How long should a storage be able to provide reserve (h)"
    eff_from    "Conversion efficiency from input energy to the conversion process (ratio)"
    eff_fo      "Conversion efficiency from the conversion process to the output energy (ratio)"
/
param_egs "Set of possible data parameters for grid, node, storage" /
    maxSpill    "Maximum spill rate from storage (MWh/h)"
    minSpill    "Minimum spill rate from storage (MWh/h)"
    maxContent  "Maximum storage content (MWh)"
    minContent  "Minimum storage content (fraction of maximum)"
    chargingEff "Average charging efficiency"
    dischargingEff "Average discharging efficiency"
/
param "Set of general parameters" /
    annualDemand "Total annual energy demand (MWh)"
    annualImport "Electricity import from an exogenous region (MWh per year)"
    emissionTax "Emission tax (€/tonne)"
    emissionIntensity "Intensity of emission from fuel (kg/MWh_fuel)"
    main        "Main fuel"
    startup     "Start-up fuel"
/;

* --- Energy generation and consumption ---------------------------------------
Sets
    unit "Set of generators, storages and loads"
    gn(grid,node) "Nodes of the energy grids"
    gn2n(grid,node,node) "Transfer capacity between nodes in specific energy grids"
    gnu(grid, node, unit) "Units in specific nodes of particular energy grids"
    gnu_input(grid, node, unit) "Forms of energy the unit uses as endogenous inputs"
    nnu(node, node, unit) "Link between upper and lower nodal levels for units"
    nodeState(grid, node) "Nodes with a state variable"
    gnnState(grid, node, node) "Node state variable bounds"
    storage "Storage"
    grid_storage(grid, storage) "The energy grid stored by the storage"
    gns(grid, node, storage) "Storage units of certain energy type in specific nodes"
    nu(node, unit) "Units attached to particular nodes. For units with multiple endogenous outputs only single (node, unit) combination allowed - with the primary grid node (affecting e.g. fuel use calculation with cV)"
    ggnuFixedOutputRatio(grid, grid, node, unit) "Units with a fixed ratio between two different grids of output (e.g. backpressure)"
    ggnuConstrainedOutputRatio(grid, grid, node, unit) "Units with a constrained ratio between two different grids of output (e.g. extraction)"
    unitElec(unit) "Units that generate and/or consume electricity"
    unitHeat(unit) "Units that produce and/or consume unitHeat"
    unitVG(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
    unitWithCV(unit) "Units that use cV factor for their secondary output(s)"
    unitHydro(unit) "Hydropower generators"
    unitFuel(unit) "Units using a commercial fuel"
    unitMinLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unitOnline(unit) "Units that have an online variable"
    flow_unit(flow, unit) "Units linked to a certain energy flow time series"
    unit_fuel(unit, fuel, param) "Fuel(s) used by the unit"
    unit_storage(unit, storage) "Units attached to storages"
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
        / resUp       "Capacity available for upward reserves (p.u.)"
          resDown     "Capacity available for downward reserves (p.u.)"
        /
    resTypeAndDir(resType, resDirection) "Different combinations of reserve types and directions"
        / primary.resUp
          primary.resDown
          secondary.resUp
          secondary.resDown
          tertiary.resUp
          tertiary.resDown
        /
    resCapable(resType, resDirection, node, unit) "Generators capable and available to provide particular reserves"
;


* --- Time & stochastics ------------------------------------------------------


* Sets to define time, forecasts and samples
Sets
    $$include 'input/timeAndSamples.inc'
    m(mType) "model(s) in use"
    tt(t) "Time steps in the current model"
    mf(mType, f) "Forecasts present in the models"
    ms(mType, s) "Samples present in the models"
    mstStart(mType, s, t) "Start point of samples"
    ft(f, t) "Combination of forecasts and time periods in the current model"
    ft_dynamic(f, t) "ft without first t and with tLast+1 (moved right)"
    ft_realized(f, t) "Last realized ft"
    mft(mType, f, t) "Combination of forecasts and time periods in the models"
    mft_(mType, f, t) "Combination of forecasts and time periods in the models"
    msft(mType, s, f, t) "Combination of samples, forecasts and time periods in the models"
    sft(s, f, t) "Combination of samples, forecasts and time periods in the current model"
    mftStart(mType, f, t) "Start point of simulation"
    mftBind(mType, f, t) "Time periods/slices where forecasts/samples are coupled, note: t couples samples"
    fRealization(f) "fRealization of the forecasts"
    fCentral(f) "Forecast that continues as sample(s) after the forecast horizon ends"
    sInitial(s) "Sample that presents the realized/forecasted period"
    sCentral(s) "Sample that continues the central forecast after the forecast horizon ends"
    mftLastForecast(mType, f, t) "Last time period where the forecast extends"
    mftLastSteps(mType, f, t) "Last time periods of the model (can be end of forecasts or end of samples)"
    modelSolves(mType, t) "when different models are to be solved"
;


* Set initial values to avoid errors when checking if parameter contents have been loaded from input data
fRealization('f00') = yes;
ms(mType, s) = no;
modelSolves(mType, t) = no;

alias(m, mSolve);
alias(t, t_, t__, tSolve, tFuel);
alias(f, f_, f__);
alias(s, s_, s__);


*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);



