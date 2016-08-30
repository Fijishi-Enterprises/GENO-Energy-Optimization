* --- Internal counters -------------------------------------------------------
Scalars
    errorcount /0/
    tSolveFirst "counter (ord) for the first t in the solve"
    tSolveLast "counter for the last t in the solve"
    tCounter "counter for t" /0/
    lastCounter "last member in use of the general counter"
    ts_length "Length of time series (t)"
    continueLoop "Helper to stop the looping early"
    intervalLength "Legnth of the interval to be calculated, considering end of modelling period"
;

* --- Power plant and fuel data -----------------------------------------------
Parameters
    p_gn(grid, node, param_gn) "Data for energy nodes"
    p_gnn(grid, node, node, param_gnn) "Data for interconnections between energy nodes"
    p_gnu(grid, node, unit, param_gnu) "Unit data where energy type matters"
    p_nu(node, unit, param_nu) "Unit data where energy type does not matter"
    p_gnStorage(grid, node, storage, param_gnStorage) "Storage unit data"
    p_nuReserves(node, unit, restype, *) "Reserve provision data for units"
    p_gnPolicy(grid, node, param_policy, *) "Policy data for grid, node"
    p_fuelEmission(fuel, emission) "Fuel emission content"
;

* --- Feasibility control -----------------------------------------------------
Parameters
    p_gnSlack(inc_dec, slack, grid, node, param_slack) "Data for slack terms"
;

* --- Probability -------------------------------------------------------------
Parameters
    p_sWeight(s) "Weight of sample"
    p_sProbability(s) "Probability to reach sample conditioned on anchestor samples"
    p_fProbability(f) "Probability of forecast"
;

Scalar p_sWeightSum "Sum of sample weights";

* --- Model structure ---------------------------------------------------------
Parameters
    pt(t) "Displacement needed to reach the previous time period (in time periods)"
    pf(f, t) "Displacement needed to reach the previous forecast (in forecasts)"
    ct(t) "Circular t displacement if the time series data is not long enough to cover the model horizon"
    t_bind(t) "Displacement to reach the binding time period in the parent sample (in time periods). Can skip with aggregated steps as well as when connecting samples."
    ft_bind(f, t) "Displacement to reach the binding forecast (in forecasts) in the current model"
    mt_bind(mType, t) "Displacement to reach the binding time period in the parent sample (in time periods) in the models"
    mft_bind(mType, f, t) "Displacement to reach the binding forecast (in forecasts) in the models"
;

* --- Stochastic data parameters ----------------------------------------------
Parameters
    ts_energyDemand(grid, node, f, t) "Fixed energy demand of a time period/slice divided by average demand"
    ts_energyDemand_(grid, node, f, t)
    ts_inflow(*, f, t) "External energy inflow during a time period (MWh)"
    ts_inflow_(*, f, t)
    ts_cf(flow, node, f, t) "Available capacity factor time series (per unit)"
    ts_cf_(flow, node, f, t)
    ts_import(grid, node, t) "Energy import from locations outside the model scope (MW)"
    ts_import_(grid, node, t)
    ts_reserveDemand(restype, resdirection, node, f, t) "Reserve demand in region in the time period/slice (MW)"
    ts_reserveDemand_(restype, resdirection, node, f, t)

    ts_nodeState(grid, node, param_gn, f, t) "Fix the states of a node according to time-series form exogenous input"
    ts_fuelPriceChange(fuel, t) "Initial fuel price and consequent changes in fuel price (€/MWh)"
    ts_fuelPriceChangenode(fuel, node, t) "Initial fuel price and consequent changes in fuel price in model nodegraphies (€/MWh)"
    ts_stoContent(storage, f, t) "Storage content at the start of the time period (ratio of max)"
    ts_unavailability(unit, t) "Unavailability of a unit in the time period/slice (p.u.)"
;

* --- Other time dependent parameters -----------------------------------------
Parameters
    p_storageValue(grid, node, storage, t) "Value of storage at the end of a time step"
    p_stepLength(mType, f, t) "Length of a time step (t)"
    p_stepLengthNoReset(mType, f, t) "Length of a time step (t)"
;
