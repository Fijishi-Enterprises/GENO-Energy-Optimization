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
* --- Building Model Equations ------------------------------------------------
* =============================================================================

Model building /
    q_obj
    q_balance
*    q_resDemand
*    q_resDemandLargestInfeedUnit

    // Unit Operation
    q_maxDownward
    q_maxUpward
*    q_reserveProvision
*    q_startup
*    q_startuptype
*    q_onlineLimit
*    q_onlineMinUptime
*    q_minDown
*    q_genRamp
*    q_genRampChange
*    q_rampUpLimit
*    q_rampDownLimit
*    q_outputRatioFixed
*    q_outputRatioConstrained
    q_conversionDirectInputOutput
*    q_conversionSOS2InputIntermediate
*    q_conversionSOS2Constraint
*    q_conversionSOS2IntermediateOutput
*    q_fuelUseLimit

    // Energy Transfer
    q_transfer
    q_transferRightwardLimit
    q_transferLeftwardLimit
*    q_resTransferLimitRightward
*    q_resTransferLimitLeftward
*    q_reserveProvisionRightward
*    q_reserveProvisionLeftward

    // State Variables
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundStateMaxDiff
    q_boundCyclic

    // Policy
*    q_inertiaMin
*    q_instantaneousShareMax
*    q_constrainedOnlineMultiUnit
*    q_capacityMargin
*    q_constrainedCapMultiUnit
*    q_emissioncap
*    q_energyShareMax
*    q_energyShareMin

$ifthen exist '%input_dir%/building_additional_constraints.gms'
   $$include '%input_dir%/building_additional_constraints.gms'      // Declare additional constraints from the input data
$endif
/;
