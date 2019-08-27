$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* =============================================================================
* --- Model Related Set Definitions -------------------------------------------
* =============================================================================

Sets

* --- Model Related Selections ------------------------------------------------

    mType "model types in the Backbone" /
        building,
        invest,
        schedule
        /

    mSetting "setting categories for models" /

        // General Time Structure
        t_start, // First time step for the start of simulation
        t_jump, // Number of time steps realized with each solve
        t_horizon, // Length of the simulation horizon in time steps (central forecast)
        t_end, // Last time step of the simulation
        loadPoint, // Load advanced basis; 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
        savePoint, // Save advanced basis; 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
        lastStepInIntervalBlock, // Last time step in the block of intervals with the same length
        stepsPerInterval, // Number of time steps aggregated within interval
        stepLengthInHours, // Length of one time step in hours

        // Samples and Forecasts
        samples, // Number of active samples
        forecasts, // Number of active forecasts
        t_forecastLengthUnchanging, // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
        t_forecastLengthDecreasesFrom, // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
        t_forecastStart, // Time step for first reading the forecasts (not necessarily t_start)
        t_forecastJump, // Number of time steps between each update of the forecasts
        t_improveForecast "Number of time steps ahead of time on which the forecast is improved on each solve"
        t_perfectForesight "Number of time steps for which realized data is used instead of forecasts"
        onlyExistingForecasts "Use only existing forecast values when reading updated forecasts. Note: zero values need to be saved as Eps in the gdx file."
        scenarios        "Number of long-term scenarios used"
        scenarioLength   "Length of scenario in time steps for creating stocahstic scenarios from time series data"

        // Features
        t_trajectoryHorizon, // Length of the horizon when start-up and shutdown trajectories are considered (in time steps)
        t_initializationPeriod,  // Number of time steps in the beginning of the simulation which are solved but the results of which are not stored
        dataLength, // The maximum number of time steps in any input data time series (recommended for correctly circulating data)
        red_num_leaves "Desired number of preserved scenarios or leaves (SCENRED)"
        red_percentage "Desired relative distance (accuracy) of scenario reduction (SCENRED)"
        incHRAdditionalConstraints // Method to include the two additional constraints for incremental heat rates;
                                   // 0 = include for units with non-convex fuel use, 1 = include for all units
        /

    // Solve info
    solveInfoAttributes "Information about model solves" /
        modelStat
        solveStat
        totalTime
        iterations
        nodes
        numEqu
        numDVar
        numVar
        numNZ
        sumInfes
        objEst
        objVal
        /

    // !!! REDUNDANT SETS PENDING REMOVAL !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    solve_info "Containers for solve information" /
        modelStat "Status of the model after solve"
        solveStat "Status of the solve"
        totalTime "Total solve time"
        iterations "Number of iteration"
        nodes "Number of nodes in the solve"
        numEqu "Number of equations in the problem"
        numDVar "Number of D variables in the problem"
        numVar "Number of variables in the problem"
        numNZ "Number of non-zeros in the problem"
        sumInfes "Sum of infeasibilities"
        objEst "Estimate for the best possible objective value"
        objVal "Objectiv value"
        /

* --- Efficiency Approximation Related Sets -----------------------------------

    // Efficiency Levels and Categories
    effLevel "Pre-defined levels for efficiency representation that can start from t_solve + x"
        / level1*level9 /
    effSelector "Select equations and lambdas/slope for efficiency calculations"
        / lambda01*lambda12, directOff, directOnLP, directOnMIP , incHR/ // NOTE! Lambdas required first!
    effDirect(effSelector) "Using direct input to output equation"
        / directOff, directOnLP, directOnMIP /
    effDirectOff(effSelector) "Using direct input to output equation without online variable, i.e. constant efficiency"
        / directOff /
    effDirectOn(effSelector) "Using direct input to output equation with online variable"
        / directOnLP, directOnMIP /
    effLambda(effSelector) "Lambdas in use for part-load efficiency representation"
        / lambda01*lambda12 /
    effIncHR(effSelector) "Using incremental heat rate equation"
        / incHR /
    effOnline(effSelector) "Efficiency selectors that use online variables"
        / directOnLP, directOnMIP, lambda01*lambda12 ,incHR / // IMPORTANT! Online variables are generated based on this, so keep it up to date!

* --- General and Directional Sets --------------------------------------------

    // General Counter
    counter "General counter set"
        /c000*c999/
    cc(counter) "Temporary subset of counter used for calculations"

    // Directional Sets
    up_down "Direction set used by some variables, e.g. reserve provisions and generation ramps"
        / up, down /
    inc_dec "Increase or decrease in dummy, or slack variables"
        / increase, decrease /
    min_max "Minimum and maximum"
        / min, max /

* --- Model Feature Sets ------------------------------------------------------

    // Unit Startup Related Sets
    starttype "Startup types" /
        hot "Hot start"
        warm "Warm start"
        cold "Cold start"
        /
    starttypeConstrained(starttype) "Startup types with constrained maximum non-opearational time"
        / hot, warm /
    cost_consumption "Startup cost or startup fuel consumption"
        / cost, consumption /

    // Other Features
    feature "Set of optional model features" /
*        findStorageStart "Solve for optimal storage start levels" // NOT IMPLEMENTED
        storageValue     "Use storage value instead of fixed control"
*        storageEnd       "Expected storage end levels greater than starting levels" // NOT IMPLEMENTED
*        addOn            "Use StoSSch as a storage add-on to a larger model" // NOT IMPLEMENTED
*        extraRes         "Use extra tertiary reserves for error in elec. load during time step" // NOT IMPLEMENTED
*        rampSched        "Use power based scheduling" // PARTIALLY IMPLEMENTED
        scenRed          "Reduce number of long-tem scenarios using GAMS SCENRED2"
        checkUnavailability "Take into account ts_unit unavailability data"
         /
* --- Set to declare time series that will be read between solves ------------------------------------------------------
    timeseries "Names of time series that could be loop read from files between solves" /
        ts_unit
        ts_effUnit
        ts_effGroupUnit
        ts_influx
        ts_cf
        ts_reserveDemand
        ts_node
        ts_fuelPriceChange
        ts_fuelPrice
        ts_unavailability
        /

; // END Sets

* =============================================================================
* --- Model Parameter Definitions ---------------------------------------------
* =============================================================================

* --- Numeric Model Parameters ------------------------------------------------

// General model parameter arrays
Parameter
*    settings(mSetting)
    mSettings(mType, mSetting) "Model settings array"
    mSettingsEff(mtype, effLevel) "Model efficiency approximation array"
    mInterval(mType, mSetting, counter) "Model interval array"
    t_skip_counter "Numerical counter for solve time steps"
;

// Include additional parameters if found
Parameter params(*) /
$if exist 'params.inc' $include 'params.inc'
/;

// Features
Set active(mType, feature) "Set membership tells active model features";
option clear = active;

* =============================================================================
* --- Parameter Set Definitions -----------------------------------------------
* =============================================================================

Sets

* --- Parameter Data Related Sets ---------------------------------------------

param_gn  "Possible parameters for grid, node" /
    selfDischargeLoss "Self discharge rate of the node (MW/[v_state])"
    energyStoredPerUnitOfState "A possible unit conversion if v_state uses something else than MWh (MWh/[v_state])"
    boundStart    "A flag to bound the first t in the run using reference constant or time series"
    boundStartAndEnd "A flag that both start and end are bound using reference constant or time series"
    boundEnd      "A flag to bound last t in each solve based on the reference constant or time series"
    boundAll      "A flag to bound the state to the reference in all time steps"
    boundStartToEnd  "Force the last states to equal the first state"
    forecastLength "Length of forecasts in use for the node (hours). After this, the node will use the central forecast."
    capacityMargin "Capacity margin used in invest mode (MW)"
/

param_gnBoundaryTypes "Types of boundaries that can be set for a node with a state variable" /
    upwardLimit   "Absolute maximum state of the node (unit depends on energyCapacity)"
    downwardLimit "Absolute minimum energy in the node (unit depends on energyCapacity)"
    upwardSlack01*upwardSlack20 "A threshold after which a specific cost co-efficient is applied (unit depends on energyCapacity)"
    downwardSlack01*downwardSlack20 "A threshold after which a specific cost co-efficient is applied (unit depends on energyCapacity)"
    reference     "Reference value for a state that can be used to bound a state (unit depends on energyCapacity)"
    maxSpill      "Maximum spill rate from the node (MWh/h)"
    minSpill      "Minimum spill rate from the node (MWh/h)"
    balancePenalty "Penalty value for violating the energy balance of that particular node (EUR/MWh) (can be interpretated as the energy price in certain settings)"
/

param_gnBoundaryProperties "Properties that can be set for the different boundaries" /
    useTimeSeries "A flag to use time series to set state bounds and limits"
    useConstant   "A flag to use constant to set state bounds and limits"
    deltaFromReference "The constant or the time series indicate how much the boundary deviates from reference (instead of being an absolute number)"
    constant      "A constant value for the boundary or the reference"
    slackCost     "The cost of exceeding the slack boundary"
    multiplier    "A multiplier to change the value (either constant or time series), default 1"
/

param_gnn "Set of possible data parameters for grid, node, node (nodal interconnections)" /
    transferCap   "Transfer capacity limits (MW)"
    transferCapBidirectional "Total bidirectional transfer capacity limit (MW)"
    transferLoss  "Transfer losses"
    diffCoeff     "Coefficients for energy diffusion between nodes (MW/[v_state])"
    boundStateMaxDiff "Maximum difference of node state pairs ([v_state])"
    transferCapInvLimit "Capacity limit for investments (MW)"
    investMIP     "A flag to make integer investment instead of continous investment (MW versus number of links)"
    unitSize      "Size of one link for integer investments (MW)"
    invCost       "Investment cost (EUR/MW)"
    annuity       "Investment annuity"
    ReservePortion "Portion to cover incase fail"
/

param_gnu "Set of possible data parameters for grid, node, unit" /
    maxGen        "Maximum output capacity (MW)"
    maxCons       "Maximum loading capacity (MW)"
    useInitialGeneration     "A flag to indicate whether to fix generation for the first time step (binary)"
    initialGeneration        "Initial generation/consumption of the unit in the first time step (MW)"
    conversionFactor "Conversion factor for inputs or outputs (for changing the unit of measurement)"
    doNotOutput   "Flag for inputs that are not included in the output commodities"
    cV            "Reduction in primary output when increasing secondary output, e.g. reduction of electricity generation due to heat generation in extraction CHP (MWh_e/MWh_h)"
    maxRampUp     "Speed to ramp up (p.u./min)"
    maxRampDown   "Speed to ramp down (p.u./min)"
    upperLimitCapacityRatio  "Ratio of the upper limit of the node state and the unit capacity investment ([v_state]/MW)"
    unitSizeGen   "Output capacity of one subunit for integer investments (MW)"
    unitSizeCons  "Loading capacity of one subunit for integer investments (MW)"
    unitSizeTot   "Sum of output and loading capacity of one subunit (MW)"
    invCosts      "Investment costs (EUR/MW)"
    annuity       "Investment annuity factor"
    fomCosts      "Fixed operation and maintenance costs (EUR/MW/a)"
    inertia       "Inertia of the unit (s)"
    unitSizeMVA   "Generator MVA rating of one subunit (MVA)"
    availabilityCapacityMargin  "Availability of the unit in the capacity margin equation (p.u.). If zero, v_gen is used. Currently used only for output capacity."
/

param_gnuBoundaryProperties "Properties that can be set for the different boundaries" /
    rampLimit     "Maximum ramp speed (p.u./min)"
    rampCost      "Wear and tear cost of ramping up (EUR/MW)"
/

param_unit "Set of possible data parameters for units" /
    unitCount     "Number of subunits if aggregated"
    outputCapacityTotal "Output capacity of the unit, calculated by summing all the outputs together by default, unless defined in data"
    unitOutputCapacityTotal "Output capacity of the unit, calculated by summing all the subunit output sizes together by default"
    availability  "Availability of given energy conversion technology (p.u.)"
    useInitialOnlineStatus   "A flag to fix the online status of a unit for the first time step (binary)"
    initialOnlineStatus      "Initial online status of the unit in the first time step (0-1)"
    unavailability  "Unavailability of given energy conversion technology (p.u.)"
    omCosts       "Variable operation and maintenance costs (EUR/MWh)"
    startCostCold "Variable start-up costs for cold starts excluding fuel costs (EUR/MW)"
    startCostWarm "Variable start-up costs for warm starts excluding fuel costs (EUR/MW)"
    startCostHot  "Variable start-up costs for hot starts excluding fuel costs (EUR/MW)"
    startFuelConsCold "Consumption of start-up fuel per cold subunit started up (MWh_fuel/MW)"
    startFuelConsWarm "Consumption of start-up fuel per warm subunit started up (MWh_fuel/MW)"
    startFuelConsHot "Consumption of start-up fuel per hot subunit started up (MWh_fuel/MW)"
    startColdAfterXhours "Offline hours after which the start-up will be a cold start (h)"
    startWarmAfterXhours "Offline hours after which the start-up will be a warm start (h)"
    shutdownCost  "Cost of shutting down the unit"
    rampSpeedToMinLoad "Ramping speed from start-up to minimum load (p.u./min)"
    rampSpeedFromMinLoad "Ramping speed from shutdown decision to zero load (p.u./min)"
    minOperationHours "Minimum operation time (h), prevents shutdown after startup until the defined amount of time has passed"
    minShutdownHours "Minimum shut down time (h), prevents starting up again after the defined amount of time has passed"
    SO2           "SO2 emissions (tonne per MWh_fuel)"
    NOx           "NOx emissions (tonne per MWh_fuel)"
    CH4           "CH4 emissions (tonne per MWh_fuel)"
    resTimelim    "How long should a storage be able to provide reserve (h)"
    eff00 * eff12 "Efficiency of the unit to convert input to output/intermediate product"
    opFirstCross  "The operating point where the real efficiency curve and approximated efficiency curve cross"
    op00 * op12   "Right border of the efficiency point"
    hr00 * hr12   "Incremental heat rates (GJ/MWh)"
    hrop00 * hrop12   "Right border of the incremental heat rates"
    section       "Possibility to define a no load fuel use for units with zero minimum output"
    hrsection     "no load fuel use to be defined when using incremental heat rates"
    level1 * level9 "Level of simplification in the part-load efficiency representation"
    useTimeseries "A flag to use time series form input for unit parameters whenever possible"
    investMIP     "A flag to make integer investment instead of continous investment"
    maxUnitCount  "Maximum number of units when making integer investments"
    minUnitCount  "Minimum number of units when making integer investments"
    lastStepNotAggregated "Last time step when the unit is not yet aggregated - calculated in inputsLoop.gms for units that have aggregation"
/

param_eff "Parameters used for unit efficiency approximations" /
    lb      "Minimum load of the unit"
    op      "Maximum load of the unit, or the operating point of the SOS2 variable in the piecewise linear heat rate approximation (lambda)"
    section "Operational heat rate of the unit, or the SOS2 variable in the piecewise linear heat rate approximation (lambda)"
    slope   "Heat rate parameter representing no-load fuel consumption"
/

param_fuel "Parameters for fuels" /
    main          "Main fuel of the unit - unless input fuels defined as grids"
    startup       "Startup fuel of the unit, if exists. Can be the same as main fuel - consumption using startupFuelCons"
/

param_fuelPrice "Paramters for fuel prices" /
    fuelPrice     "Fuel price (EUR/MWh)"
    useConstant   "Flag to use constant data for fuels"
    useTimeSeries "Flag to use time series form data for fuels"
/

param_unitFuel "Parameters for fuel limits in units" /
    maxFuelCons   "Maximum absolute fuel consumption in a unit - not used for start-up fuels"
    maxFuelFraction "Maximum share of a fuel in the consumption mix"   //only for main fuels
    fixedFuelFraction "Fixed share of a fuel in the consumption mix"   //only for start-up fuels
/

param_policy "Set of possible data parameters for grid, node, regulation" /
    emissionTax   "Emission tax (EUR/tonne)"
    emissionCap   "Emission limit (tonne)"
    instantaneousShareMax "Maximum instantaneous share of generation and import from a particular group of units and transfer links"
    energyShareMax "Maximum energy share of generation from a particular group of units"
    energyShareMin "Minimum energy share of generation from a particular group of units"
    kineticEnergyMin "Minimum system kinetic energy (MWs)"
    constrainedCapMultiplier "Multiplier a(i) for unit investments in equation Sum(i, a(i)*v_invest(i)) <= b"
    constrainedCapTotalMax "Total maximum b for unit investments in equation Sum(i, a(i)*v_invest(i)) <= b"
    constrainedOnlineMultiplier "Multiplier a(i) for online units in equation Sum(i, a(i)*v_online(i)) <= b"
    constrainedOnlineTotalMax "Total maximum b for online units in equation Sum(i, a(i)*v_online(i)) <= b"
    minCons "minimum consumption of storage unit when charging"
    // Reserve related parameters, currently without a proper parameter set
    update_frequency "Frequency of updating reserve contributions"
    update_offset "Optional offset for delaying the reserve update frequency"
    gate_closure  "Number of timesteps ahead of dispatch that reserves are fixed"
    use_time_series "Flag for using time series data. !!! REDUNDANT WITH useTimeseries, PENDING REMOVAL !!!"
    reserve_length "Length of reserve horizon"
    reserveReliability "Reliability parameter of reserve provisions"
    reserve_increase_ratio "Unit output is multiplied by this factor to get the increase in reserve demand"
    portion_of_infeed_to_reserve "Proportion of the generation of a tripping unit that needs to be covered by reserves from other units"
/

* --- Efficiency Approximation Related Sets -----------------------------------

// Efficiency Approximation related Counters
op(param_unit) "Operating points in the efficiency curves, also functions as index for data points"
        /op00*op12/ // IMPORTANT! Has to equal the same param_unit!
eff(param_unit) "Effiency for the corresponding operating point ('op') in the efficiency curves, also used for data indexing"
        /eff00*eff12/ // IMPORTANT! Has to equal the same param_unit!
lambda "Lambda approximation indeces"
        /lambda01*lambda12/ // IMPORTANT! Has to equal effLambda!
hrop(param_unit) "Operating points in the incremental heat rate curves, also functions as index for data points"
        /hrop00*hrop12/ // IMPORTANT! Has to equal the same param_unit!
hr(param_unit) "Heat rate for the corresponding operating point ('hrop') in the heat rate curves, also used for data indexing"
        /hr00*hr12/ // IMPORTANT! Has to equal the same param_unit!
* --- Counters and Directional Sets -------------------------------------------

// Slack categories
slack(param_gnBoundaryTypes) "Categories for slack variables"
       / upwardSlack01*upwardSlack20, downwardSlack01*downwardSlack20 /
upwardSlack(param_gnBoundaryTypes) "Set of upward slacks"
       / upwardSlack01*upwardSlack20 /
downwardSlack(param_gnBoundaryTypes) "Set of downward slacks"
       / downwardSlack01*downwardSlack20 /

// Flags for boundaries
stateLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / upwardLimit, downwardLimit /
spillLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / maxSpill, minSpill /
useConstantOrTimeSeries(param_gnBoundaryProperties) "useTimeSeries and useConstant property together"
       / useTimeSeries, useConstant /
; // END parameter set declarations
