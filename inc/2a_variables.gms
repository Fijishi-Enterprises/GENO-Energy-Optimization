Free variable v_obj "Total operating cost (¤)";
Free variables
    v_gen(grid, node, unit, f, t) "Energy generation or consumption in a time step (MW)"
;
Positive variables
    v_fuelUse(node, unit, fuel, f, t) "Fuel use of a unit during time period (MWh_fuel)"
    v_online(node, unit, f, t) "Capacity online for generators with unit commitment restrictions (MW)"
    v_startup(node, unit, f, t) "Capacity started up from previous time period/slice (MW)"
    v_state(grid, node, f, t) "State variable for nodes that maintain a state (MWh, unless modified by energyCapacity parameter)"
    v_stoCharge(grid, node, storage, f, t) "Charging of storage during time period (MWh)"
    v_stoDischarge(grid, node, storage, f, t) "Discharging of storage during time step (MWh)"
    v_stoContent(grid, node, storage, f, t) "Content of storage at the start of time period/time slice (MWh)"
    v_spill(grid, node, storage, f, t) "Spill of energy from storage during time period (MWh)"
    v_transfer(grid, node, node, f, t) "Average electricity transmission level from node to node during time period/slice (MW)"
    v_resTransCapacity(resType, resDirection, node, node, f, t) "Electricity transmission capacity from node to node reserved for providing reserves (MW)"
    v_reserve(resType, resDirection, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
;

* --- Feasibility control -----------------------------------------------------
Positive variables
    v_stateSlack(slack, inc_dec, grid, node, f, t) "Slack variable for different v_state slack categories, permits e.g. costs for exceeding acceptable v_states (MWh, unless modified by energyCapacity parameter)"
    vq_gen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    vq_resDemand(resType, resDirection, node, f, t) "Dummy to decrease demand for a reserve (MW)"
    vq_stoCharge(grid, node, storage, f, t) "Dummy loading of storages to ensure equation feasibility (MWh)"
;

