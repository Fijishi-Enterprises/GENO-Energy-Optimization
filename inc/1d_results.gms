* Result arrays
Parameters
    r_stoContent(storage, t) "Storage content at end of hour (MWh)"
    r_onlineCap(unit, t) "Online capacity of a unit during hour (MW)"
    r_gen(grid, unit, t) "Energy generation for a unit (MW)"
    r_elec_type(genType, t) "Average electricity generation rate of generator type (MW)"
    r_demand(node, t) "Average energy demand (MW)"
    r_transfer(node, node, t) "Energy transfer (MW)"
    r_capacity_type(genType) "Available generation capacity by type (MW)"
    r_elecConsumption(unit, t) "Average electricity consumption rate during hour (MW)"
    r_storageValue(storage, t) "Storage value (€/MWh)"
    r_storageControl(storage, t) "Storage control during hour (MWh)"
    r_energyPrice(grid, node, t) "Marginal cost of energy generation (MWh)"
    r_totalCost "Total operating cost over the simulation (€)" / 0 /
;
