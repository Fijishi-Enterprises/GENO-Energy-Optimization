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

$onempty
Sets
* --- Geography ---------------------------------------------------------------
    grid "Forms of energy endogenously presented in the model"
    node "Nodes maintain the energy balance or track exogenous commodities"

* --- Emissions & flows -------------------------------------------------------
    emission "Emissions"
    flow "Flow based energy resources (time series)"

* --- Node classifications ----------------------------------------------------
    node_spill(node) "Nodes that can spill; used to remove v_spill variables where not relevant"
    node_priceData(node) "Nodes that have input data in ts_price table"
    node_priceChangeData(node) "Nodes that have input data in ts_priceChange table"
    node_superpos(node) "Nodes whose state is monitored in the z dimension using superpositioning of state"
    flowNode(flow, node) "Nodes with flows"
    node_tmp(node) "temporary set for summing nodes"
    node_tmp_(node) "another temporary set for summing nodes"

* --- Emission classifications ------------------------------------------------
    emission_priceData(emission) "Emissions that have input data in ts_emissionPrice table"
    emission_priceChangeData(emission) "Emissions that have input data in ts_emissionPriceChange table"

* --- Energy generation and consumption ---------------------------------------
    unit "Set of generators, storages and loads"
    unittype "Unit technology types"
    unit_flow(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
    unit_fail(unit) "Units that might fail" / /
    unit_minLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unit_online(unit) "Units that have an online variable in the first active effLevel"
    unit_online_LP(unit) "Units that have an LP online variable in the first active effLevel"
    unit_online_MIP(unit) "Units that have an MIP online variable in the first active effLevel"
    unit_aggregator(unit) "Aggregator units aggragating several units"
    unit_aggregated(unit) "Units that are aggregated"
    unit_noAggregate(unit) "Units that are not aggregated and are not aggregators"
    unit_startCost(unit) "units that have start costs defined"
    unit_slope(unit) "Units with piecewise linear efficiency constraints"
    unit_noSlope(unit) "Units without piecewise linear efficiency constraints"
    unitAggregator_unit(unit, unit) "Aggregate unit linked to aggregated units"
    unitUnitEffLevel(unit, unit, EffLevel) "Aggregator unit linked to aggreted units with a definition when to start the aggregation" / /
    flowUnit(flow, unit) "Units linked to a certain energy flow time series" / /
    unitUnittype(unit, unittype) "Link generation technologies to types for result tables" / /
    unitStarttype(unit, starttype) "Units with special startup properties"
    unit_invest(unit) "Units with investments allowed"
    unit_investLP(unit) "Units with continuous investments allowed"
    unit_investMIP(unit) "Units with integer investments allowed"
    unit_timeseries(unit) "Units with time series enabled"
    unit_incHRAdditionalConstraints(unit) "Units that use the two additional incremental heat rate constraints"
    unitConstraint(unit, constraint) "combinations of units and their eq/gt constraints"
    unit_eqConstrained(unit) "Units that have eq constraints between inputs and/or outputs"
    unit_gtConstrained(unit) "Units that have gt constraints between inputs and/or outputs"
    unit_tsConstrained(unit) "Units that have timeseries for eq or gt constraints between inputs and/or outputs"
    unit_tmp(unit) "temporary set for summing units"
    unit_forecasts(unit, timeseries) "A flag which (unit, timeseries) have forecast data. If not set, values are read from f_realized. Default value = yes."

* --- Sets bounding geography and units ---------------------------------------
    group "A group of units, transfer links, nodes, etc."
    gn(grid, node) "Grids and their nodes"
* NOTE! Should it be possible to permit time-series form upper or lower bounds on states? If so, then gn() needs rethinking.
    gn2n(grid, node, node) "All (directional) transfer links between nodes in specific energy grids"
    gn2n_directional(grid, node, node) "Transfer links with positive rightward transfer and negative leftward transfer"
    gn2n_directional_investLP(grid, node, node) "Transfer links with with continuous investments allowed"
    gn2n_directional_investMIP(grid, node, node) "Transfer links with with integer investments allowed"
    gn2n_timeseries(grid, node, node, param_gnn) "Transfer links with time series enabled for certain parameters"
    gn2n_directional_rampConstrained(grid, node, node) "Transfer links with ramp constraints enabled"
    gnu(grid, node, unit) "Units in specific nodes of particular energy grids"
    gnu_input(grid, node, unit) "Forms of energy the unit uses as endogenous inputs"
    gnu_output(grid, node, unit) "Forms of energy the unit uses as endogenous outputs"
    nu(node, unit) "Units attached to particular nodes"
    nu_startup(node, unit) "Units consuming energy from particular nodes in start-up"
    gn_influx(grid, node) "nodes with influx time series"
    gn_state(grid, node) "Nodes with a state variable"
    gn_stateSlack(grid, node) "Nodes with a state slack variable"
    gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes) "nodes with time series for boundaryTypes (ts_node)"
    gn_forecasts(*, node, timeseries) "A flag which (grid/flow/restype, node, timeseries) have forecast data. If not set, values are read from f_realized. Default value = yes."
    gnn_state(grid, node, node) "Nodes with state variables interconnected via diffusion"
    gnn_boundState(grid, node, node) "Nodes with state variables bound by other nodes"
    gn2gnu(grid, node, grid, node, unit) "Conversions between energy grids by specific units"
    gnu_tmp(grid, node, unit) "temporary table of (grid, node, unit) for easier if chekcs and looping"

* --- Reserve types -----------------------------------------------------------
    restype "Reserve types"
    restypeDirection(restype, up_down) "Different combinations of reserve types and directions" / /
    restypeDirectionGridNode(restype, up_down, grid, node) "Nodes with up/down reserve requirements"
    resTypeDirectionGridNodeNode(restype, up_down, grid, node, node) "Node node connections that can transfer up/down reserves"
    restypeDirectionGroup(restype, up_down, group) "Groups with up/down reserve requirements"
    restypeDirectionGridNodeGroup(restype, up_down, grid, node, group)
    gnuRescapable(restype, up_down, grid, node, unit) "Units capable and available to provide particular up/down reserves"
    gnuOfflineRescapable(restype, grid, node, unit) "Units capable and available to provide offline reserves"
    restypeReleasedForRealization(restype) "Reserve types that are released for the realized time intervals" / /
    offlineRes (restype) "Reserve types where offline reserve provision possible"
    offlineResUnit (unit) "Units where offline reserve provision possible"
    restype_inertia(restype) "Reserve types where the requirement can also be fulfilled with the inertia of synchronous machines" / /
    groupRestype(group, restype) "Groups with reserve requirements"

* --- Sets to define time, forecasts and samples ------------------------------
$ifthen exist '%input_dir%/timeAndSamples.inc'
    $$include '%input_dir%/timeAndSamples.inc'
$else
    $$abort 'Did not find %input_dir%/timeAndSamples.inc. Check path and spelling!'
$endif

    m(mType) "model(s) in use"
    s_active(s) "Samples with non-zero probability in the current model solve"
    s_realized(s) "All s among realized sft (redundant if always equivalent to s)"
    f_solve(f) "forecasts in the model to be solved next"

    t_start(t) "start t"
    t_startp(t) "Temporary subset for time steps"
    t_full(t) "Full set of time steps in the current model"
    t_datalength(t) "Full set of time steps withing the datalength"
    t_current(t) "Set of time steps within the current solve horizon"
    t_active(t) "Set of active t:s within the current solve horizon, including necessary history"
    t_invest(t) "Time steps when investments can be made" / /
    t_realized(t) "Set of realized time steps in the simulation"
    tt(t) "Temporary subset for time steps used for calculations"
    tt_(t) "Another temporary subset for time steps used for calculations"
    tt_block(counter_large, t) "Temporary time step subset for storing the time interval blocks"
    tt_interval(t) "Temporary time steps when forming the ft structure, current sample"
    tt_forecast(t) "Temporary subset for time steps used for forecast updating during solve loop"
    tt_aggregate(t, t) "Time steps included in each active time step for time series aggregation"
    tt_agg_circular(t, t, t) "Alternative aggregation ordering with embedded circulars"

    mf(mType, f) "Forecasts present in the models"
    mf_realization(mType, f) "Realization of the forecasts"
    mf_central(mType, f) "Forecast that continues as sample(s) after the forecast horizon ends"
    ms(mType, s) "Samples present in the models"
    ms_initial(mType, s) "Sample that presents the realized/forecasted period"
    ms_central(mType, s) "Sample that continues the central forecast after the forecast horizon ends"
    ft(f, t) "Combination of forecasts and t:s in the current solve"
    ft_realized(f, t) "Realized ft"
    ft_realizedNoReset(f, t) "Full set of realized ft, facilitates calculation of results"
    ft_reservesFixed(group, restype, f, t) "Forecast-time steps with reserves fixed due to commitments on a previous solve."
    mft(mType, f, t) "Combination of forecasts and t:s in the current model solve"
    mft_start(mType, f, t) "Start point of the current model solve"
    mft_lastSteps(mType, f, t) "Last interval of the current model solve"
    msf(mType, s, f) "Combination of samples and forecasts in the models"
    mst(mType, s, t) "Combination of models samples and t's"
    mst_start(mType, s, t) "Start point of samples"
    mst_end(mType, s, t) "Last point of samples"
    sft(s, f, t) "Combination of samples, forecasts and t's in the current model solve"
    sft_realized(s, f, t) "Realized sft"
    sft_realizedNoReset(s, f, t) "Full set of realized sft, facilitates calculation of results"
    sft_resdgn(restype, up_down, grid, node, s,f,t) "Temporary tuplet for reserves by restypeDirectionGridNode"
    msft(mType, s, f, t) "Combination of models, samples, forecasts and t's"
    msft_realizedNoReset(mType, s, f, t) "Combination of realized samples, forecasts and t:s in the current model solve and previously realized t:s"

    modelSolves(mType, t) "when different models are to be solved"
    gnss_bound(grid, node, s, s) "Bound the samples so that the node state at the last interval of the first sample equals the state at the first interval of the second sample" / /
    uss_bound(unit, s, s) "Bound the samples so that the unit online state at the last interval of the first sample equals the state at the first interval of the second sample" / /

    mz(mType, z) "z periods in the models"
    zs(z, s) "relationship between the z-periods and samples"

* --- counter sets used in several loops, time intervals, and trajectories
    counter(counter_large) "Counter set limited to needed amount of counters"
    cc(counter_large) "Temporary subset of counter used for calculations"

* --- Sets used for the changing unit aggregation and efficiency approximations as well as unit lifetimes
    usft(unit, s, f, t) "set of active units and aggregated sft"
    usft_online(unit, s, f, t) "Units with any online and startup variables on intervals"
    usft_onlineLP(unit, s, f, t) "Units with LP online and startup variables on intervals"
    usft_onlineMIP(unit, s, f, t) "Units with MIP online and startup variables on intervals"
    usft_onlineLP_withPrevious(unit, s, f, t) "Units with LP online and startup variables on intervals, including t0"
    usft_onlineMIP_withPrevious(unit, s, f, t) "Units with MIP online and startup variables on intervals, including t0"
    usft_startupTrajectory(unit, s, f, t) "Units with start-up trajectories on intervals"
    usft_shutdownTrajectory(unit, s, f, t) "Units with shutdown trajectories on intervals"
    usft_aggregator_first(unit, s, f, t) "The first intervals when aggregator units are active"
    gnusft(grid, node, unit, s, f, t) "set of active gnu and aggregated sft"
    gnusft_ramp(grid, node, unit, s, f, t) "Units with ramp requirements or costs"
    gnusft_rampCost(slack, grid, node, unit, s, f, t) "Units with ramp costs"

    eff_usft(effSelector, unit, s, f, t) "Selecting conversion efficiency equations"
    effGroup(effSelector) "Group name for efficiency selector set, e.g. DirectOff and Lambda02"
    effGroupSelector(effSelector, effSelector) "Efficiency selectors included in efficiency groups, e.g. Lambda02 contains Lambda01 and Lambda02."
    effLevelGroupUnit(effLevel, effSelector, unit) "What efficiency selectors are in use for each unit at each efficiency representation level" / /
    effGroupSelectorUnit(effSelector, unit, effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"

    mSettingsReservesInUse(mType, restype, up_down) "Reserves that are used in each model type"
    unitCounter(unit, counter_large) "Counter used for restricting excessive looping over the counter set when defining unit startup/shutdown/online time restrictions"
    runUpCounter(unit, counter_large) "Counter used for unit run-up intervals"
    shutdownCounter(unit, counter_large) "Counter used for unit shutdown intervals"
    utAvailabilityLimits(unit, t, availabilityLimits) "Time step when the unit becomes available/unavailable, e.g. because of technical lifetime" / /

* --- Sets used for the changing transfer link aggregation and efficiency approximations as well as lifetimes
    gn2nsft_directional_rampConstrained(grid, node, node, s, f, t) "Transfer links with ramp constraints enabled, aggregating time steps"

* --- Sets used for grouping of units, transfer links, nodes, etc. ------------
    uGroup(unit, group) "Units in particular groups" / /
    gnuGroup(grid, node, unit, group) "Combination of grids, nodes and units in particular groups" / /
    gn2nGroup(grid, node, node, group) "Transfer links in particular groups" / /
    gnGroup(grid, node, group) "Combination of grids and nodes in particular groups" / /
    sGroup(s, group) "Samples in particular groups" / /
    emissionGroup(emission, group) "combinations of emissions and groups"
    groupPolicyTimeseries(group, param_policy) "Combination of groups and policies that have time series" / /

* --- Set of timeseries that will be read from files between solves -----------
    mTimeseries_loop_read(mType, timeseries) "Those time series that will be read between solves"
;
$offempty

* --- Set for metadata --------------------------------------------------------

* Get current username
$ifthen %system.filesys% == 'MSNT'
$set username %sysenv.USERNAME%
$else
$set username %sysenv.USER%
$endif

* Create metadata
set metadata(*) /
   'User' '%username%'
   'Date' '%system.date%'
   'Time' '%system.time%'
   'GAMS version' '%system.gamsrelease%'
   'GAMS system' '%system.gstring%'
$ifthen exist 'version_git'
    $$include 'version_git';
$else
    $$include 'version';
$endif
/;
if(execError > 0, metadata('FAILED') = yes);



* Set initial values to avoid errors when checking if parameter contents have been loaded from input data
Option clear = modelSolves;
Option clear = ms;
Option clear = mf;
mf_realization(mType, 'f00') = yes;
Option clear = mTimeseries_loop_read;

alias(m, mSolve);
alias(t, t_, t__, t_solve);
alias(f, f_, f__);
alias(s, s_, s__);
alias(grid, grid_, grid_output);
alias(unit, unit_);
alias(node, from_node, to_node, node_, node_input, node_output, node_fail, node_left, node_right);
alias(effSelector, effSelector_);
alias(effDirect, effDirect_);
alias(effDirectOff, effDirectOff_);
alias(effDirectOn, effDirectOn_);
alias(effLambda, effLambda_);
alias(lambda, lambda_, lambda__);
alias(op, op_, op__);
alias(hrop, hrop_, hrop__);
alias(eff, eff_, eff__);
alias(hr, hr_, hr__);
alias(effLevel, effLevel_);
alias(restype, restype_);
alias(group, group_);
alias(metadata, r_info_metadata);

*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);



