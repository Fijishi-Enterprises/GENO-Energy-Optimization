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

Sets
* --- Geography ---------------------------------------------------------------
    grid "Forms of energy endogenously presented in the model"
    node "Nodes where different types of energy are converted"

* --- Fuels & resources -------------------------------------------------------
    emission "Emissions"
    fuel "Fuels"
    flow "Flow based energy resources (time series)"

* --- Energy generation and consumption ---------------------------------------
    unit "Set of generators, storages and loads"
    unit_flow(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
    unit_fuel(unit) "Units using a commercial fuel"
    unit_minLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unit_online(unit) "Units that have an online variable in the first effLevel level1"
    unit_online_LP(unit) "Units that have an LP online variable in the first effLevel level1"
    unit_online_MIP(unit) "Units that have an MIP online variable in the first effLevel level1"
    unit_aggregator(unit) "Aggregator units aggragating several units"
    unit_aggregated(unit) "Units that are aggregated"
    unit_noAggregate(unit) "Units that are not aggregated and are not aggregators"
    unit_slope(unit) "Units with piecewise linear efficiency constraints"
    unit_noSlope(unit) "Units without piecewise linear efficiency constraints"
    unitAggregator_unit(unit, unit) "Aggregate unit linked to aggregated units"
    unitUnitEffLevel(unit, unit, EffLevel) "Aggregator unit linke to aggreted units with a definition when to start the aggregation"
    flowUnit(flow, *) "Units or storages linked to a certain energy flow time series"
    unitUnittype(unit, *) "Link generation technologies to types"
    unitStarttype(unit, starttype) "Units with special startup properties"
    uFuel(unit, param_fuel, fuel) "Units linked with fuels"
    unittype "Unit technology types"
    unit_investLP(unit) "Units with continuous investments allowed"
    unit_investMIP(unit) "Units with integer investments allowed"
    unit_current(unit) "Current unit"

* --- Nodes -------------------------------------------------------------------
    node_spill(node) "Nodes that can spill; used to remove v_spill variables where not relevant"
    flowNode(flow, node) "Nodes with flows"

* --- Sets bounding geography and units ---------------------------------------
    gn(grid, node) "Grids and their nodes"
* NOTE! Should it be possible to permit time-series form upper or lower bounds on states? If so, then gn() needs rethinking.
    gn2n(grid, node, node) "All (directional) transfer links between nodes in specific energy grids"
    gn2n_directional(grid, node, node) "Transfer links with positive rightward transfer and negative leftward transfer"
    gn2n_directional_investLP(grid, node, node) "Transfer links with with continuous investments allowed"
    gn2n_directional_investMIP(grid, node, node) "Transfer links with with integer investments allowed"
    gnu(grid, node, unit) "Units in specific nodes of particular energy grids"
    gnu_input(grid, node, unit) "Forms of energy the unit uses as endogenous inputs"
    gnu_output(grid, node, unit) "Forms of energy the unit uses as endogenous outputs"
    nu(node, unit) "Units attached to particular nodes"
    gn_state(grid, node) "Nodes with a state variable"
    gn_stateSlack(grid, node) "Nodes with a state slack variable"
    gnn_state(grid, node, node) "Nodes with state variables interconnected via diffusion"
    gnn_boundState(grid, node, node) "Nodes with state variables bound by other nodes"
    gn2gnu(grid, node, grid, node, unit) "Conversions between energy grids by specific units"
    gngnu_fixedOutputRatio(grid, node, grid, node, unit) "Units with a fixed ratio between two different grids of output (e.g. backpressure)"
    gngnu_constrainedOutputRatio(grid, node, grid, node, unit) "Units with a constrained ratio between two different grids of output (e.g. extraction)"

* --- Reserve types -----------------------------------------------------------
    restype "Reserve types"
    restypeDirection(restype, up_down) "Different combinations of reserve types and directions"
    restypeDirectionNode(restype, up_down, node) "Nodes with reserve requirements"
    nuRescapable(restype, up_down, node, unit) "Units capable and available to provide particular reserves"
    restypeReleasedForRealization(restype) "Reserve types that are released for the realized time intervals"

* --- Sets to define time, forecasts and samples ------------------------------
    $$include 'input/timeAndSamples.inc'
    m(mType) "model(s) in use"
    t_full(t) "Full set of time steps in the current model"
    t_current(t) "Set of time steps within the current solve horizon"
    t_active(t) "Set of active t:s within the current solve horizon"
    t_activeNoReset(t) "Set of active t:s within the current solve horizon and previously realized t:s"
    t_invest(t) "Time steps when investments can be made"
    tt(t) "Temporary subset for time steps used for calculations"
    tt_interval(t) "Temporary time steps when forming the ft structure"
    tt_forecast(t) "Temporary subset for time steps used for forecast updating during solve loop"
    mf(mType, f) "Forecasts present in the models"
    ms(mType, s) "Samples present in the models"
    mst_start(mType, s, t) "Start point of samples"
    mst_end(mType, s, t) "Last point of samples"
    ft(f, t) "Combination of forecasts and t:s in the current solve"
    ft_realized(f, t) "Realized ft"
    ft_realizedNoReset(f, t) "Full set of realized ft, facilitates calculation of results"
    mft_nReserves(node, restype, mType, f, t) "Combination of forecasts and t:s locked due to committing reserves ahead of time."
    mft(mType, f, t) "Combination of forecasts and t:s in the current model solve"
    msf(mType, s, f) "Combination of samples and forecasts in the models"
    msft(mType, s, f, t) "Combination of samples, forecasts and t:s in the current model solve"
    msft_realizedNoReset(mType, s, f, t) "Combination of realized samples, forecasts and t:s in the current model solve and previously realized t:s"
    mft_start(mType, f, t) "Start point of the current model solve"
    mf_realization(mType, f) "fRealization of the forecasts"
    mf_central(mType, f) "Forecast that continues as sample(s) after the forecast horizon ends"
    ms_initial(mType, s) "Sample that presents the realized/forecasted period"
    ms_central(mType, s) "Sample that continues the central forecast after the forecast horizon ends"
    mft_lastSteps(mType, f, t) "Last interval of the current model solve"
    modelSolves(mType, t) "when different models are to be solved"
    f_solve(f) "forecasts in the model to be solved next"
    t_latestForecast(t) "t for the latest forecast that is available"

* --- Sets used for the changing unit aggregation and efficiency approximations
    uft(unit, f, t) "Active units on intervals, enables aggregation of units for later intervals"
    uft_online(unit, f, t) "Units with any online and startup variables on intervals"
    uft_onlineLP(unit, f, t) "Units with LP online and startup variables on intervals"
    uft_onlineMIP(unit, f, t) "Units with MIP online and startup variables on intervals"
    uft_startupTrajectory(unit, f, t) "Units with start-up trajectories on intervals"
    uft_shutdownTrajectory(unit, f, t) "Units with shutdown trajectories on intervals"
    nuft(node, unit, f, t) "Enables aggregation of nodes and units for later intervals"
    gnuft(grid, node, unit, f, t) "Enables aggregation of nodes and units for later intervals"
    gnuft_ramp(grid, node, unit, f, t) "Units with ramp requirements or costs"
    gnuft_rampCost(grid, node, unit, slack, f, t) "Units with ramp costs"
    suft(effSelector, unit, f, t) "Selecting conversion efficiency equations"
    sufts(effSelector, unit, f, t, effSelector) "Selecting conversion efficiency equations"
    effGroup(effSelector) "Group name for efficiency selector set, e.g. DirectOff and Lambda02"
    effGroupSelector(effSelector, effSelector) "Efficiency selectors included in efficiency groups, e.g. Lambda02 contains Lambda01 and Lambda02."
    effLevelGroupUnit(effLevel, effSelector, unit) "What efficiency selectors are in use for each unit at each efficiency representation level"
    effGroupSelectorUnit(effSelector, unit, effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"
    mSettingsReservesInUse(mType, *, up_down) "Reserves that are used in each model type" 

* --- Sets used for grouping of units, transfer links, nodes, etc. ------------
    group "A group of units, transfer links, nodes, etc."
    uGroup(unit, group) "Units in particular groups"
    gnuGroup(grid, node, unit, group) "Combination of grids, nodes and units in particular groups"
    gn2nGroup(grid, node, node, group) "Transfer links in particular groups"
    gnGroup(grid, node, group) "Combination of grids and nodes in particular groups"

* --- Set of timeseries that will be read from files between solves -----------
    mTimeseries_loop_read(mType, timeseries) "Those time series that will be read between solves"
;
* Set initial values to avoid errors when checking if parameter contents have been loaded from input data
Option clear = modelSolves;
Option clear = ms;
Option clear = mf;
mf_realization(mType, 'f00') = yes;

alias(m, mSolve);
alias(t, t_, t__, tSolve, tFuel);
alias(f, f_, f__);
alias(s, s_, s__);
alias(grid, grid_, grid_output);
alias(unit, unit_);
alias(node, from_node, to_node, node_, node_input, node_output);
alias(node, from_node, to_node);
alias(effSelector, effSelector_);
alias(effDirect, effDirect_);
alias(effDirectOff, effDirectOff_);
alias(effDirectOn, effDirectOn_);
alias(effLambda, effLambda_);
alias(lambda, lambda_, lambda__);
alias(op, op_, op__);
alias(eff, eff_, eff__);
alias(fuel, fuel_);


*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);




