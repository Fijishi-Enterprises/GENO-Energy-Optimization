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

* =============================================================================
* --- Model Results Arrays ----------------------------------------------------
* =============================================================================

Parameters

* --- Cost Results ------------------------------------------------------------

    // Total Objective Function
    r_totalObj "Total operating cost over the simulation (€)" / 0 /

    // Realized System Costs
    r_gnRealizedCost(grid, node, f, t) "Realized system costs in gn for each t (MEUR)"
    r_gnTotalRealizedCost(grid, node) "Total realized system costs in gn over the simulation (MEUR)"
    r_gnTotalRealizedCostShare(grid, node) "Total realized system cost gn/g shares over the simulation"
    r_gTotalRealizedCost(grid) "Total realized system costs in g over the simulation (MEUR)"
    r_totalRealizedCost "Total realized system costs over the simulation (MEUR)" / 0 /

* --- Node Results ------------------------------------------------------------

    // State variable results, required for model structure
    r_state(grid, node, f, t) "Node state at timestep t"
    // State variable slack values
    r_stateSlack(grid, node, slack, f, t) "Note state slack at timestep t"

    // Energy transfer and spill variable results
    r_transfer(grid, from_node, to_node, f, t) "Energy transfer (MW)"
    r_spill(grid, node, f, t) "Spill of energy from storage node during time period (MWh)"

    // Interesting node related results
    r_balanceMarginal(grid, node, f, t) "Marginal values of the q_balance equation"
    r_gnnTotalTransfer(grid, node, node) "Total amount of energy transferred between gnn over the simulation (MWh)"
    r_gnTotalSpill(grid, node) "Total spilled energy from gn over the simulation (MWh)"
    r_gnTotalSpillShare(grid, node) "Total spilled energy gn/g share"
    r_gTotalSpill(grid) "Total spilled energy from gn over the simulation (MWh)"

* --- Energy Generation/Consumption Results -----------------------------------

    // Results required for model structure
    r_gen(grid, node, unit, f, t) "Energy generation for a unit (MW)"

    // Fuel use results
    r_fuelUse(fuel, unit, f, t) "Fuel use of units"
    r_genFuel(grid, node, fuel, f, t) "Energy generation/consumption based on fuels / flows (MW)"
    r_gnTotalGenFuel(grid, node, fuel) "Total energy generation in gn per fuel over the simulation (MWh)"
    r_gnTotalGenFuelShare(grid, node, fuel) "Total energy generation fuel consumption gn/g share"
    r_gTotalGenFuel(grid, fuel) "Total energy generation in g per fuel over the simulation (MWh)"
    r_totalGenFuel(fuel) "Total overall energy generation/consumption per fuel over the simulation (MWh)"

    // Interesting energy generation results
    r_gnuTotalGen(grid, node, unit) "Total energy generation in gnu over the simulation (MWh)"
    r_gnuTotalGenShare(grid, node, unit) "Total energy generation gnu/gn share"
    r_gnTotalGen(grid, node) "Total energy generation in gn over the simulation (MWh)"
    r_gnTotalGenShare(grid, node) "Total energy generation gn/g share"
    r_gTotalGen(grid) "Total energy generation in g over the simulation (MWh)"

    // Approximate utilization rates
    r_gnuUtilizationRate(grid, node, unit) "Approximate utilization rates of gnus over the simulation"

    // Interesting energy consumption results
    r_gnConsumption(grid, node, f, t) "Consumption of energy in gn for each t (MWh)"
    r_gnTotalConsumption(grid, node) "Total consumption of energy in gn over the simulation (MWh)"
    r_gnTotalConsumptionShare(grid, node) "Total consumption gn/g share"
    r_gTotalConsumption(grid) "Total consumption of energy in g over the simulation (MWh)"

* --- Unit Online State Results -----------------------------------------------

    // Online results required for model structure
    r_online(unit, f, t) "Units online"
    r_startup(unit, starttype, f, t) "Units started up"
    r_shutdown(unit, f, t) "Units shut down"

    // Interesting unit online results
    r_uTotalOnline(unit) "Total online sub-unit-hours of units over the simulation"
    r_uTotalOnlinePerUnit(unit) "Total unit online hours per sub-unit over the simulation"

    // Interesting unit startup and shutdown results
    r_uTotalStartup(unit, starttype) "Number of sub-unit startups over the simulation"
    r_uTotalShutdown(unit) "Number of sub-unit shutdowns over the simulation"

* --- Reserve Provision Results -----------------------------------------------

    // Reserve provision results required for model structure
    r_reserve(restype, up_down, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
    r_resTransferRightward(restype, up_down, node, node, f, t) "Electricity transmission capacity from the first node to the second node reserved for providing reserves (MW)"
    r_resTransferLeftward(restype, up_down, node, node, f, t) "Electricity transmission capacity from the second node to the first node reserved for providing reserves (MW)"

    // Interesting reserve results
    r_resDemandMarginal(restype, up_down, node, f, t) "Marginal values of the q_resDemand equation"
    r_nuTotalReserve(restype, up_down, node, unit) "Total nu reserve provision over the simulation (MW*h)"
    r_nuTotalReserveShare(restype, up_down, node, unit) "Total nu/n reserve provision share over the simulation"
    r_nTotalReserve(restype, up_down, node) "Total reserve provisions in nodes over the simulation (MW*h)"

* --- Dummy Variable Results --------------------------------------------------

    // Results regarding solution feasibility
    r_qGen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    r_gnTotalqGen(inc_dec, grid, node) "Total dummy energy generation/consumption in gn over the simulation (MWh)."
    r_gTotalqGen(inc_dec, grid) "Total dummy energy generation/consumption in g over the simulation (MWh)."
    r_qResDemand(restype, up_down, node, f, t) "Dummy to decrease demand for a reserve (MW)"
    r_nTotalqResDemand(restype, up_down, node) "Total dummy reserve provisions in n over the simulation"
    r_solveStatus(t, solve_info) "Information about the solve"

$ontext
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

;
$offtext

Scalar r_realizedLast "Order of last realised time step";

* --- Initialize a few of the results arrays, required by model structure -----

Option clear = r_state;
Option clear = r_online;
Option clear = r_reserve;
Option clear = r_resTransferRightward;
Option clear = r_resTransferLeftward;
Option clear = r_gen;
Option clear = r_realizedLast;
Option clear = r_startup;
Option clear = r_shutdown;

* =============================================================================
* --- Diagnostics Results Arrays ----------------------------------------------
* =============================================================================

Parameters
    d_cop(unit, f, t) "Coefficients of performance of conversion units"
    d_eff(unit, f, t) "Efficiency of generation units using fuel"
    d_capacityFactor(flow, node, f, t) "Diagnostic capacity factors (accounting for GAMS plotting error)"
;
