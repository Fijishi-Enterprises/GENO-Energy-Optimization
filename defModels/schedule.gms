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
* --- Schedule Model Equations ------------------------------------------------
* =============================================================================

Model schedule /
    q_obj
    q_balance
    q_resDemand
    q_resDemandLargestInfeedUnit

    // Unit Operation
    q_maxDownward
    q_maxUpward
    q_maxUpward2
*    q_maxUpward3
*    q_reserveProvision
    q_startshut
    q_startuptype
    q_onlineLimit
    q_onlineOnStartUp
    q_offlineAfterShutDown
    q_onlineMinUptime
*   q_onlineCyclic
    q_genRamp
    q_rampUpLimit
*    q_rampUpLimit2
    q_rampDownLimit
    q_rampUpDown
    q_rampSlack
    q_outputRatioFixed
    q_outputRatioConstrained
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
    q_conversionIncHR
    q_conversionIncHRMaxGen
    q_conversionIncHRBounds
    q_conversionIncHR_help1
    q_conversionIncHR_help2
    q_fuelUseLimit

    // Energy Transfer
    q_transfer
    q_transferRightwardLimit
    q_transferLeftwardLimit
    q_resTransferLimitRightward
    q_resTransferLimitLeftward
*    q_reserveProvisionRightward
*    q_reserveProvisionLeftward

    // State Variables
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundStateMaxDiff
    q_boundCyclic

    // Policy
    q_inertiaMin
    q_instantaneousShareMax
    q_constrainedOnlineMultiUnit
*    q_capacityMargin
*    q_constrainedCapMultiUnit
*    q_emissioncap
*    q_energyShareMax
*    q_energyShareMin
    q_minCons
$ifthen exist '%input_dir%/schedule_additional_constraints.gms'
   $$include '%input_dir%/schedule_additional_constraints.gms'      // Declare additional constraints from the input data
$endif
/;

