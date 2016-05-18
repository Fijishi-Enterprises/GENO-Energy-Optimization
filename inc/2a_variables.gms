Free variable v_obj "Total operating cost (¤)";
Free variables
    v_gen(etype, geo, unit, f, t) "Energy generation or consumption in a time step (MW)"
;
Positive variables
    v_fuelUse(geo, unit, fuel, f, t) "Fuel use of a unit during time period (MWh_fuel)"
    v_online(geo, unit, f, t) "Capacity online for generators with unit commitment restrictions (MW)"
    v_startup(geo, unit, f, t) "Capacity started up from previous time period/slice (MW)"
    v_stoCharge(etype, geo, storage, f, t) "Charging of storage during time period (MWh)"
    v_stoDischarge(etype, geo, storage, f, t) "Discharging of storage during time step (MWh)"
    v_stoContent(etype, geo, storage, f, t) "Content of storage at the start of time period/time slice (MWh)"
    v_spill(etype, geo, storage, f, t) "Spill of energy from storage during time period (MWh)"
    v_transfer(etype, geo, geo, f, t) "Average electricity transmission level from bus to bus during time period/slice (MW)"
    v_resTransCapacity(resType, resDirection, geo, geo, f, t) "Electricity transmission capacity from bus to bus reserved for providing reserves (MW)"
    v_reserve(resType, resDirection, geo, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
;

* --- Feasibility control -----------------------------------------------------
Set inc_dec "Increase or decrease in dummy variables" / increase, decrease /;
Positive variables
    vq_gen(inc_dec, etype, geo, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    vq_resDemand(resType, resDirection, geo, f, t) "Dummy to decrease demand for a reserve (MW)"
    vq_stoCharge(etype, geo, storage, f, t) "Dummy loading of storages to ensure equation feasibility (MWh)"
;

