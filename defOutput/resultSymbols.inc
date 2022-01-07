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

* --- Symbols related to the simulation setup ---------------------------------
t_realized = t

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
r_gnnVariableTransCost
r_gnnTotalVariableTransCost
r_gnnTransferValue
r_gnnTotalTransferValue

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
r_transferRightward
r_transferLeftward
r_spill

// Interesting node related results
r_balanceMarginal
r_balanceMarginalAverage
r_gnnTotalTransfer
r_gnTotalSpill
r_gnTotalSpillShare
r_gTotalSpill
r_gnnDiffusion

* --- Energy Generation/Consumption Result Symbols ----------------------------

// Results required for model structure !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
r_gen

// Energy output results based on input types or unittypes
r_genFuel
r_genUnittype
r_gnTotalGenFuel
r_gnTotalGenFuelShare
r_gTotalGenFuel
r_totalGenFuel

// Interesting energy generation results
r_gnuTotalGen
r_gnuTotalGen_unittype   
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

// Start-up consumption results
r_nuStartupConsumption

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

* --- Emissions Results -----------------------------------------------

// Unit level emissions from normal operation
r_emissions

// Unit level emissions from outputs, not considered in the equations
r_emissionsFromOutput

// Unit level emissions from start-ups
r_emissionsStartup

// Emission sums
r_nuTotalEmissionsOperation
r_nuTotalEmissionsFromOutput
r_nuTotalEmissionsStartup
r_nuTotalEmissions
r_nTotalEmissions
r_uTotalEmissions
r_totalEmissions

* --- Reserve Provision Result Symbols ----------------------------------------

// Reserve provision results required for model structure !!!!!!!!!!!!!!!!!!!!!
r_reserve
r_reserve2Reserve
r_resTransferRightward
r_resTransferLeftward

// Interesting reserve results
r_resDemandMarginal
r_resDemandMarginalAverage
r_gnuTotalReserve
r_gnuTotalReserveShare
r_gnTotalReserve
r_gnnTotalResTransferRightward
r_gnnTotalResTransferLeftward
r_groupTotalReserve
r_resDemandLargestInfeedUnit

* --- Investment Result Symbols -----------------------------------------------

// Interesting investment results
r_invest
r_investTransfer

* --- Sum results for groups --------------------------------------------------

// gnTotalgen in units that belong to gnuGroups over the simulation
r_gnTotalGenGnuGroup

* --- Dummy and Diagnostic Variable Result Symbols ----------------------------

// Results regarding solution feasibility
r_qGen
r_gnTotalqGen
r_gTotalqGen
r_qResDemand
r_qResMissing
r_groupTotalqResDemand
r_qCapacity
r_solveStatus

// Diagnostics
$iftheni.diag '%diag%' == yes
d_cop
d_eff
d_capacityFactor
d_nodeState
d_influx
d_state
$endif.diag

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
