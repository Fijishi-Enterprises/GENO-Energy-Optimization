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
m
s_active
s_prev
ss
f_solve
t_start
t_full
t_datalength
t_current
t_active
t_invest
t_realized
t_latestForecast
tt
tt_block
tt_interval
tt_forecast
tt_aggregate

mf
mf_realization
mf_central
ms
ms_initial
ms_central
ft
ft_realized
ft_realizedNoReset
ft_reservesFixed
mft
mft_start
mft_lastSteps
msf
mst
mst_start
mst_end
sft
sft_realized
sft_realizedNoReset
msft
msft_realizedNoReset

modelSolves
gnss_bound
uss_bound

usft
usft_online
usft_onlineLP
usft_onlineMIP
usft_onlineLP_withPrevious
usft_onlineMIP_withPrevious
usft_startupTrajectory
usft_shutdownTrajectory
usft_aggregator_first
gnusft
gnusft_ramp
gnusft_rampCost

eff_usft
effGroup
effGroupSelector
effLevelGroupUnit
effGroupSelectorUnit

mSettingsReservesInUse
unitCounter
runUpCounter
shutdownCounter
utAvailabilityLimits

gn2nsft_directional_rampConstrained

uGroup
gnuGroup
gn2nGroup
gnGroup
sGroup
emissionGroup

mTimeseries_loop_read


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
p_groupPolicy
p_groupPolicyUnit
p_groupPolicyEmission
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
    q_fixedFlow
    q_reserveProvision
    q_reserveProvisionOnline
    q_startshut
    q_startuptype
    q_onlineOnStartUp
    q_offlineAfterShutDown
    q_onlineLimit
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
    q_unitEqualityConstraint
    q_unitGreaterThanConstraint

    // Energy Transfer
    q_transfer
    q_transferRightwardLimit
    q_transferLeftwardLimit
    q_transferRamp
    q_transferRampLimit1
    q_transferRampLimit2
    q_resTransferLimitRightward
    q_resTransferLimitLeftward
    q_reserveProvisionRightward
    q_reserveProvisionLeftward
    q_transferTwoWayLimit1
    q_transferTwoWayLimit2

    // State Variables
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundStateMaxDiff
    q_boundCyclic

    // superpositioned state variables
    q_superposSampleBegin
    q_superposBoundEnd
    q_superposInter
    q_superposStateMax
    q_superposStateMin
    q_superposStateUpwardLimit
    q_superposStateDownwardLimit

    // Policy
    q_inertiaMin
    q_instantaneousShareMax
    q_constrainedOnlineMultiUnit
    q_capacityMargin
    q_constrainedCapMultiUnit
    q_emissioncapNodeGroup
    q_energyLimit
    q_energyShareLimit
    q_ReserveShareMax

* Dummy variables
v_stateSlack
vq_gen
vq_resDemand
vq_resMissing
vq_capacity
