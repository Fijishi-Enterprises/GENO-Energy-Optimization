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

* --- Results required for the model structure --------------------------------

r_state // Conserves state variable values between solves
r_online // Conserves online variable values between solves
r_reserve // Conserves locked reserve variables between solves
r_resTransferRightward // Conserves locked reserve transfer variables between solves
r_resTransferLeftward // Conserves locked reserve transfer variables between solves
r_gen // Conserves locked generation variables between solves
r_startup // Conserves locked startup variables between solves
r_shutdown // Conserves locked shutdown variables between solves

* --- Other desired results ---------------------------------------------------

// Interesting variable and equation values
r_fuelUse
r_genFuel
r_transfer
r_spill
r_balanceMarginal
r_resDemandMarginal

// Results requiring calculations
r_gnConsumption
r_gnRealizedCost

// Total result arrays
r_totalObj
r_gnuTotalGen
r_gnTotalGen
r_gTotalGen
r_gnTotalGenFuel
r_gTotalGenFuel
r_totalGenFuel
r_gnnTotalTransfer
r_gnTotalSpill
r_gTotalSpill
r_gnTotalConsumption
r_gTotalConsumption
r_gnTotalRealizedCost
r_gTotalRealizedCost
r_totalRealizedCost
r_nuTotalReserve
r_nTotalReserve
r_uTotalOnline
r_uTotalOnlinePerUnit
r_gnuUtilizationRate

// Diagnostics
d_cop
d_eff
d_capacityFactor

// Dummy variables for solution feasibility reasons
r_qGen
r_qResDemand

// Solve/model information
r_solveStatus

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

// Metadata and settings
metadata
mSettings

