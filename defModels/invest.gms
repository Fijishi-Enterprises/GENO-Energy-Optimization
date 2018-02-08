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
* --- Invest Model Equations --------------------------------------------------
* =============================================================================

Model invest /
    q_obj
    q_balance
    q_resDemand

    // Unit Equations
    q_maxDownward
    q_maxUpward
    q_startup
    q_startuptype
    q_onlineLimit
    q_onlineMinUptime
*    q_minDown
*    q_genRamp
*    q_genRampChange
*    q_rampUpLimit
*    q_rampDownLimit
    q_outputRatioFixed
    q_outputRatioConstrained
    q_maxFuelFraction
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
    q_fixedGenCap1U
    q_fixedGenCap2U

    // Energy Transfer
    q_transfer
    q_transferRightwardLimit
    q_transferLeftwardLimit
    q_resTransferLimitRightward
    q_resTransferLimitLeftward

    // State Variables
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundStateMaxDiff
    q_boundCyclic

    // Policy
    q_capacityMargin
    q_emissioncap
    q_instantaneousShareMax
    q_energyShareMax
    q_energyShareMin
    q_inertiaMin
/;

* =============================================================================
* --- Invest Model Attributes -------------------------------------------------
* =============================================================================

invest.holdfixed = 1; // Fixed variables are treated as constants
invest.trylinear = 1; // Try to solve using LP if possible
