* --- Internal counters -------------------------------------------------------
Scalars
    errorcount /0/
    tElapsed "Model time elapsed since simulation start (t)" /0/
    tLast "How many time periods to the end of the current solve (t)" /0/
    tSolveOrd "ord of tSolve"
    tCounter "counter for t" /0/
;

* --- Power plant and fuel data -----------------------------------------------
Parameters
    eguData(etype, geo, unit, param_egu) "Unit data where energy type matters"
    guData(geo, unit, param_gu) "Unit data where energy type does not matter"
    egsData(etype, geo, storage, param_egs) "Storage unit data"
    guDataReserves(geo, unit, resType, *) "Reserve provision data for units"
    p_data2d(*, *, param) "2-dimensional data parameters of objects"
    p_transferCap(etype, geo, geo) "Transfer capacity limits"
    p_transferLoss(etype, geo, geo) "Transfer losses"
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
    t_bind(t) "Displacement to reach the binding time period in the parent sample (in time periods). Can skip with aggregated steps as well as when connecting samples."
    ft_bind(f, t) "Displacement to reach the binding forecast (in forecasts) in the current model"
    mt_bind(mType, t) "Displacement to reach the binding time period in the parent sample (in time periods) in the models"
    mft_bind(mType, f, t) "Displacement to reach the binding forecast (in forecasts) in the models"
;

* --- Stochastic data parameters ----------------------------------------------
Parameters
    ts_energyDemand(etype, geo, f, t) "Fixed energy demand of a time period/slice divided by average demand"
    ts_energyDemand_(etype, geo, f, t)
    ts_inflow(*, f, t) "External energy inflow during a time period (MWh)"
    ts_inflow_(*, f, t)
    ts_cf(flow, geo, f, t) "Available capacity factor time series (per unit)"
    ts_cf_(flow, geo, f, t)
    ts_import(etype, geo, t) "Energy import from locations outside the model scope (MW)"
    ts_import_(etype, geo, t)
    ts_reserveDemand(resType, resDirection, geo, f, t) "Reserve demand in region in the time period/slice (MW)"
    ts_reserveDemand_(resType, resDirection, geo, f, t)

    ts_fuelPriceChange(fuel, t) "Initial fuel price and consequent changes in fuel price (�/MWh)"
    ts_fuelPriceChangeGeo(fuel, geo, t) "Initial fuel price and consequent changes in fuel price in model geographies (�/MWh)"
    ts_stoContent(storage, f, t) "Storage content at the start of the time period (ratio of max)"
    ts_unavailability(unit, t) "Unavailability of a unit in the time period/slice (p.u.)"
;

* --- Other time dependent parameters -----------------------------------------
Parameters
    p_storageValue(etype, geo, storage, t) "Value of storage at the end of a time step"
    p_stepLength(mType, f, t) "Length of a time step (t)"
;
