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
* --- Results Symbols Included in Output --------------------------------------
* =============================================================================

* --- Cost Result Symbols -----------------------------------------------------

// Total Objective Function
r_totalObj

// Unit Operational Cost Components
r_gnuVOMCost
r_gnuTotalVOMCost
r_uFuelEmissionCost
r_uTotalFuelEmissionCost
r_uStartupCost
r_uTotalStartupCost

// Nodal Cost Components
r_gnStateSlackCost
r_gnTotalStateSlackCost
r_gnStorageValueChange

// Investment and Fixed Operation and Maintenance Cost Components
r_gnuFOMCost
r_gnuUnitInvestmentCost
r_gnnLinkInvestmentCost

// Realized System Operating Costs
r_gnRealizedOperatingCost
r_gnTotalRealizedOperatingCost
r_gnTotalRealizedOperatingCostShare
r_gnTotalRealizedNetOperatingCost
r_gTotalRealizedOperatingCost
r_gTotalRealizedNetOperatingCost
r_totalRealizedOperatingCost
r_totalRealizedNetOperatingCost

// Realized System Costs
r_gnTotalRealizedCost
r_gnTotalRealizedCostShare
r_gnTotalRealizedNetCost
r_gTotalRealizedCost
r_gTotalRealizedNetCost
r_totalRealizedCost
r_totalRealizedNetCost

* --- Node Result Symbols -----------------------------------------------------

// State variable results, required for model structure !!!!!!!!!!!!!!!!!!!!!!!
r_state
// State variable slack results
r_stateSlack

// Energy transfer and spill variable results
r_transfer
r_spill

// Interesting node related results
r_balanceMarginal
r_gnnTotalTransfer
r_gnTotalSpill
r_gnTotalSpillShare
r_gTotalSpill

* --- Energy Generation/Consumption Result Symbols ----------------------------

// Results required for model structure !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
r_gen

// Fuel use results
r_fuelUse
r_genFuel
r_genUnittype
r_gnTotalGenFuel
r_gnTotalGenFuelShare
r_gTotalGenFuel
r_totalGenFuel

// Interesting energy generation results
r_gnuTotalGen
r_gnuTotalGenShare
r_gnTotalGen
r_gnTotalGenShare
r_gTotalGen

// Approximate utilization rates
r_gnuUtilizationRate

// Interesting energy consumption results
r_gnConsumption
r_gnTotalConsumption
r_gnTotalConsumptionShare
r_gTotalConsumption

* --- Unit Online State Result Symbols ----------------------------------------

// Online results required for model structure !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
r_online
r_startup
r_shutdown

// Interesting unit online results
r_uTotalOnline
r_uTotalOnlinePerUnit

// Interesting unit startup and shutdown results
r_uTotalStartup
r_uTotalShutdown

* --- Reserve Provision Result Symbols ----------------------------------------

// Reserve provision results required for model structure !!!!!!!!!!!!!!!!!!!!!
r_reserve
r_resTransferRightward
r_resTransferLeftward

// Interesting reserve results
r_resDemandMarginal
r_nuTotalReserve
r_nuTotalReserveShare
r_nTotalReserve

* --- Investment Result Symbols -----------------------------------------------

// Interesting investment results
r_invest
r_investTransfer

* --- Dummy and Diagnostic Variable Result Symbols ----------------------------

// Results regarding solution feasibility
r_qGen
r_gnTotalqGen
r_gTotalqGen
r_qResDemand
r_nTotalqResDemand
r_qCapacity
r_solveStatus

// Diagnostics
d_cop
d_eff
d_capacityFactor
d_nodeState

// Metadata and settings
metadata
mSettings

// OLD RESULTS, mostly here for inspiration
*r_elec_type
*r_demand
*r_onlineCap
*r_heat
*r_capacity_type
*r_elecConsumption
*r_storageValue
*r_storageControl
*r_elecPrice
*r_cost
