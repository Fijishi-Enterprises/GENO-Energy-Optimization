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
        t_horizon, // Length of the simulation horizon (central forecast)
        t_end, // Last time step of the simulation
        intervalEnd, // End index of a time step interval
        intervalLength, // Number of time steps aggregated within interval
        IntervalInHours, // Length of one time step in hours

        // Samples and Forecasts
        samples, // Number of active samples
        forecasts, // Number of active forecasts
        t_forecastStart, // Time step for first reading the forecasts (not necessarily t_start)
        t_forecastLength, // Length of forecasts in time steps
        t_forecastJump, // Number of time steps between each update of the forecasts
        readForecastsInTheLoop, // Flag for updating forecasts in the solve loop

        // Features
        t_reserveLength, // Length of reserve provision horizon in time steps
        t_aggregate // Unit aggregation threshold time index
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
        / lambda01*lambda12, directOff, directOnLP, directOnMIP / // NOTE! Lambdas required first!
    effDirect(effSelector) "Using direct input to output equation"
        / directOff, directOnLP, directOnMIP /
    effDirectOff(effSelector) "Using direct input to output equation without online variable, i.e. constant efficiency"
        / directOff /
    effDirectOn(effSelector) "Using direct input to output equation with online variable"
        / directOnLP, directOnMIP /
    effLambda(effSelector) "Lambdas in use for part-load efficiency representation"
        / lambda01*lambda12 /
    effOnline(effSelector) "Efficiency selectors that use online variables"
        / directOnLP, directOnMIP, lambda01*lambda12 / // IMPORTANT! Online variables are generated based on this, so keep it up to date!

    // Efficiency Approximation related Counters
    op "Operating points in the efficiency curves, also functions as index for data points"
        /op00*op12/ // IMPORTANT! Has to equal the same param_unit!
    eff "Effiency for the corresponding operating point ('op') in the efficiency curves, also used for data indexing"
        /eff00*eff12/ // IMPORTANT! Has to equal the same param_unit!
    lambda "Lambda approximation indeces"
        /lambda01*lambda12/ // IMPORTANT! Has to equal effLambda!

* --- General and Directional Sets --------------------------------------------

    // General Counter
    counter "general counter set"
        /c000*c999/

    // Directional Sets
    up_down "Direction set used by some variables, e.g. reserve provisions and generation ramps"
        / up, down /
    inc_dec "Increase or decrease in dummy, or slack variables"
        / increase, decrease /
    min_max "Minimum and maximum"
        / min, max /

* --- Model Feature Sets ------------------------------------------------------

    // Reserve Provision Related Sets
    restype "Reserve types" /
        primary "Automatic frequency containment reserves"
        secondary "Fast frequency restoration reserves"
        tertiary "Replacement reserves"
        /
    restypeDirection(restype, up_down) "Different combinations of reserve types and directions" /
        primary.up
        primary.down
        secondary.up
        secondary.down
        tertiary.up
        tertiary.down
        /

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
    unit_capacity "Unit or capacity based parameter"
        / unit, capacity /

    // Other Features
    feature "Set of optional model features" /
        findStorageStart "Solve for optimal storage start levels"
        storageValue     "Use storage value instead of fixed control"
        storageEnd       "Expected storage end levels greater than starting levels"
        addOn            "Use StoSSch as a storage add-on to a larger model"
        extraRes         "Use extra tertiary reserves for error in elec. load during time step"
        rampSched        "Use power based scheduling"
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

// Activate model features if found
Set active(feature) "Set membership tells active model features" /
$if exist 'features.inc' $include 'features.inc'
/;

// Parse command line options and store values for features
$if set findStorageStart active('findStorageStart') = %findStorageStart%;
$if set storageValue active('storageValue') = %storageValue%;
$if set storageEnd active('storageEnd') = %storageEnd%;
$if set addOn active('addOn') = %addOn%;
$if set extraRes active('extraRes') = %extraRes%;
$if set rampSched active('rampSched') = %rampSched%;

* =============================================================================
* --- Parameter Set Definitions -----------------------------------------------
* =============================================================================

Sets

* --- Parameter Data Related Sets ---------------------------------------------

param_gn  "Possible parameters for grid, node" /
    selfDischargeLoss "Self discharge rate of the node [MW/v_state]"
    energyStoredPerUnitOfState "A possible unit conversion if v_state uses something else than MWh"
    boundStart    "A flag to bound the first t in the run using reference constant or time series"
    boundStartAndEnd "A flag that both start and end are bound using reference constant or time series"
    boundEnd      "A flag to bound last t in each solve based on the reference constant or time series"
    boundAll      "A flag to bound the state to the reference in all time steps"
    boundStartToEnd  "Force the last states to equal the first state"
    boundCyclic   "A flag to impose cyclic bounds for the first and the last states within a sample"
    boundCyclicBetweenSamples   "A flag to impose cyclic bounds for the last and first states between samples"
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
    transferCap "Transfer capacity limits"
    transferCapBidirectional "Total bidirectional transfer capacity limit"
    transferLoss "Transfer losses"
    diffCoeff   "Coefficients for energy diffusion between nodes"
    boundStateOffset "Offset parameter for relatively bound node states"
    boundStateMaxDiff "Maximum difference of node state pairs"
    transferCapInvLimit "Capacity limit for investments (MW)"
    investMIP   "Choice of making integer investment instead of continous investment (MW versus number of links)"
    unitSize    "Size of one link for integer investments (MW)"
    invCost "Investment cost (€/MW)"
    annuity "Investment annuity"
/

param_gnu "Set of possible data parameters for grid, node, unit" /
    maxGen      "Maximum output capacity (MW)"
    maxCons     "Maximum loading capacity (MW)"
    cB          "Share of output"
    cV          "Reduction in primary output when increasing secondary output, e.g. reduction of electricity generation due to heat generation in extraction CHP (MWh_e/MWh_h)"
    maxRampUp   "Speed to ramp up (p.u. / min)"
    maxRampDown "Speed to ramp down (p.u. / min)"
    rampUpCost  "Wear and tear cost of ramping up (€/MW)"
    rampDownCost "Wear and tear cost of ramping down (€/MW)"
    maxGenCap   "Maximum output capacity investment (MW)"
    maxConsCap  "Maximum loading capacity investment (MW)"
    minGenCap   "Minimum output capacity investment (MW)"
    minConsCap  "Minimum loading capacity investment (MW)"
    upperLimitCapacityRatio  "Ratio of the upper limit of the node state and the unit capacity investment"
    unitSizeGen "Output capacity of one unit for integer investments (MW)"
    unitSizeCons  "Loading capacity of one unit for integer investments (MW)"
    unitSizeTot "Sum of output and loading capacity of one unit (MW)"
    unitSizeGenNet "Output minus loading capacity of one unit (MW)"
    invCosts    "Investment costs (€/MW)"
    annuity     "Investment annuity"
    inertia  "Inertia of the unit (s)"
    unitSizeMVA "Generator MVA rating (MVA)"
/

param_unit "Set of possible data parameters for units" /
    unitCount   "Number of subunits if aggregated"
    outputCapacityTotal "Output capacity of the unit, calculated by summing all the outputs together by default, unless defined in data"
    availability "Availability of given energy conversion technology (p.u.)"
    omCosts     "Variable operation and maintenance costs (€/MWh)"
    startCostCold "Variable start-up costs for cold starts excluding fuel costs (€/subunit) NOT IN USE"
    startCostWarm "Variable start-up costs for warm starts excluding fuel costs (€/subunit) NOT IN USE"
    startCost "Variable start-up costs for starts excluding fuel costs (€/subunit)"
    startFuelConsCold "Consumption of start-up fuel per subunit started up (MWh_fuel/subunit) NOT IN USE"
    startFuelConsWarm "Consumption of start-up fuel per subunit started up (MWh_fuel/subunit) NOT IN USE"
    startFuelCons "Consumption of start-up fuel per subunit started up (MWh_fuel/subunit)"
    startCostCold_MW "Variable start-up costs for cold starts excluding fuel costs (€/MW) NOT IN USE"
    startCostWarm_MW "Variable start-up costs for warm starts excluding fuel costs (€/MW) NOT IN USE"
    startCost_MW "Variable start-up costs for starts excluding fuel costs (€/MW)"
    startFuelConsCold_MW "Consumption of start-up fuel per capacity started up (MWh_fuel/MW) NOT IN USE"
    startFuelConsWarm_MW "Consumption of start-up fuel per capacity started up (MWh_fuel/MW) NOT IN USE"
    startFuelCons_MW "Consumption of start-up fuel per capacity started up (MWh_fuel/MW)"
    startCold   "Offline hours after which the start-up will be a cold start (h) NOT IN USE"
    startWarm   "Offline hours after which the start-up will be a warm start (h) NOT IN USE"
    minOperationTime "Minimum operation time (h), prevents shutdown after startup until the defined amount of time has passed"
    minShutDownTime "Minimum shut down time (h), prevents starting up again after the defined amount of time has passed"
    SO2         "SO2 emissions (tonne per MWh_fuel)"
    NOx         "NOx emissions (tonne per MWh_fuel)"
    CH4         "CH4 emissions (tonne per MWh_fuel)"
    resTimelim  "How long should a storage be able to provide reserve (h)"
    eff00 * eff12    "Efficiency of the unit to convert input to output/intermediate product"
    opFirstCross "The operating point where the real efficiency curve and approximated efficiency curve cross"
    op00 * op12     "Right border of the efficiency point"
    level1 * level9 "Level of simplification in the part-load efficiency representation"
    useTimeseries "Uses time series form input for unit parameters whenever possible"
    section     "Possibility to define a no load fuel use for units with zero minimum output"
    investMIP   "Choice of making integer investment instead of continous investment (number of units versus MW)"
    maxUnitCount "Maximum number of units when making integer investments"
    minUnitCount "Minimum number of units when making integer investments"
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
    emissionTax "Emission tax (EUR/tonne)"
    update_frequency "Frequency of updating reserve contributions"
    gate_closure "Number of timesteps ahead of dispatch that reserves are fixed"
    use_time_series "Flag for using time series data. !!! REDUNDANT WITH useTimeseries, PENDING REMOVAL !!!"
    reserveContribution "Reliability parameter of reserve provisions"
    emissionCap "Emission limit (tonne)"
    instantaneousShareMax "Maximum instantaneous share of generation and import from a particular group of units and transfer links"
    energyShareMax "Maximum energy share of generation from a particular group of units"
    energyShareMin "Minimum energy share of generation from a particular group of units"
    kineticEnergyMin "Minimum system kinetic energy (MWs)"
/

param_gnugnu "Set of possible data parameters for grid, node, unit, grid, node, unit" /
    capacityRatio "Fixed ratio of the capacity of the first unit to the second"
/

* --- Counters and Directional Sets -------------------------------------------

// Slack categories
slack(param_gnBoundaryTypes) "Categories for slack variables"
       / upwardSlack01*upwardSlack20, downwardSlack01*downwardSlack20 /
upwardSlack(slack) "Set of upward slacks"
       / upwardSlack01*upwardSlack20 /
downwardSlack(slack) "Set of downward slacks"
       / downwardSlack01*downwardSlack20 /

// Flags for boundaries
stateLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / upwardLimit, downwardLimit /
spillLimits(param_gnBoundaryTypes) "set of upward and downward state limits"
       / maxSpill, minSpill /
useConstantOrTimeSeries(param_gnBoundaryProperties) "useTimeSeries and useConstant property together"
       / useTimeSeries, useConstant /
; // END parameter set declarations
