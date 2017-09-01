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
    tSolveFirst "counter (ord) for the first t in the solve"
    tSolveLast "counter for the last t in the solve"
    tDispatchCurrent "counter for the current t in the dispatch loop" /0/
    tCounter "counter for t" /0/
    lastCounter "last member in use of the general counter"
    ts_length "Length of time series (t)"
    continueLoop "Helper to stop the looping early"
    intervalLength "Legnth of the interval to be calculated, considering end of modelling period"
    count "General counter"
    count_lambda, count_lambda2 "Counter for lambdas"
    cum_slope "Cumulative for slope"
    cum_lambda "Cumulative for lambda"
    heat_rate "Heat rate temporary parameter"
    tmp "General temporary parameter"
    tmp_dist "Temporary parameter for calculating the distance between operating points"
    tmp_op "Temporary parameter for operating point"
    tmp_count_op "Counting the number of valid operating points in the unit data"
    f_improve /12/;
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
    p_fuelEmission(fuel, emission) "Fuel emission content"
    p_uFuel(unit, param_fuel, fuel, param_unitFuel) "Parameters interacting between units and fuels"
    p_unitFuelEmissionCost(unit, fuel, emission) "Emission costs for each unit, calculated from input data"
    p_effUnit(effSelector, unit, effSelector, *)  "Data for piece-wise linear efficiency blocks"
    p_effGroupUnit(effSelector, unit, *) "Unit data specific to a efficiency group (e.g. left border of the unit)"
    p_gnugnu(grid, node, unit, grid, node, unit, param_gnugnu) "Data connecting units in nodes and grids"
    p_uNonoperational(unit, starttype, min_max) "Non-operational time after being shut down before start up"
    p_uStartup(unit, starttype, cost_consumption, unit_capacity) "Startup cost and fuel consumption"
// Time dependent unit & fuel parameters
    ts_unit(unit, *, f, t) "Time dependent unit data, where energy type doesn't matter"
    ts_effUnit(effSelector, unit, effSelector, *, f, t) "Time dependent data for piece-wise linear efficiency blocks"
    ts_effGroupUnit(effSelector, unit, *, f, t) "Time dependent efficiency group unit data"
// Alias used for interval aggregation
    ts_unit_(unit, *, f, t)
;

* --- Probability -------------------------------------------------------------
Parameters
    p_sWeight(s) "Weight of sample"
    p_sProbability(s) "Probability to reach sample conditioned on anchestor samples"
    p_fProbability(f) "Probability of forecast"
    p_sft_probability(s, f, t) "Probability of forecast"
;

Scalar p_sWeightSum "Sum of sample weights";

* --- Model structure ---------------------------------------------------------
Parameters
    pt(t) "Displacement needed to reach the previous time period (in time periods)"
    pf(f, t) "Displacement needed to reach the previous forecast (in forecasts)"
    pf_nReserves(node, restype, f, t) "Forecast index displacement needed to reach the previous forecast when committing reserves."
    cf(f, t) "Displacement needed to reach the current forecast (in forecasts) - this is needed when the forecast tree gets reduced in dynamic equations"
    cf_nReserves(node, restype,  f, t) "Forecast index displacement needed to reach the realization when committing reserves."
    ct(t) "Circular t displacement if the time series data is not long enough to cover the model horizon"
*    t_bind(t) "Displacement to reach the binding time period in the parent sample (in time periods). Can skip with aggregated steps as well as when connecting samples."
*    ft_bind(f, t) "Displacement to reach the binding forecast (in forecasts) in the current model"
*    mt_bind(mType, t) "Displacement to reach the binding time period in the parent sample (in time periods) in the models"
*    mft_bind(mType, f, t) "Displacement to reach the binding forecast (in forecasts) in the models"
    p_slackDirection(slack) "+1 for upward slacks and -1 for downward slacks"
    tForecastNext(mType) "When the next forecast will be availalbe (ord time)"
    aaSolveInfo(mType, t, solveInfoAttributes) "stores information about the solve status"
*    p_uft_online_last(unit, f, t) "Ord of last t where unit is online"
;

* --- Stochastic data parameters ----------------------------------------------
Parameters
    ts_influx(grid, node, f, t) "External power inflow/outflow during a time period (MWh/h)"
    ts_cf(flow, node, f, t) "Available capacity factor time series (per unit)"
    ts_reserveDemand(restype, up_down, node, f, t) "Reserve demand in region in the time period/slice (MW)"
    ts_reserveDemand_(restype, up_down, node, f, t)
    ts_nodeState(grid, node, param_gnBoundaryTypes, f, t) "Fix the states of a node according to time-series form exogenous input"
    ts_fuelPriceChange(fuel, t) "Initial fuel price and consequent changes in fuel price (€/MWh)"
    ts_unavailability(unit, t) "Unavailability of a unit in the time period/slice (p.u.)"
// Aliases used for interval aggregation
    ts_influx_(grid, node, f, t)
    ts_influx_temp(grid, node, f, t)
    ts_cf_(flow, node, f, t)
    ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t)
    ts_forecast(flow, node, t, f, t)
    ts_tertiary(*,node,t,*,t)
;

* --- Other time dependent parameters -----------------------------------------
Parameters
    p_storageValue(grid, node, t) "Value of stored something at the end of a time step"
    p_stepLength(mType, f, t) "Length of a time step (t)"
    p_stepLengthNoReset(mType, f, t) "Length of a time step (t)"
;
