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
sft
ft_realized
sft_realized
t_active
t_current
t_full
t_invest
uft
uft_online
uft_onlineLP
uft_onlineMIP
uft_onlineLP_withPrevious
uft_onlineMIP_withPrevious

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
p_groupReserves
p_gnuReserves
p_gnPolicy
p_groupPolicy
p_groupPolicy3D
p_nEmission
p_unitEmissionCost
p_effUnit
p_effGroupUnit
p_uNonoperational
p_uStartupfuel
p_u_maxOutputInLastRunUpInterval
p_u_runUpTimeIntervals
dt_toStartup
p_uCounter_runUpMin
p_uCounter_runUpMax
p_u_maxOutputInFirstShutdownInterval
p_u_shutdownTimeIntervals
dt_toShutdown
p_uCounter_shutdownMin
p_uCounter_shutdownMax

* Variables
v_obj
v_gen
v_gen_inc
v_genRamp
v_transfer
v_state
v_sos2
v_spill
v_online_LP
v_online_MIP
v_startup_LP
v_startup_MIP
v_shutdown_LP
v_shutdown_MIP
v_genRampUpDown
v_transferRightward
v_transferLeftward
v_resTransferRightward
v_resTransferLeftward
v_reserve
v_investTransfer_LP
v_investTransfer_MIP
v_invest_LP
v_invest_MIP
v_help_inc

* equations
    q_obj
    q_balance
    q_resDemand
    q_resDemandLargestInfeedUnit
    q_rateOfChangeOfFrequencyUnit
    q_rateOfChangeOfFrequencyTransfer
    q_resDemandLargestInfeedTransfer

    // Unit Operation
    q_maxDownward
    q_maxDownwardOfflineReserve
    q_maxUpward
    q_maxUpwardOfflineReserve
    q_reserveProvision
    q_reserveProvisionOnline
    q_startshut
    q_startuptype
    q_onlineLimit
    q_onlineOnStartUp
    q_offlineAfterShutDown
    q_onlineMinUptime
    q_onlineCyclic
    q_genRamp
    q_rampUpLimit
    q_rampDownLimit
    q_rampUpDown
    q_rampSlack
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
    q_conversionIncHR
    q_conversionIncHRMaxOutput
    q_conversionIncHRBounds
    q_conversionIncHR_help1
    q_conversionIncHR_help2
*    q_commodityUseLimit

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
    q_inertiaMin
    q_instantaneousShareMax
    q_constrainedOnlineMultiUnit
    q_capacityMargin
    q_constrainedCapMultiUnit
    q_emissioncap
    q_energyShareMax
    q_energyShareMin

* Dummy variables
vq_gen
vq_resDemand
vq_resMissing
v_stateSlack
vq_capacity
