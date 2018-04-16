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

* sets
ft
ft_realized
t_active
t_current
t_full
t_invest

* Parameters
tSolveFirst
tSolveLast
p_stepLength
p_unit
*ts_cf
*ts_unit
*ts_effUnit
*ts_effGroupUnit
p_gn
p_gnBoundaryPropertiesForStates
p_gnn
p_gnu
p_nReserves
p_nuReserves
p_gnPolicy
p_groupPolicy
p_groupPolicy3D
p_fuelEmission
p_uFuel
p_unitFuelEmissionCost
p_effUnit
p_effGroupUnit
p_uNonoperational
p_uStartup
p_u_maxOutputInLastRunUpInterval
p_u_runUpTimeIntervals
dt_toStartup
p_ut_runUp

* Variables
v_obj
v_gen
v_genRamp
v_transfer
v_state
v_fuelUse
v_sos2
v_startup
v_spill
v_online_LP
v_online_MIP
v_startup
v_shutdown
v_resTransferRightward
v_resTransferLeftward
v_reserve
v_investTransfer_LP
v_investTransfer_MIP
v_invest_LP
v_invest_MIP

* equations
    q_obj
    q_balance
    q_resDemand

    // Unit Operation
    q_maxDownward
    q_noReserveInRunUp
    q_maxUpward
    q_startshut
    q_startuptype
    q_onlineLimit
    q_onlineOnStartUp
    q_offlineAfterShutDown
    q_onlineMinUptime
    q_genRamp
    q_rampUpLimit
    q_rampDownLimit
    q_outputRatioFixed
    q_outputRatioConstrained
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput

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

* Dummy variables
vq_gen
vq_resDemand
v_stateSlack
