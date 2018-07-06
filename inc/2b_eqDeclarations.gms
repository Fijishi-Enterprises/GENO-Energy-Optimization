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
* --- Penalty Definitions -----------------------------------------------------
* =============================================================================

$setlocal def_penalty 1e4
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (EUR/MWh)"
    PENALTY_RES(restype, up_down) "Penalty on violating a reserve (EUR/MW)"
    PENALTY_RES_MISSING(restype, up_down) "Penalty on violating a reserve (EUR/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(restype, up_down) = 0.9*%def_penalty%;
PENALTY_RES_MISSING(restype, up_down) = 0.1*%def_penalty%;


* =============================================================================
* --- Equation Declarations ---------------------------------------------------
* =============================================================================

equations
    // Objective Function, Energy Balance, and Reserve demand
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, up_down, node, f, t) "Procurement for each reserve type is greater than demand"

    // Unit Operation
    q_maxDownward(mType, grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(mType, grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_startshut(mType, unit, f, t) "Online cap. now minus online cap in the previous time step is equal to started up minus shut down capacity"
    q_startuptype(mType, starttype, unit, f, t) "Startup type depends on the time the unit has been non-operational"
    q_onlineOnStartUp(unit, f, t) "Unit must be online after starting up"
    q_offlineAfterShutdown(unit, f, t) "Unit must be offline after shutting down"
    q_onlineLimit(mType, unit, f, t) "Number of online units limited for units with startup constraints and investment possibility"
    q_onlineMinUptime(mType, unit, f, t) "Unit must stay operational if it has started up during the previous minOperationHours hours"
    q_genRamp(mType, grid, node, s, unit, f, t) "Record the ramps of units with ramp restricitions or costs"
    q_rampUpLimit(mType, grid, node, s, unit, f, t) "Up ramping limited for units"
    q_rampDownLimit(grid, node, mType, s, unit, f, t) "Down ramping limited for units"
    q_outputRatioFixed(grid, node, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, node, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
    q_conversionDirectInputOutput(effSelector, unit, f, t) "Direct conversion of inputs to outputs (no piece-wise linear part-load efficiencies)"
    q_conversionSOS2InputIntermediate(effSelector, unit, f, t)   "Intermediate output when using SOS2 variable based part-load piece-wise linearization"
    q_conversionSOS2Constraint(effSelector, unit, f, t)          "Sum of v_sos2 has to equal v_online"
    q_conversionSOS2IntermediateOutput(effSelector, unit, f, t)  "Output is forced equal with v_sos2 output"

    // Energy Transfer
    q_transfer(grid, node, node, f, t) "Rightward and leftward transfer must match the total transfer"
    q_transferRightwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the rightward direction are less than the transfer capacity"
    q_transferLeftwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the leftward direction are less than the transfer capacity"
    q_resTransferLimitRightward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the rightward direction"
    q_resTransferLimitLeftward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the leftward direction"

    // State Variables
    q_stateSlack(grid, node, slack, f, t) "Slack variable greater than the difference between v_state and the slack boundary"
    q_stateUpwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_stateDownwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_boundStateMaxDiff(grid, node, node, mType, f, t) "Node state variables bounded by other nodes (maximum state difference)"
    q_boundCyclic(grid, node, mType, s, s) "Cyclic bound for the first and the last states of samples"

    // Policy
    q_inertiaMin(group, f, t) "Minimum inertia in a group of nodes"
    q_instantaneousShareMax(group, f, t) "Maximum instantaneous share of generation and controlled import from a group of units and links"
    q_constrainedOnlineMultiUnit(group, f, t) "Constrained number of online units for a group of units"
    q_capacityMargin(grid, node, f, t) "There needs to be enough capacity to cover energy demand plus a margin"
    q_constrainedCapMultiUnit(group, t) "Constrained unit number ratios and sums for a group of units"
    q_emissioncap(group, emission) "Limit for emissions"
    q_energyShareMax(group) "Maximum energy share of generation and import from a group of units"
    q_energyShareMin(group) "Minimum energy share of generation and import from a group of units"
;
