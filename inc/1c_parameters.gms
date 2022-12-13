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

* --- Internal counters -------------------------------------------------------
Scalars
    solveCount /0/
    t_solveFirst "counter (ord) for the first t in the solve"
    t_solveLast "counter for the last t in the solve"
    tCounter "counter for t" /0/
    lastCounter "last member in use of the general counter"
    continueLoop "Helper to stop the looping early"
    currentForecastLength "Length of the forecast in the curren solve, minimum of unchanging and decreasing forecast lengths"
    count "General counter"
    count_lambda
    count_lambda2 "Counter for lambdas"
    count_sample "Counter for samples"
    cum_slope "Cumulative for slope"
    cum_lambda "Cumulative for lambda"
    heat_rate "Heat rate temporary parameter"
    tmp "General temporary parameter"
    tmp_ "General temporary parameter"
    tmp__ "General temporary parameter"
    tmp_dt "Temporary parameter for evaluating the necessary amount of historical timesteps"
    tmp_dist "Temporary parameter for calculating the distance between operating points"
    tmp_op "Temporary parameter for operating point"
    tmp_count_op "Counting the number of valid operating points in the unit data"
    tmp_offset "Offset of sample in time steps"
    tRealizedLast "counter (ord) for the last realized t in the solve"
    firstResultsOutputSolve /1/;
;


* --- Power plant and commodity data -----------------------------------------------
* initiating optional input data tables with empty
$onempty
Parameters
    p_gn(grid, node, param_gn)         "Properties for energy nodes"
    p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, param_gnBoundaryProperties) "Properties of different state boundaries and limits" / /
    p_storageValue(grid, node)         "Constant value of stored something at the end of a time step (EUR/<v_state_unit>)" / /
    p_gnn(grid, node, node, param_gnn) "Data for interconnections between energy nodes" / /
    p_gnu(grid, node, unit, param_gnu) "Unit data where energy type matters. Automatically calculated from input data p_gnu_io."
    p_gnu_io(grid, node, unit, input_output, param_gnu) "Unit data where energy type matters"
    p_gnuBoundaryProperties(grid, node, unit, slack, param_gnuBoundaryProperties) "Properties for unit boundaries where energy type matters" / /
    p_unit(unit, param_unit)           "Unit data where energy type does not matter"
    p_unitConstraint(unit, constraint) "Constant for constraints (eq1-9, gt1-9) between inputs and/or outputs. Each unit have their own (eq1-9, gt1-9)." / /
    p_unitConstraintNode(unit, constraint, node) "Coefficients for constraints (eq1-9, gt1-9) between inputs and/or outputs" / /
    p_gnReserves(grid, node, restype, param_policy) "Data defining the reserve rules in each node"
    p_groupReserves(group, restype, param_policy) "Data defining the reserve rules in each node group" / /
    p_groupReserves3D(group, restype, up_down, param_policy) "Reserve policy in each node group separately for each reserve type and direction" / /
    p_groupReserves4D(group, restype, up_down, group, param_policy) "Reserve policy in each node group separately for each reserve type and direction, also linking to another group" / /
    p_gnuReserves(grid, node, unit, restype, param_policy) "Reserve provision data for units" / /
    p_gnnReserves(grid, node, node, restype, up_down) "Reserve provision data for node node connections" / /
    p_gnuRes2Res(grid, node, unit, restype, up_down, restype) "The first type of reserve can be used also in the second reserve category (with a possible multiplier)" / /
    p_groupPolicy(group, param_policy) "Two-dimensional policy data for groups" / /
    p_groupPolicyUnit(group, param_policy, unit) "Three-dimensional policy data for groups and units" / /
    p_groupPolicyEmission(group, param_policy, emission) "Three-dimensional policy data for groups and emissions" / /
    p_price(node, param_price)         "Commodity price parameters"
    p_emissionPrice(emission, group, param_price) "emission price parameters (EUR/tEmission)"
    p_nEmission(node, emission)        "Emission content (tEmission/MWh)" / /
    p_gnuEmission(grid, node, unit, emission, param_gnuEmission) "unit data of emission factors for investments, maintenance, and energy" / /
    p_uStartupfuel(unit, node, param_unitStartupfuel) "Parameters for startup fuels" / /
    p_unStartup(unit, node, starttype) "Consumption during the start-up (MWh/start-up)"
    p_effUnit(effSelector, unit, effSelector, param_eff)  "Data for piece-wise linear efficiency blocks"
    p_effGroupUnit(effSelector, unit, param_eff) "Unit data specific to a efficiency group (e.g. left border of the unit)"
    p_uNonoperational(unit, starttype, min_max) "Non-operational time after being shut down before start up"
    p_uStartup(unit, starttype, cost_consumption) "Startup cost and fuel consumption"
    p_u_maxOutputInLastRunUpInterval(unit) "Maximum output in the last interval for the run-up to min. load (p.u.)"
    p_u_maxRampSpeedInLastRunUpInterval(unit) "Maximum ramp speed in the last interval for the run-up to min. load (p.u.)"
    p_u_runUpTimeIntervals(unit)       "Time steps required for the run-up phase"
    p_u_runUpTimeIntervalsCeil(unit)   "Ceiling of time steps required for the run-up phase"
    p_uCounter_runUpMin(unit, counter) "Minimum output for the time steps where the unit is being started up to the minimum load (minimum output in the last interval) (p.u.)"
    p_uCounter_runUpMax(unit, counter) "Maximum output for the time steps where the unit is being started up to the minimum load (minimum output in the last interval) (p.u.)"
    p_u_maxOutputInFirstShutdownInterval(unit) "Maximum output in the first interval for the shutdown from min. load (p.u.)"
    p_uShutdown(unit, cost_consumption) "Shutdown cost per unit"
    p_u_shutdownTimeIntervals(unit)     "Time steps required for the shutdown phase"
    p_u_shutdownTimeIntervalsCeil(unit) "Floor of time steps required for the shutdown phase"
    p_uCounter_shutdownMin(unit, counter) "Minimum output for the time steps where the unit is being shut down from the minimum load (minimum output in the first interval) (p.u.)"
    p_uCounter_shutdownMax(unit, counter) "Maximum output for the time steps where the unit is being shut down from the minimum load (minimum output in the first interval) (p.u.)"
    p_u_minRampSpeedInLastRunUpInterval(unit) "Minimum ramp speed in the last interval for the run-up to min. load (p.u./min)"
    p_u_minRampSpeedInFirstShutdownInterval(unit) "Minimum ramp speed in the fist interval for the shutdown from min. load (p.u./min)"
// Time dependent unit & commodity parameters
    ts_unit(unit, param_unit, f, t) "Time dependent unit data, where energy type doesn't matter"
    ts_effUnit(effSelector, unit, effSelector, param_eff, f, t) "Time dependent data for piece-wise linear efficiency blocks"
    ts_effGroupUnit(effSelector, unit, param_eff, f, t) "Time dependent efficiency group unit data"
// Alias used for interval aggregation
    ts_unit_(unit, param_unit, f, t)
*    ts_effUnit_(effSelector, unit, effSelector, param_eff, f, t)
*    ts_effGroupUnit_(effSelector, unit, param_eff, f, t)
;
$offempty

* --- Probability -------------------------------------------------------------
Parameters
    p_msWeight(mType, s) "Temporal weight of sample: number of similar periods represented by sample s (0-1)"
    p_msAnnuityWeight(mType, s) "Temporal weight of sample: used when calculating annuities (0-1)"
    p_msProbability(mType, s) "Probability to reach sample conditioned on ancestor samples (0-1)"
    p_mfProbability(mType, f) "Probability of forecast (0-1)"
    p_msft_probability(mType, s, f, t) "Probability of forecast (0-1)"
    p_sProbability(s) "Probability of sample (0-1)"
;

Scalar p_sWeightSum "Sum of sample weights";

* --- Model structure ---------------------------------------------------------
Parameters
    // Time displacement arrays
    dt(t) "Displacement needed to reach the previous time interval (in time steps)"
    dt_circular(t) "Circular t displacement if the time series data is not long enough to cover the model horizon"
    dt_next(t) "Displacement needed to reach the next time interval (in time steps)"
    dt_active(t) "Displacement needed to reach the corresponding active time interval from any time interval (in time steps)"
    dt_toStartup(unit, t) "Displacement from the current time interval to the time interval where the unit was started up in case online variable changes from 0 to 1 (in time steps)"
    dt_toShutdown(unit, t) "Displacement from the current time interval to the time interval where the shutdown phase began in case generation becomes 0 (in time steps)"
    dt_starttypeUnitCounter(starttype, unit, counter) "Displacement needed to account for starttype constraints (in time steps)"
    dt_downtimeUnitCounter(unit, counter) "Displacement needed to account for downtime constraints (in time steps)"
    dt_uptimeUnitCounter(unit, counter) "Displacement needed to account for uptime constraints (in time steps)"
    dt_trajectory(counter) "Run-up/shutdown trajectory time index displacement"

    // Forecast displacement arrays
    df(f, t) "Displacement needed to reach the realized forecast on the current time step"
    df_central(f, t) "Displacement needed to reach the central forecast - this is needed when the forecast tree gets reduced in dynamic equations"
    df_reserves(grid, node, restype, f, t) "Forecast index displacement needed to reach the realized forecast when committing reserves"
    df_reservesGroup(group, restype, f, t) "Forecast index displacement needed to reach the realized forecast when committing reserves"
    df_realization(f, t) "Displacement needed to reach the realized forecast on the current time step when no forecast is available"

    // Sample displacement arrays
    ds(s, t) "Displacement needed to reach the sample of previous time step"
    ds_state(grid, node, s, t) "Displacement needed to reach the sample of previous time step at this node"

    // Temporary displacement arrays
    ddt(t) "Temporary time displacement array"
    ddf(f) "Temporary forecast displacement array"
    ddf_(f) "Temporary forecast displacement array"

    // Other
    p_slackDirection(param_gnBoundaryTypes) "+1 for upward slacks and -1 for downward slacks"
    tForecastNext(mType) "When the next forecast will be available (ord time)"
    msStart(mType, s) "Start point of samples: first time step in the sample"
    msEnd(mType, s) "End point of samples: first time step not in the sample"
    tOrd(t) "Order of t"
;

* --- Stochastic data parameters ----------------------------------------------
$onempty
Parameters   // optional parameter tables initiated as empty tables
    // Used mostly for raw data storage
    ts_influx(grid, node, f, t) "External power inflow/outflow during a time step (MWh/h)" / /
    ts_cf(flow, node, f, t) "Available capacity factor time series (p.u.)" / /
    ts_reserveDemand(restype, up_down, group, f, t) "Reserve demand in region in the time step (MW)" / /
    ts_node(grid, node, param_gnBoundaryTypes, f, t) "Time-series for node constraints (<v_state_unit>) or balance penalty cost (EUR / <v_state_unit>)" / /
    ts_unitConstraintNode(unit, constraint, node, f, t) "Time series coefficients for constraints (eq1-9, gt1-9) between inputs and/or outputs" / /
    ts_gnn(grid, node, node, param_gnn, f, t) "Time dependent interconnection data (unit depending on parameter)" / /
    ts_storageValue(grid, node, f, t) "Timeseries of storage value at the end of a time step (EUR/<v_state_unit>)" / /
    ts_price(node, t) "Commodity price (EUR/MWh). Values are read directly from input data or calculated from ts_priceChange. Can use both, but only one option for each node allowed." / /
    ts_priceChange(node, t) "Initial commodity price and consequent changes in commodity price (EUR/MWh)" / /
    ts_emissionPrice(emission, group, t) "Emission group price time series (EUR/tEmission)" / /
    ts_emissionPriceChange(emission, group, t) "Initial emission group price and consequent changes in price (EUR/tEmission)" / /
;
$offempty
Parameters
    // static cost parameters
    p_vomCost(grid, node, unit, param_price) "Calculated static O&M cost that includes O&M costs, fuel costs, and emission costs (EUR/MWh)"
    p_startupCost(unit, starttype, param_price) "Calculated static startup cost that includes startup costs, fuel costs, and emission costs (EUR/MW)"

    // Aliases used in the equations after processing values for looping including time step aggregation if required
    ts_influx_(grid, node, s, f, t) "ts_influx values processed for looping including time step aggregation if required (MWh/h)"
    ts_cf_(flow, node, s, f, t) "ts_cf values processed for looping including time step aggregation if required (p.u.)"
    ts_reserveDemand_(restype, up_down, group, f, t) "ts_reserveDemand values processed for looping including time step aggregation if required (MW)"
    ts_node_(grid, node, param_gnBoundaryTypes, s, f, t) "ts_node values processed for looping including time step aggregation if required (unit depending on parameter)"
    ts_unitConstraintNode_(unit, constraint, node, s, f, t) "ts_unitConstraintNode values processed for looping including time step aggregation if required (coefficient of constraint)"
    ts_gnn_(grid, node, node, param_gnn, f, t) "ts_gnn values processed for looping including time step aggregation if required (unit depending on parameter)"
    ts_storageValue_(grid, node, s, f, t) "ts_storageValue values processed for looping including time step aggregation if required (EUR/<v_state_unit>)"
    ts_price_(node, t) "Commodity price (EUR/MWh) for aggregated time steps"
    ts_emissionPrice_(emission, group, t) "Emission group price time series  for aggregated time steps (EUR/tEmission)"
    ts_vomCost_(grid, node, unit, t) "Calculated time dependent O&M cost that includes O&M cost, fuel cost and emission cost (EUR/MWh)"
    ts_startupCost_(unit, starttype, t) "Calculated time dependent startup cost that includes startup cost, fuel cost and emission cost (EUR/MW)"

    // Aliases used for updating data in inputsLoop.gms
    ts_unit_update(unit, param_unit, f, t)
    ts_effUnit_update(effSelector, unit, effSelector, param_eff, f, t)
    ts_effGroupUnit_update(effSelector, unit, param_eff, f, t)
    ts_influx_update(grid, node, f, t)
    ts_cf_update(flow, node, f, t)
    ts_reserveDemand_update(restype, up_down, group, f, t)
    ts_node_update(grid, node, param_gnBoundaryTypes, f, t)
    ts_gnn_update(grid, node, node, param_gnn, f, t)

    // Help parameters for calculating smoothening of time series
    ts_influx_std(grid, node, t)  "Standard deviation of ts_influx over samples"
    ts_cf_std(flow, node, t) "Standard deviation of ts_cf over samples (p.u.)"

;

* --- Other time dependent parameters -----------------------------------------
$onempty
Parameters
    p_stepLength(mType, f, t) "Length of an interval in hours"
    p_stepLengthNoReset(mType, f, t) "Length of an interval in hours - includes also lengths of previously realized intervals"
    p_s_discountFactor(s) "Discount factor for samples for objective function. Allows multiyear modelling." / /
;
$offempty
