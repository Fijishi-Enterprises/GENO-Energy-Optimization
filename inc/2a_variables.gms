Free variable v_obj "Total operating cost (monetary unit)";
Free variables
    v_gen(grid, node, unit, f, t) "Energy generation or consumption in a time step (MW)"
    v_state(grid, node, f, t) "State variable for nodes that maintain a state (MWh, unless modified by energyStoredPerUnitOfState and diffCoeff parameters)"
    v_genRamp(grid, node, unit, f, t) "Change in energy generation or consumption over a time step (p.u./min)"
;
Integer variables
    v_online(unit, f, t) "Number of units online for units with unit commitment restrictions"
;
SOS2 variables
    v_sos2(unit, f, t, effSelector) "Intermediate lambda variable for SOS2 based piece-wise linear efficiency curve"
;
Positive variables
    v_fuelUse(fuel, unit, f, t) "Fuel use of a unit during time period (MWh_fuel)"
    v_startup(unit, f, t) "Capacity started up after/during the time period/slice (MW)"
    v_shutdown(unit, f, t) "Capacity shut down after/during the time period/slice (MW)"
    v_genRampChange(grid, node, unit, up_down, f, t) "Rate of change in energy generation between time steps (p.u./min)"
    v_spill(grid, node, f, t) "Spill of energy from storage node during time period (MWh)"
    v_transfer(grid, node, node, f, t) "Average electricity transmission level from node to node during time period/slice (MW)"
    v_resTransfer(restype, up_down, node, node, f, t) "Electricity transmission capacity from node to node reserved for providing reserves (MW)"
    v_reserve(restype, up_down, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
;

* --- Feasibility control -----------------------------------------------------
Positive variables
    v_stateSlack(grid, node, slack, f, t) "Slack variable for different v_state slack categories, permits e.g. costs for exceeding acceptable v_states (MWh, unless modified by energyCapacity parameter)"
    vq_gen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    vq_resDemand(restype, up_down, node, f, t) "Dummy to decrease demand for a reserve (MW)"
;
