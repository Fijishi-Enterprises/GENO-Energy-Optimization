Sets
* --- Geography ---------------------------------------------------------------
    grid "Forms of energy endogenously presented in the model"
    node "Nodes where different types of energy are converted"
*    node_to_node(node, node) "Transmission links" // NOT USED ATM

* --- Fuels & resources -------------------------------------------------------
    emission "Emissions"
    fuel "Fuels"
    flow "Flow based energy resources (time series)"

* --- Energy generation and consumption ---------------------------------------
    unit "Set of generators, storages and loads"
    unit_elec(unit) "Units that generate and/or consume electricity"
*    unit_heat(unit) "Units that produce and/or consume unit_heat" // NOT USED ATM
    unit_flow(unit) "Unit that depend directly on variable energy flows (RoR, solar PV, etc.)"
*    unit_withConstrainedOutputRatio(unit) "Units that use cV factor for their secondary output(s)" // NOT USED ATM
*    unit_hydro(unit) "Hydropower generators" // NOT USED ATM
    unit_fuel(unit) "Units using a commercial fuel"
    unit_minLoad(unit) "Units that have unit commitment restrictions (e.g. minimum power level)"
    unit_online(unit) "Units that have an online variable"
    unit_aggregate(unit) "Aggregate units aggragating several units"
    unit_noAggregate(unit) "Units that are not aggregated at all"
    unit_slope(unit) "Units with piecewise linear efficiency constraints"
    unit_noSlope(unit) "Units without piecewise linear efficiency constraints"
    unitUnit_aggregate(unit, unit) "Aggregate unit linked to aggregated units"
    flowUnit(flow, *) "Units or storages linked to a certain energy flow time series"
    unitUnittype(unit, *) "Link generation technologies to types"
    uFuel(unit, param_fuel, fuel) "Units linked with fuels"
    slopeUnit(slope, unit) "Piece-wise linear slope used by an unit"
    unittype "Unit technology types"


* --- Nodes -----------------------------------------------------------------
*    node_reservoir(node)  "Hydropower reservoirs"
    node_spill(node)      "Nodes that can spill; used to remove v_spill variables where not relevant"


* --- Sets bounding geography and units -------------------------------------
    gn(grid, node) "Grids and their nodes"
* NOTE! Should it be possible to permit time-series form upper or lower bounds on states? If so, then gn() needs rethinking.
    gn2n(grid, node, node) "Transfer capacity between nodes in specific energy grids"
    gnu(grid, node, unit) "Units in specific nodes of particular energy grids"
    gnu_input(grid, node, unit) "Forms of energy the unit uses as endogenous inputs"
    gnu_output(grid, node, unit) "Forms of energy the unit uses as endogenous outputs"
*    gnuUnion(grid, node, unit, param_union) "How inputs or outputs are related to each other" // NOT USED ATM
    nu(node, unit) "Units attached to particular nodes"
*    nnu(node, node, unit) "Units that link two nodes" // NOT USED ATM
    gn_state(grid, node) "Nodes with a state variable"
    gn_stateSlack(grid, node) "Nodes with a state slack variable"
    gnn_state(grid, node, node) "Nodes with state variables interconnected via diffusion"
    gnn_boundState(grid, node, node) "Nodes with state variables bound by other nodes"
    gn2gnu(grid, node, grid, node, unit) "Conversions between energy grids by specific units"
    gngnu_fixedOutputRatio(grid, node, grid, node, unit) "Units with a fixed ratio between two different grids of output (e.g. backpressure)"
    gngnu_constrainedOutputRatio(grid, node, grid, node, unit) "Units with a constrained ratio between two different grids of output (e.g. extraction)"

* --- Reserve types -----------------------------------------------------------
    restype "Reserve types"
        / primary "Automatic frequency containment reserves"
          secondary "Fast frequency restoration reserves"
          tertiary "Replacement reserves"
        /
    resdirection "Reserve direction"
        / resUp       "Capacity available for upward reserves (p.u.)"
          resDown     "Capacity available for downward reserves (p.u.)"
        /
    restypeDirection(restype, resdirection) "Different combinations of reserve types and directions"
        / primary.resUp
          primary.resDown
          secondary.resUp
          secondary.resDown
          tertiary.resUp
          tertiary.resDown
        /
    restypeDirectionNode(restype, resdirection, node) "Nodes with reserve requirements"
    nuRescapable(restype, resdirection, node, unit) "Units capable and available to provide particular reserves"

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
    ft_new(f, t) "Newly introduced f,t to be used in calculating parameter/variable values"
    mft(mType, f, t) "Combination of forecasts and time periods in the models"
    mft_(mType, f, t) "Combination of forecasts and time periods in the models"
    msft(mType, s, f, t) "Combination of samples, forecasts and time periods in the models"
    mftStart(mType, f, t) "Start point of simulation"
    mftBind(mType, f, t) "Time periods/slices where forecasts/samples are coupled, note: t couples samples"
    uft(unit, f, t) "Enables aggregation of units for later time periods"
    uft_online(unit, f, t) "Units with online and startup variables on time periods"
    nuft(node, unit, f, t) "Enables aggregation of nodes and units for later time periods"
    gnuft(grid, node, unit, f, t) "Enables aggregation of nodes and units for later time periods"
    suft(effSelector, unit, f, t) "Selecting conversion efficiency equations"
    sufts(effSelector, unit, f, t, effSelector) "Selecting conversion efficiency equations"
    effGroup(effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"
    effGroupSelector(effSelector, effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"
    effLevelGroupUnit(effLevel, effSelector, unit) "What efficiency selectors are in use for each unit at each efficiency representation level"
    effLevelSelectorUnit(effLevel, effSelector, unit) "What efficiency selectors are in use for each unit at each efficiency representation level"
    effGroupSelectorUnit(effSelector, unit, effSelector) "Group name for efficiency selector set, e.g. Lambda02 contains Lambda01 and Lambda02"
    fRealization(f) "fRealization of the forecasts"
    fCentral(f) "Forecast that continues as sample(s) after the forecast horizon ends"
    sInitial(s) "Sample that presents the realized/forecasted period"
    sCentral(s) "Sample that continues the central forecast after the forecast horizon ends"
    mftLastForecast(mType, f, t) "Last time period where the forecast extends"
    mftLastSteps(mType, f, t) "Last time periods of the model (can be end of forecasts or end of samples)"
    modelSolves(mType, t) "when different models are to be solved"
    fSolve(f) "forecasts in the model to be solved next"
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


*if(active('rampSched'),
  $$include inc/rampSched/sets_rampSched.gms
*);




