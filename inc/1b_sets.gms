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
    unit_elec(unit) "Units that generate and/or consume electricity"
    unit_flow(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
    unit_fuel(unit) "Units using a commercial fuel"
    unit_minLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unit_aggregate(unit) "Aggregate units aggragating several units"
    unit_noAggregate(unit) "Units that are not aggregated at all"
    unit_slope(unit) "Units with piecewise linear efficiency constraints"
    unit_noSlope(unit) "Units without piecewise linear efficiency constraints"
    unitUnit_aggregate(unit, unit) "Aggregate unit linked to aggregated units"
    flowUnit(flow, *) "Units or storages linked to a certain energy flow time series"
    unitUnittype(unit, *) "Link generation technologies to types"
    uFuel(unit, param_fuel, fuel) "Units linked with fuels"
    unittype "Unit technology types"
    unit_investLP(unit) "Units with continuous investments allowed"
    unit_investMIP(unit) "Units with integer investments allowed"
    group "A group of units and transfer links"

* --- Nodes -----------------------------------------------------------------
    node_spill(node)      "Nodes that can spill; used to remove v_spill variables where not relevant"

* --- Sets bounding geography and units -------------------------------------
    gn(grid, node) "Grids and their nodes"
* NOTE! Should it be possible to permit time-series form upper or lower bounds on states? If so, then gn() needs rethinking.
    gn2n(grid, node, node) "All (directional) transfer links between nodes in specific energy grids"
    gn2n_bidirectional(grid, node, node) "Bidirectional transfer links between nodes in specific energy grids"
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
    gnu_group(grid, node, unit, group) "Units in particular groups"
    gn2n_group(grid, node, node, group) "Transfer links in particular groups"

* --- Reserve types -----------------------------------------------------------
    restypeDirectionNode(restype, up_down, node) "Nodes with reserve requirements"
    nuRescapable(restype, up_down, node, unit) "Units capable and available to provide particular reserves"

* --- Sets to define time, forecasts and samples -----------------------------------------------
    $$include 'input/timeAndSamples.inc'
    m(mType) "model(s) in use"
    tt(t) "Time steps in the current model"
    tInterval(t) "Temp for t's when calculating time series averages"
    mf(mType, f) "Forecasts present in the models"
    ms(mType, s) "Samples present in the models"
    mstStart(mType, s, t) "Start point of samples"
    ft(f, t) "Combination of forecasts and time periods in the current model"
    ft_dynamic(f, t) "ft without first t and with tLast+1 (moved right)"
    ft_full(f, t) "ft with all t's in the solve including tSolve and tLast+1"
    ft_realized(f, t) "Realized ft"
    ft_realizedLast(f, t) "Last realized ft"
    ft_nReserves(node, restype, f, t) "Forecast-time steps locked due to committing reserves ahead of time."
    mft(mType, f, t) "Combination of forecasts and time periods in the models"
    mft_(mType, f, t) "Combination of forecasts and time periods in the models"
    msf(mType, s, f) "Model, sample, forecast"
    msft(mType, s, f, t) "Combination of samples, forecasts and time periods in the models"
    mftStart(mType, f, t) "Start point of simulation"
*    mftBind(mType, f, t) "Time periods/slices where forecasts/samples are coupled, note: t couples samples"
    fRealization(f) "fRealization of the forecasts"
    fCentral(f) "Forecast that continues as sample(s) after the forecast horizon ends"
    sInitial(s) "Sample that presents the realized/forecasted period"
    sCentral(s) "Sample that continues the central forecast after the forecast horizon ends"
    mftLastForecast(mType, f, t) "Last time period where the forecast extends"
    mftLastSteps(mType, f, t) "Last time periods of the model (can be end of forecasts or end of samples)"
    modelSolves(mType, t) "when different models are to be solved"
    fSolve(f) "forecasts in the model to be solved next"
    tSolveDispatch(t)
    tLatestForecast(t) "t for the latest forecast that is available"
    t_invest(t) "Time steps when investments can be made"

* --- Sets used for the changing unit aggregation and efficiency approximations
    uft(unit, f, t) "Enables aggregation of units for later time periods"
    uft_online(unit, f, t) "Units with online and startup variables on time periods"
    uft_online_last(unit, f, t) "Last (f,t) when online variables are included"
    uft_online_incl_previous(unit, f, t) "Units with online and startup variables on time periods including the last realized period from previous solve"
    nuft(node, unit, f, t) "Enables aggregation of nodes and units for later time periods"
    gnuft(grid, node, unit, f, t) "Enables aggregation of nodes and units for later time periods"
    gnuft_ramp(grid, node, unit, f, t) "Units with ramp requirements or costs"
    suft(effSelector, unit, f, t) "Selecting conversion efficiency equations"
    sufts(effSelector, unit, f, t, effSelector) "Selecting conversion efficiency equations"
    effGroup(effSelector) "Group name for efficiency selector set, e.g. DirectOff and Lambda02"
    effGroupSelector(effSelector, effSelector) "Efficiency selectors included in efficiency groups, e.g. Lambda02 contains Lambda01 and Lambda02."
    effLevelGroupUnit(effLevel, effSelector, unit) "What efficiency selectors are in use for each unit at each efficiency representation level"
    effGroupSelectorUnit(effSelector, unit, effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"
;
* Set initial values to avoid errors when checking if parameter contents have been loaded from input data
fRealization('f00') = yes;
ms(mType, s) = no;
modelSolves(mType, t) = no;

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


*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);




