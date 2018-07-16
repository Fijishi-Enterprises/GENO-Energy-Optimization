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
    errorcount /0/
    solveCount /0/
    tSolveFirst "counter (ord) for the first t in the solve"
    tSolveLast "counter for the last t in the solve"
    tCounter "counter for t" /0/
    lastCounter "last member in use of the general counter"
    ts_length "Length of time series (t)"
    continueLoop "Helper to stop the looping early"
    intervalLength "Legnth of the interval to be calculated, considering end of modelling period"
    currentForecastLength "Length of the forecast in the curren solve, minimum of unchanging and decreasing forecast lengths"
    count "General counter"
    count_lambda, count_lambda2 "Counter for lambdas"
    cum_slope "Cumulative for slope"
    cum_lambda "Cumulative for lambda"
    heat_rate "Heat rate temporary parameter"
    tmp "General temporary parameter"
    tmp_ "General temporary parameter"
    tmp__ "General temporary parameter"
    tmp_dist "Temporary parameter for calculating the distance between operating points"
    tmp_op "Temporary parameter for operating point"
    tmp_count_op "Counting the number of valid operating points in the unit data"
    f_improve / 12 /
    tRealizedLast "counter (ord) for the last realized t in the solve"
    firstResultsOutputSolve /1/;
;

* --- Power plant and fuel data -----------------------------------------------
Parameters
    p_gn(grid, node, param_gn) "Properties for energy nodes"
    p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, param_gnBoundaryProperties) "Properties of different state boundaries and limits"
    p_gnn(grid, node, node, param_gnn) "Data for interconnections between energy nodes"
    p_gnu(grid, node, unit, param_gnu) "Unit data where energy type matters"
    p_unit(unit, *) "Unit data where energy type does not matter"
    p_nReserves(node, restype, *) "Data defining the reserve rules in each node"
    p_nuReserves(node, unit, restype, *) "Reserve provision data for units"
    p_gnPolicy(grid, node, param_policy, *) "Policy data for grid, node"
    p_groupPolicy(group, param_policy) "Two-dimensional policy data for groups"
    p_groupPolicy3D(group, param_policy, *) "Three-dimensional policy data for groups"
    p_fuelEmission(fuel, emission) "Fuel emission content"
    p_uFuel(unit, param_fuel, fuel, param_unitFuel) "Parameters interacting between units and fuels"
    p_unitFuelEmissionCost(unit, fuel, emission) "Emission costs for each unit, calculated from input data"
    p_effUnit(effSelector, unit, effSelector, *)  "Data for piece-wise linear efficiency blocks"
    p_effGroupUnit(effSelector, unit, *) "Unit data specific to a efficiency group (e.g. left border of the unit)"
    p_uNonoperational(unit, starttype, min_max) "Non-operational time after being shut down before start up"
    p_uStartup(unit, starttype, cost_consumption, unit_capacity) "Startup cost and fuel consumption"
    p_u_maxOutputInLastRunUpInterval(unit) "Maximum output in the last interval for the run-up to min. load (p.u.)"
    p_u_runUpTimeIntervals(unit) "Time intervals required for the run-up phase"
    p_u_runUpTimeIntervalsCeil(unit) "Ceiling of time intervals required for the run-up phase"
    p_ut_runUp(unit, t) "Output for the time intervals where the unit is being started up to the minimum load (minimum output in the last interval) (p.u.)"
// Time dependent unit & fuel parameters
    ts_unit(unit, *, f, t) "Time dependent unit data, where energy type doesn't matter"
    ts_effUnit(effSelector, unit, effSelector, *, f, t) "Time dependent data for piece-wise linear efficiency blocks"
    ts_effGroupUnit(effSelector, unit, *, f, t) "Time dependent efficiency group unit data"
// Alias used for interval aggregation
    ts_unit_(unit, *, f, t)
;

* --- Probability -------------------------------------------------------------
Parameters
    p_msWeight(mType, s) "Weight of sample"
    p_msProbability(mType, s) "Probability to reach sample conditioned on anchestor samples"
    p_mfProbability(mType, f) "Probability of forecast"
    p_msft_probability(mType, s, f, t) "Probability of forecast"
;

Scalar p_sWeightSum "Sum of sample weights";

* --- Model structure ---------------------------------------------------------
Parameters
    // Time displacement arrays
    dt(t) "Displacement needed to reach the previous time period (in time periods)"
    dt_noReset(t) "Displacement needed to reach the previous time period (in time periods)"
    dt_circular(t) "Circular t displacement if the time series data is not long enough to cover the model horizon"
    dt_next(t) "Displacement needed to reach the next time period (in time periods)"
    dtt(t, t) "Displacement needed to reach any previous time period (in time periods)"
    dt_toStartup(unit, t) "Displacement from the current time period to the time period where the unit has been started up in case online variable changes from 0 to 1"
    dt_starttypeUnitCounter(starttype, unit, counter) "Displacement needed to account for starttype constraints"
    dt_downtimeUnitCounter(unit, counter) "Displacement needed to account for downtime constraints"
    dt_uptimeUnitCounter(unit, counter) "Displacement needed to account for uptime constraints"

    // Forecast displacement arrays
    df(f, t) "Displacement needed to reach the realized forecast on the current time step"
    df_central(f, t) "Displacement needed to reach the central forecast - this is needed when the forecast tree gets reduced in dynamic equations"
    df_nReserves(node, restype, f, t) "Forecast index displacement needed to reach the realized forecast when committing reserves."

    // Temporary displacement arrays
    ddt(t) "Temporary time displacement array."
    ddf(f, t) "Temporary forecast displacement array."
    ddf_(f, t) "Temporary forecast displacement array."

    // Other
    p_slackDirection(slack) "+1 for upward slacks and -1 for downward slacks"
    tForecastNext(mType) "When the next forecast will be availalbe (ord time)"
    aaSolveInfo(mType, t, solveInfoAttributes) "stores information about the solve status"
    msStart(mType, s) "Start point of samples"
    msEnd(mType, s) "End point of samples"
    tOrd(t) "Order of t"
;

* --- Stochastic data parameters ----------------------------------------------
Parameters
    ts_influx(grid, node, f, t) "External power inflow/outflow during a time period (MWh/h)"
    ts_cf(flow, node, f, t) "Available capacity factor time series (per unit)"
    ts_reserveDemand(restype, up_down, node, f, t) "Reserve demand in region in the time period/slice (MW)"
    ts_nodeState(grid, node, param_gnBoundaryTypes, f, t) "Fix the states of a node according to time-series form exogenous input"
    ts_fuelPriceChange(fuel, t) "Initial fuel price and consequent changes in fuel price (�/MWh)"
    ts_fuelPrice(fuel, t) "Fuel price time series (EUR/MWh)"
    ts_unavailability(unit, t) "Unavailability of a unit in the time period/slice (p.u.)"

    // Aliases used for interval aggregation
    ts_influx_(grid, node, f, t)
    ts_influx_temp(grid, node, f, t)
    ts_cf_(flow, node, f, t)
    ts_reserveDemand_(restype, up_down, node, f, t)
    ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t)
    ts_fuelPrice_(fuel, t)
;

* --- Other time dependent parameters -----------------------------------------
Parameters
    p_storageValue(grid, node, t) "Value of stored something at the end of a time step"
    p_stepLength(mType, f, t) "Length of a time step (t)"
    p_stepLengthNoReset(mType, f, t) "Length of a time step (t)"
;
Option clear = p_storageValue; // Required for whatever reason.
