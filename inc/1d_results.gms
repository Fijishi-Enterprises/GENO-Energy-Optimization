* Result arrays
Parameters
    r_stoContent(node, t) "Storage content at end of hour (MWh)"
    r_onlineCap(unit, t) "Online capacity of a unit during hour (MW)"
    r_state(grid, node, t) "Node state at timestep t"
    r_gen(grid, unit, t) "Energy generation for a unit (MW)"
    r_genFuel(grid, node, fuel, t) "Energy generation/consumption based on fuels / flows (MW)"
    r_genNodeType(grid, node, unitType, t) "Energy generation/consumption based on unittypes (MW)"
    r_genType(grid, unitType, t) "Energy generation/consumption based on unittypes (MW)"
    r_elec_type(unittype, t) "Average electricity generation rate of generator type (MW)"
    r_demand(grid, node, t) "Average energy demand (MW)"
    r_transfer(grid, node, node, t) "Energy transfer (MW)"
    r_capacity_type(unittype) "Available generation capacity by type (MW)"
    r_elecConsumption(unit, t) "Average electricity consumption rate during hour (MW)"
    r_storageValue(node, t) "Storage value (€/MWh)"
    r_storageControl(node, t) "Storage control during hour (MWh)"
    r_energyPrice(grid, node, t) "Marginal cost of energy generation (MWh)"
    r_totalCost "Total operating cost over the simulation (€)" / 0 /
;
