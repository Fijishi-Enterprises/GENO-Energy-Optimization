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

param_gn  "Possible parameters for grid, node" /
*    chargingEff   "Average charging efficiency (p.u)" // NOTE! This isn't actually used for anything at the moment! Probably needs to be removed at some point.
*    dischargingEff "Average discharging efficiency (p.u.)" // NOTE! This isn't actually used for anything at the moment! Probably needs to be removed at some point.
    selfDischargeLoss "Self discharge rate of the node (p.u.)"
    energyStoredPerUnitOfState "A possible unit conversion if v_state uses something else than MWh"
    boundStart    "A flag to bound the first t in the run using reference constant or time series"
    boundStartAndEnd "A flag that both start and end are bound using reference constant or time series"
    boundEnd      "A flag to bound last t in each solve based on the reference constant or time series"
    boundAll      "A flag to bound the state to the reference in all time steps"
    boundStartToEnd  "Force the last states to equal the first state"
    boundCyclic   "A flag to impose cyclic bounds for the first and the last states"
/

param_gnBoundaryTypes "Types of boundaries that can be set for a node with a state variable" /
    upwardLimit   "Absolute maximum state of the node (unit depends on energyCapacity)"
    downwardLimit "Absolute minimum energy in the node (unit depends on energyCapacity)"
    upwardSlack01*upwardSlack20 "A threshold after which a specific cost co-efficient is applied (unit depends on energyCapacity)"
    downwardSlack01*downwardSlack20 "A threshold after which a specific cost co-efficient is applied (unit depends on energyCapacity)"
    reference     "Reference value for a state that can be used to bound a state (unit depends on energyCapacity)"
    maxSpill      "Maximum spill rate from the node (MWh/h)"
    minSpill      "Minimum spill rate from the node (MWh/h)"
/

param_gnBoundaryProperties "Properties that can be set for the different boundaries" /
    useTimeSeries "A flag to use time series to set state bounds and limits"
    useConstant   "A flag to use constant to set state bounds and limits"
    deltaFromReference "The constant or the time series indicate how much the boundary deviates from reference (instead of being an absolute number)"
    constant      "A constant value for the boundary or the reference"
    slackCost     "The cost of exceeding the slack boundary"
    multiplier    "A multiplier to change the value (either constant or time series), default 1"
/

slack(param_gnBoundaryTypes) "Categories for slack variables"
       / upwardSlack01*upwardSlack20, downwardSlack01*downwardSlack20 /
upwardSlack(slack) "Set of upward slacks"
       / upwardSlack01*upwardSlack20 /
downwardSlack(slack) "Set of downward slacks"
       / downwardSlack01*downwardSlack20 /
inc_dec "Increase or decrease in dummy or slack variables"
       / increase, decrease /
stateLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / upwardLimit, downwardLimit /
spillLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / maxSpill, minSpill /
useConstantOrTimeSeries(param_gnBoundaryProperties) "useTimeSeries and useConstant property together"
       / useTimeSeries, useConstant /

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
*    eff00 * eff12    "Efficiency of the unit to convert to certain output or from certain input at different operating points" \\ NOTE! Not currently used in p_gnu
*    rb00 * rb12     "Right border of the efficiency point" \\ NOTE! Not currently used in p_gnu
*    section00   "Input (fuel) consumption at min. load (or at zero)" \\ NOTE! Not currently used in p_gnu
*    slope00 * slope12  "Additive input (fuel) consumption slope" \\ NOTE! Not currently used in p_gnu
/

param_unit "Set of possible data parameters for units" /
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
*    section00   "Input (fuel) consumption at min. load (or at zero)"   // NOT USED ATM!
    slope00 * slope12  "Additive input (fuel) consumption slope"
    level1 * level9 "Level of simplification in the part-load efficiency representation"
    useTimeseries "Uses time series form input for unit parameters whenever possible"
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

*param_union "Different ways inputs and outputs of energy conversion units can be combined" /
*    fixed "The ratio between different output forms is fixed"
*    unbound    "The ratio of this output is not constrained by other forms of energy"
*    constrained "The usage is limited by the output of free outputs - in relation to the efficiency limits"
*    substitute  "Inputs and outputs can be substituted"
*/
