* --- Model parameters, features and switches ---------------------------------
Sets  // Model related selections
    mType "model types in the Backbone" /invest, storage, schedule, realtime/
    mSetting "setting categories for models" /t_start, t_jump, t_horizon, t_forecastLength, t_end, samples, forecasts, intervalEnd, intervalLength, t_aggregate/
    counter "general counter set" /c000*c999/

    slope "Part-load efficiency"
        /slope00*slope12/
    rb "Right borders of efficiency curves"
        /rb00*rb12/
    lb "Left borders of efficiency curves"
        /lb00*lb12/
    effSelector "Select equations and lambdas/slope for efficiency calculations"
        / directOff, directOn, slope01*slope12, lambda01*lambda12 /
    effDirect(effSelector) "Using direct input to output equation"
        / directOff, directOn /
    effDirectOff(effSelector) "Using direct input to output equation without online variable, i.e. constant efficiency"
        / directOff /
    effDirectOn(effSelector) "Using direct input to output equation with online variable"
        / directOn /
    effSlope(effSelector) "Slope in use for part-load efficiency representation"
        / slope01*slope12 /
    effLambda(effSelector) "Lambdas in use for part-load efficiency representation"
        / lambda01*lambda12 /
    effLevel "Pre-defined levels for efficiency representation that can start from t_solve + x"
        / level1*level9 /
;


* Numeric parameters
Parameter
    mSettings(mType, mSetting)
    mSettingsEff(mtype, effLevel)
    mInterval(mType, mSetting, counter)
    t_skip_counter
;


Parameter params(*) /
$if exist 'params.inc' $include 'params.inc'
/;


* Model features
Set feature "Set of optional model features" /
    findStorageStart "Solve for optimal storage start levels"
    storageValue     "Use storage value instead of fixed control"
    storageEnd       "Expected storage end levels greater than starting levels"
    addOn            "Use StoSSch as a storage add-on to a larger model"
    extraRes         "Use extra tertiary reserves for error in elec. load during time step"
    rampSched        "Use power based scheduling"
/;

Set active(feature) "Set membership tells active model features" /
$if exist 'features.inc' $include 'features.inc'
/;

* --- Parse command line options and store values -----------------------------

* Features
$if set findStorageStart active('findStorageStart') = %findStorageStart%;
$if set storageValue active('storageValue') = %storageValue%;
$if set storageEnd active('storageEnd') = %storageEnd%;
$if set addOn active('addOn') = %addOn%;
$if set extraRes active('extraRes') = %extraRes%;
$if set rampSched active('rampSched') = %rampSched%;


* --- Set definitions for parameters -----------------------------------------------------
Sets

param_gn  "Set of possible data parameters for grid, node" /
    maxState    "Absolute maximum state of the node (unit depends on energyCapacity)"
    minState    "Absolute minimum energy in the node (unit depends on energyCapacity)"
    maxStateSlack "Maximum increase or decrease in the state of the node with a specifict cost co-efficient (unit depends on energyCapacity)"
    referenceState    "Reference value for a state that can be used to fix a state (unit depends on energyCapacity)"
    energyCapacity "Energy capacity of the node (MWh/?, allows for changing the quality of the node state variables)"
    maxSpill    "Maximum spill rate from the node (MWh/h)"
    minSpill    "Minimum spill rate from the node (MWh/h)"
    chargingEff "Average charging efficiency (p.u)"
    dischargingEff "Average discharging efficiency (p.u.)"
    selfDischargeLoss "Self discharge rate of the node (p.u.)"
    fixNothing  "A flag to indicate that no state should be fixed"
    fixStart "A flag to fix tSolve based on fixState constant or time series or on the previous solve"
    fixEnd "A flag to fix last t based on fixState constant or time series"
    fixConstant "A flag to fix a state with a constant value in referenceState"
    fixTimeSeries "A flag to use time series to fix states"
    fixCircular "Force the last states to equal the first state"
    maxUseTimeSeries "Use time series instead of a constant to set state maximum"
    minUseTimeSeries "Use time series instead of a constant to set state minimum"
    referenceMultiplier  "A multiplier to change the reference value (either constant or time series), default 1"
    maxMultiplier "State maximum (time series or constant) multiplier, default 1"
    minMultiplier "State minimum (time series or constant) multiplier, default 1"
/

param_gnn "Set of possible data parameters for grid, node, node (nodal interconnections)" /
    transferCap "Transfer capacity limits"
    transferLoss "Transfer losses"
    diffCoeff   "Coefficients for energy diffusion between nodes"
    boundStateOffset "Offset parameter for relatively bound node states"
/

param_gnu "Set of possible data parameters for grid, node, unit" /
    maxGen      "Maximum output capacity (MW)"
    maxCons     "Maximum loading capacity (MW)"
    cB          "Share of output"
    cV          "Reduction in primary output when increasing secondary output, e.g. reduction of electricity generation due to heat generation in extraction CHP (MWh_e/MWh_h)"
    eff00 * eff12    "Efficiency of the unit to convert to certain output or from certain input at different operating points"
    rb00 * rb12     "Right border of the efficiency point"
    section00   "Input (fuel) consumption at min. load (or at zero)"
    slope00 * slope12  "Additive input (fuel) consumption slope"
/

param_nu "Set of possible data parameters for node, unit" /
    unitCount   "Number of units if aggregated"
    unitCapacity "A proxy for the unit size in case the maxGens cannot be just added up by default"
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
    eff00 * eff12    "Efficiency of the unit to convert input to output/intermediate product"
    rb00 * rb12     "Right border of the efficiency point"
    section00   "Input (fuel) consumption at min. load (or at zero)"
    slope00 * slope12  "Additive input (fuel) consumption slope"
    level1 * level9 "Level of simplification in the part-load efficiency representation"
/

param_fuel "Parameters for fuels" /
    emissionIntensity "Intensity of emission from fuel (kg/MWh_fuel)"
    main        "Main fuel of the unit - unless input fuels defined as grids"
    startup     "Startup fuel of the unit, if exists. Can be the same as main fuel - consumption using startupFuelCons"
/

param_unitFuel "Parameters for fuel limits in units" /
    maxFuelCons "Maximum absolute fuel consumption in a unit"
    maxFuelFraction "Maximum share of a fuel in the consumption mix"
/

param_policy "Set of possible data parameters for grid, node, regulation" /
    emissionTax "Emission tax (€/tonne)"
/

param_union "Different ways inputs and outputs of energy conversion units can be combined" /
    fixed "The ratio between different output forms is fixed"
    unbound    "The ratio of this output is not constrained by other forms of energy"
    constrained "The usage is limited by the output of free outputs - in relation to the efficiency limits"
    substitute  "Inputs and outputs can be substituted"
/


param_slack "Possible parameters for node inc_dec penalties" /
    costCoeff "The cost coefficient of the slack category to be used in the objective function"
    maxSlack  "The maximum slack provided"
/
