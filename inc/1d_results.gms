$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* --- Result arrays -----------------------------------------------------------
Parameters
*    r_stoContent(node, t) "Storage content at end of hour (MWh)"
*    r_onlineCap(unit, t) "Online capacity of a unit during hour (MW)"
    r_state(grid, node, f, t) "Node state at timestep t"
    r_gen(grid, node, unit, f, t) "Energy generation for a unit (MW)"
    r_online(unit, f, t) "Units online"
    r_reserve(restype, up_down, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
    r_resTransfer(restype, up_down, node, node, f, t) "Electricity transmission capacity from node to node reserved for providing reserves (MW)"
*    r_genFuel(grid, node, fuel, t) "Energy generation/consumption based on fuels / flows (MW)"
*    r_genNodeType(grid, node, unitType, t) "Energy generation/consumption based on unittypes (MW)"
*    r_genType(grid, unitType, t) "Energy generation/consumption based on unittypes (MW)"
*    r_fuelUse(fuel, unit, t) "Fuel use of units (MW)"
*    r_elec_type(unittype, t) "Average electricity generation rate of generator type (MW)"
*    r_demand(grid, node, t) "Average energy demand (MW)"
    r_transfer(grid, from_node, to_node, f, t) "Energy transfer (MW)"
*    r_capacity_type(unittype) "Available generation capacity by type (MW)"
*    r_elecConsumption(unit, t) "Average electricity consumption rate during hour (MW)"
*    r_storageValue(node, t) "Storage value (€/MWh)"
*    r_storageControl(node, t) "Storage control during hour (MWh)"
*    r_energyPrice(grid, node, t) "Marginal cost of energy generation (MWh)"
    r_totalCost "Total operating cost over the simulation (€)" / 0 /
*    r_cost(t) "Total operating cost for each hour, without value of state or online changes (€)"
    r_qGen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    r_qResDemand(restype, up_down, node, f, t) "Dummy to decrease demand for a reserve (MW)"
;

// Initialize a few of the results arrays as required by model dynamics.
Option clear = r_reserve;
Option clear = r_resTransfer;
Option clear = r_state;
Option clear = r_online;

* --- Diagnostics Results -----------------------------------------------------
Parameters
    d_cop(unit, t) "Coefficients of performance of conversion units"
    d_eff(unit, t) "Efficiency of generation units using fuel"
;
