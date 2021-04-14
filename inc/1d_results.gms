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
    r_totalObj(t) "Total accumulated value of the objective function over all solves"

    // Unit Operational Cost Components
    r_gnuVOMCost(grid, node, unit, f, t) "Variable O&M costs for energy outputs (MEUR)"
    r_gnuTotalVOMCost(grid, node, unit) "Total gnu VOM costs over the simulation (MEUR)"
    r_uFuelEmissionCost(node, unit, f, t) "Unit fuel & emission costs for normal operation (MEUR)"
    r_uTotalFuelEmissionCost(commodity, unit) "Total unit fuel & emission costs over the simulation for normal operation (MEUR)"
    r_uStartupCost(unit, f, t) "Unit startup VOM, fuel, & emission costs (MEUR)"
    r_uShutdownCost(unit, f, t) "Unit startup VOM, fuel, & emission costs (MEUR)"
    r_uTotalStartupCost(unit) "Total unit startup costs over the simulation (MEUR)"

    // Nodal Cost Components
    r_gnStateSlackCost(grid, node, f, t) "Costs for states requiring slack (MEUR)"
    r_gnTotalStateSlackCost(grid, node) "Total costs for state slacks over the simulation (MEUR)"
    r_gnStorageValueChange(grid, node) "Change in storage values over the simulation (MEUR)"

    // Investment and Fixed Operation and Maintenance Cost Components
    r_gnuFOMCost(grid, node, unit) "Total gnu fixed O&M costs over the simulation (MEUR)"
    r_gnuUnitInvestmentCost(grid, node, unit) "Total unit investment costs over the simulation (MEUR)"
    r_gnnLinkInvestmentCost(grid, node, node) "Total transfer link investment costs over the simulation (MEUR)"

    // Realized System Operating Costs
    r_gnRealizedOperatingCost(grid, node, f, t) "Realized system operating costs in gn for each t (MEUR)"
    r_gnTotalRealizedOperatingCost(grid, node) "Total realized system operating costs in gn over the simulation (MEUR)"
    r_gnTotalRealizedOperatingCostShare(grid, node) "Total realized system operating cost gn/g shares over the simulation"
    r_gnTotalRealizedNetOperatingCost(grid, node) "Total realized system operating costs in gn over the simulation, minus the increase in storage values (MEUR)"
    r_gTotalRealizedOperatingCost(grid) "Total realized system operating costs in g over the simulation (MEUR)"
    r_gTotalRealizedNetOperatingCost(grid) "Total realized system operating costs in g over the simulation, minus the increase in storage values (MEUR)"
    r_totalRealizedOperatingCost "Total realized system operating costs over the simulation (MEUR)" / 0 /
    r_totalRealizedNetOperatingCost "Total realized system operating costs over the simulation (MEUR)" / 0 /

    // Realized System Fixed Costs
    r_gnTotalRealizedFixedCost(grid, node) "Total realized system fixed costs in gn over the simulation (MEUR)"
    r_gnTotalRealizedFixedCostShare(grid, node) "Total realized system fixed cost gn/g shares over the simulation"
    r_gTotalRealizedFixedCost(grid) "Total realized system fixed costs in g over the simulation (MEUR)"
    r_totalRealizedFixedCost "Total realized system fixed costs over the simulation (MEUR)" / 0 /

    // Realized System Costs
    r_gnTotalRealizedCost(grid, node) "Total realized system costs in gn over the simulation (MEUR)"
    r_gnTotalRealizedCostShare(grid, node) "Total realized system cost gn/g shares over the simulation"
    r_gnTotalRealizedNetCost(grid, node) "Total realized system costs in gn over the simulation, minus the increase in storage values (MEUR)"
    r_gTotalRealizedCost(grid) "Total realized system costs in g over the simulation (MEUR)"
    r_gTotalRealizedNetCost(grid) "Total realized system costs in g over the simulation, minus the increase in storage values (MEUR)"
    r_totalRealizedCost "Total realized system costs over the simulation (MEUR)" / 0 /
    r_totalRealizedNetCost "Total realized system costs over the simulation (MEUR)" / 0 /

* --- Node Results ------------------------------------------------------------

    // State variable results, required for model structure
    r_state(grid, node, f, t) "Node state at time step t"
    // State variable slack values
    r_stateSlack(grid, node, slack, f, t) "Note state slack at time step t"

    // Energy transfer and spill variable results
    r_transfer(grid, from_node, to_node, f, t) "Energy transfer (MW)"
    r_spill(grid, node, f, t) "Spill of energy from storage node during time interval (MWh)"

    // Interesting node related results
    r_balanceMarginal(grid, node, f, t) "Marginal values of the q_balance equation"
    r_gnnTotalTransfer(grid, node, node) "Total amount of energy transferred between gnn over the simulation (MWh)"
    r_gnTotalSpill(grid, node) "Total spilled energy from gn over the simulation (MWh)"
    r_gnTotalSpillShare(grid, node) "Total spilled energy gn/g share"
    r_gTotalSpill(grid) "Total spilled energy from gn over the simulation (MWh)"

* --- Energy Generation/Consumption Results -----------------------------------

    // Results required for model structure
    r_gen(grid, node, unit, f, t) "Energy generation for a unit (MW)"
    r_gen_gnUnittype(grid, node, unittype) "Energy generation for each unittype in each node (MWh)"

    // Fuel use results
    r_fuelUse(node, unit, f, t) "Fuel use of units"
    r_genFuel(grid, node, *, f, t) "Energy generation/consumption based on fuels / flows (MW)"
    r_genUnittype(grid, node, unittype, f, t) "Energy generation/consumption for each unittype (MW)"
    r_gnTotalGenFuel(grid, node, commodity) "Total energy generation in gn per fuel over the simulation (MWh)"
    r_gnTotalGenFuelShare(grid, node, commodity) "Total energy generation fuel consumption gn/g share"
    r_gTotalGenFuel(grid, commodity) "Total energy generation in g per fuel over the simulation (MWh)"
    r_totalGenFuel(commodity) "Total overall energy generation/consumption per fuel over the simulation (MWh)"

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


* --- Emissions Results -------------------------------------------------------

    // Unit level emissions
    r_emissions (node, emission, unit, f, t) "Emissions from units (tCO2)"

    // Emission sums
    r_nuTotalEmissions (node, unit, emission) "Total emissions from units (tCO2)"
    r_nTotalEmissions(node, emission) "Emissions in gn (tCO2)"
    r_uTotalEmissions(unit, emission) "Emissions in gn (tCO2)"
    r_totalEmissions (emission) "Summed emissions (tCO2)"


* --- Unit Online State Results -----------------------------------------------

    // Online results required for model structure
    r_online(unit, f, t) "Sub-units online"
    r_startup(unit, starttype, f, t) "Sub-units started up"
    r_shutdown(unit, f, t) "Sub-units shut down"

    // Interesting unit online results
    r_uTotalOnline(unit) "Total online sub-unit-hours of units over the simulation"
    r_uTotalOnlinePerUnit(unit) "Total unit online hours per sub-unit over the simulation"

    // Interesting unit startup and shutdown results
    r_uTotalStartup(unit, starttype) "Number of sub-unit startups over the simulation"
    r_uTotalShutdown(unit) "Number of sub-unit shutdowns over the simulation"

* --- Reserve Provision Results -----------------------------------------------

    // Reserve provision results required for model structure
    r_reserve(restype, up_down, grid, node, unit, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
    r_resTransferRightward(restype, up_down, grid, node, node, f, t) "Electricity transmission capacity from the first node to the second node reserved for providing reserves (MW)"
    r_resTransferLeftward(restype, up_down, grid, node, node, f, t) "Electricity transmission capacity from the second node to the first node reserved for providing reserves (MW)"
    r_reserve2Reserve(restype, up_down, grid, node, unit, restype, f, t) "Reserve provided for another reserve category (MW) (also included in r_reserve - this is just for debugging)"

    // Interesting reserve results
    r_resDemandMarginal(restype, up_down, group, f, t) "Marginal values of the q_resDemand equation"
    r_gnuTotalReserve(restype, up_down, grid, node, unit) "Total gnu reserve provision over the simulation (MW*h)"
    r_gnuTotalReserveShare(restype, up_down, grid, node, unit) "Total gnu/group reserve provision share over the simulation"
    r_groupTotalReserve(restype, up_down, group) "Total reserve provisions in groups over the simulation (MW*h)"
    r_resDemandLargestInfeedUnit(restype, up_down, group, f, t) "Reserve Demand from the loss of largest infeed unit"

* --- Investment Results ------------------------------------------------------

    // Interesting investment results
    r_invest(unit) "Number/amount of invested sub-units"
    r_investTransfer(grid, node, node, t) "Amount of invested transfer link capacity"

* --- Group results -----------------------------------------------------------

    // gnTotalgen in units that belong to gnuGroups over the simulation
    r_gnTotalGenGnuGroup(grid, node, group) "gnTotalGen in units that belong to gnuGroup (MWh)"

* --- Dummy Variable Results --------------------------------------------------

    // Results regarding solution feasibility
    r_qGen(inc_dec, grid, node, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    r_gnTotalqGen(inc_dec, grid, node) "Total dummy energy generation/consumption in gn over the simulation (MWh)."
    r_gTotalqGen(inc_dec, grid) "Total dummy energy generation/consumption in g over the simulation (MWh)."
    r_qResDemand(restype, up_down, group, f, t) "Dummy to decrease demand for a reserve (MW) before reserve commitment"
    r_qResMissing(restype, up_down, group, f, t) "Dummy to decrease demand for a reserve (MW) after reserve commitment"
    r_groupTotalqResDemand(restype, up_down, group) "Total dummy reserve provisions in the group over the simulation"
    r_qCapacity(grid, node, f, t) "Dummy capacity to ensure capacity margin equation feasibility (MW)"
    r_solveStatus(t, solve_info) "Information about the solve"

; // END PARAMETER DECLARATION

Scalar r_realizedLast "Order of last realised time step";

* --- Initialize a few of the results arrays, required by model structure -----

Option clear = r_totalObj;
Option clear = r_state;
Option clear = r_online;
Option clear = r_reserve;
Option clear = r_resTransferRightward;
Option clear = r_resTransferLeftward;
Option clear = r_gen;
Option clear = r_realizedLast;
Option clear = r_startup;
Option clear = r_shutdown;
Option clear = r_invest;
Option clear = r_investTransfer;
Option clear = r_qResDemand;
Option clear = r_resDemandLargestInfeedUnit;

* =============================================================================
* --- Diagnostics Results Arrays ----------------------------------------------
* =============================================================================

// Only include these if '--diag=yes' given as a command line argument
$iftheni.diag '%diag%' == yes
Parameters
    d_cop(unit, f, t) "Coefficients of performance of conversion units"
    d_eff(unit, f, t) "Efficiency of generation units using fuel"
    d_capacityFactor(flow, node, s, f, t) "Diagnostic capacity factors (accounting for GAMS plotting error)"
    d_nodeState(grid, node, param_gnBoundaryTypes, s, f, t) "Diagnostic temperature forecasts (accounting for GAMS plotting error)"
    d_influx(grid, node, s, f, t) "Diagnostic influx forecasts (accounting for GAMS plotting error)"
    d_state(grid, node, scenario, f, t) "Diagnostic state results in each scenario"
    d_ts_scenarios(timeseries, *, node, scenario, f, t) "Diagnostic time series values in scenarios"
;
$endif.diag
