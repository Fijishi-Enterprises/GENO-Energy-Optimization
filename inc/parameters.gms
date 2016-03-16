* --- Power plant and fuel data -----------------------------------------------
Parameters
    uData(etype, geo, unit, param) "Unit data"
    usData(etype, geo, storage, param) "Storage unit data"
    uReserveData(geo, unit, resType, *) "Reserve provision data for units"
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
    mt_bind(modelType, t) "Displacement to reach the binding time period in the parent sample (in time periods) in the models"
    mft_bind(modelType, f, t) "Displacement to reach the binding forecast (in forecasts) in the models"
;

* --- Stochastic data parameters ----------------------------------------------
Parameters
    ts_energyDemand(etype, geo, f, t) "Fixed energy demand of a time period/slice divided by average demand"
    ts_inflow(*, f, t) "External energy inflow during a time period (MWh)"
    ts_cf(flow, geo, f, t) "Available capacity factor time series (per unit)"

    ts_import(etype, geo, t) "Energy import from locations outside the model scope (MW)"
    ts_fuelPriceChange(fuel, t) "Initial fuel price and consequent changes in fuel price (€/MWh)"
    ts_fuelPriceChangeGeo(fuel, geo, t) "Initial fuel price and consequent changes in fuel price in model geographies (€/MWh)"
    ts_stoContent(storage, f, t) "Storage content at the start of the time period (ratio of max)"
    ts_unavailability(unit, t) "Unavailability of a unit in the time period/slice (p.u.)"
    ts_reserveDemand(resType, resDirection, geo, f, t) "Reserve demand in region in the time period/slice (MW)"

    ts_netLoad(geo, t) "net load time series"
    ts_netLoadRamp(geo, t) "net load ramp time series"
    ts_netLoadRampAve(notch, notch) "net load ramp averages"
    ts_netLoadCur(t) "net load time series for current bus/year"
    ts_netLoadRampWindow(geo, t) "averaging window for net load ramp"
    ts_netLoad2ndDer(geo, t) "net load 2nd derivative time series"
    ts_netLoadRampNotches(geo, t) "possible notches"
    ts_netLoadRampResult(geo, t) "net load ramps with reduced time series"
    ts_notchPos(notch) "position of the possible notches"
    ts_segmentErrorSquared(notch, notch_) "precalculated error penalties for selectable ramp segments"
    ts_sortIndex(geo, t) "sort rank for time series"
    ts_sortedNetLoad(geo, t) "sorted net load time series"
;

* --- Other time dependent parameters -----------------------------------------
Parameters
    p_storageValue(etype, geo, storage, t) "Value of storage at the end of a time step"
    p_stepLength(modelType, f, t) "Length of a time step (t)"
;

$include 'inc/rampSched/parameters_rampSched.gms'
