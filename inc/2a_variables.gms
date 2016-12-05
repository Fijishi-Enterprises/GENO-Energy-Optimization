Free variable v_obj "Total operating cost (monetary unit)";
Free variables
    v_gen(grid, node, unit, f, t) "Energy generation or consumption in a time step (MW)";
Integer variable
    v_online(unit, f, t) "Number of units online for units with unit commitment restrictions";
SOS1 variable
    v_sos1(effSelector, unit, f, t, effSelector) "Intermediate variable for SOS1 based piece-wise linear efficiency curve";
SOS2 variable
    v_sos2(unit, f, t, effSelector) "Intermediate lambda variable for SOS2 based piece-wise linear efficiency curve";
Positive variables
    v_fuelUse(fuel, unit, f, t) "Fuel use of a unit during time period (MWh_fuel)"
    v_startup(unit, f, t) "Capacity started up from previous time period/slice (MW)"
    v_state(grid, node, f, t) "State variable for nodes that maintain a state (MWh, unless modified by unitConversion parameter)"
    v_spill(grid, node, f, t) "Spill of energy from storage node during time period (MWh)"
    v_transfer(grid, node, node, f, t) "Average electricity transmission level from node to node during time period/slice (MW)"
    v_resTransfer(restype, resdirection, node, node, f, t) "Electricity transmission capacity from node to node reserved for providing reserves (MW)"
    v_reserve(restype, resdirection, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
;

* --- Feasibility control -----------------------------------------------------
Positive variables
    v_stateSlack(grid, node, slack, f, t) "Slack variable for different v_state slack categories, permits e.g. costs for exceeding acceptable v_states (MWh, unless modified by energyCapacity parameter)"
    vq_gen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    vq_resDemand(restype, resdirection, node, f, t) "Dummy to decrease demand for a reserve (MW)"
;

