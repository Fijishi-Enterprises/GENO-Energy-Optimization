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
    // Variables required for model structure
    r_state(grid, node, f, t) "Node state at timestep t"
    r_online(unit, f, t) "Units online"
    r_reserve(restype, up_down, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
    r_resTransferRightward(restype, up_down, node, node, f, t) "Electricity transmission capacity from the first node to the second node reserved for providing reserves (MW)"
    r_resTransferLeftward(restype, up_down, node, node, f, t) "Electricity transmission capacity from the second node to the first node reserved for providing reserves (MW)"
    r_gen(grid, node, unit, f, t) "Energy generation for a unit (MW)"
    r_startup(unit, starttype, f, t) "Units started up"
    r_shutdown(unit, f, t) "Units shut down"

    // Variables and equations of interest
    r_fuelUse(fuel, unit, f, t) "Fuel use of units"
    r_genFuel(grid, node, fuel, f, t) "Energy generation/consumption based on fuels / flows (MW)"
    r_transfer(grid, from_node, to_node, f, t) "Energy transfer (MW)"
    r_spill(grid, node, f, t) "Spill of energy from storage node during time period (MWh)"
    r_balanceMarginal(grid, node, f, t) "Marginal values of the q_balance equation"
    r_resDemandMarginal(restype, up_down, node, f, t) "Marginal values of the q_resDemand equation"

    // Total variable value arrays
    r_totalObj "Total operating cost over the simulation (€)" / 0 /
    r_gnuTotalGen(grid, node, unit) "Total energy generation/consumption in gnu over the simulation (MWh)"
    r_gnTotalGenFuel(grid, node, fuel) "Total energy generation/consumption in gn per fuel over the simulation (MWh)"
    r_totalGenFuel(fuel) "Total overall energy generation/consumption per fuel over the simulation (MWh)"
    r_gnnTotalTransfer(grid, node, node) "Total amount of energy transferred between gnn over the simulation (MWh)"
    r_gnTotalSpill(grid, node) "Total spilled enegy from gn over the simulation (MWh)"

    // Interesting results requiring further calculations
    r_gnConsumption(grid, node, f, t) "Consumption of energy in gn for each t (MWh)"
    r_gnTotalConsumption(grid, node) "Total consumption of energy in gn over the simulation (MWh)"
    r_gnRealizedCost(grid, node, f, t) "Realized system costs in gn for each t (MEUR)"
    r_gnTotalRealizedCost(grid, node) "Total realized system costs in gn over the simulation (MEUR)"
    r_totalRealizedCost "Total realized system costs over the simulation (MEUR)" / 0 /

    // Old results arrays
*    r_genNodeType(grid, node, unitType, t) "Energy generation/consumption based on unittypes (MW)"
*    r_genType(grid, unitType, t) "Energy generation/consumption based on unittypes (MW)"
*    r_elec_type(unittype, t) "Average electricity generation rate of generator type (MW)"
*    r_demand(grid, node, t) "Average energy demand (MW)"
*    r_capacity_type(unittype) "Available generation capacity by type (MW)"
*    r_elecConsumption(unit, t) "Average electricity consumption rate during hour (MW)"
*    r_storageValue(node, t) "Storage value (€/MWh)"
*    r_storageControl(node, t) "Storage control during hour (MWh)"
*    r_energyPrice(grid, node, t) "Marginal cost of energy generation (MWh)"
*    r_cost(t) "Total operating cost for each hour, without value of state or online changes (€)"

    // Dummy variable arrays for solution feasibility
    r_qGen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    r_qResDemand(restype, up_down, node, f, t) "Dummy to decrease demand for a reserve (MW)"
    r_solveStatus(t, solve_info) "Information about the solve"
;

Scalar r_realizedLast "Order of last realised time step";

// Initialize a few of the results arrays, required by model structure.
Option clear = r_state;
Option clear = r_online;
Option clear = r_reserve;
Option clear = r_resTransferRightward;
Option clear = r_resTransferLeftward;
Option clear = r_gen;
Option clear = r_realizedLast;
Option clear = r_startup;
Option clear = r_shutdown;

* --- Diagnostics Results -----------------------------------------------------
Parameters
    d_cop(unit, f, t) "Coefficients of performance of conversion units"
    d_eff(unit, f, t) "Efficiency of generation units using fuel"
;
