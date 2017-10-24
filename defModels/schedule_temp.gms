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

if (mType('schedule'),
    m('schedule') = yes; // Definition, that the model exists by its name

    // Define the temporal structure of the model in time indeces
    mSettings('schedule', 'intervalInHours') = 1; // Define the duration of a single time-step in hours
    mInterval('schedule', 'intervalLength', 'c000') = 1;
    mInterval('schedule', 'intervalEnd', 'c000') = 48;
    mInterval('schedule', 'intervalLength', 'c001') = 3;
    mInterval('schedule', 'intervalEnd', 'c001') = 336;
    mInterval('schedule', 'intervalLength', 'c002') = 6;
    mInterval('schedule', 'intervalEnd', 'c002') = 1680;
    mInterval('schedule', 'intervalLength', 'c003') = 24;
    mInterval('schedule', 'intervalEnd', 'c003') = 4392;
    mInterval('schedule', 'intervalLength', 'c004') = 168;
    mInterval('schedule', 'intervalEnd', 'c004') = 8760;

    // Define the model execution parameters in time indeces
    mSettings('schedule', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('schedule', 't_horizon') = 168;
    mSettings('schedule', 't_jump') = 3;
    mSettings('schedule', 't_forecastStart') = 1; // Ord of first forecast available
    mSettings('schedule', 't_forecastLength') = 72;
    mSettings('schedule', 't_forecastJump') = 24;
    mSettings('schedule', 't_end') = 30;
    mSettings('schedule', 't_reserveLength') = 36;

    // Define unit aggregation and efficiency levels starting indeces
    mSettings('schedule', 't_aggregate') = 72;
    mSettingsEff('schedule', 'level1') = 1;
    mSettingsEff('schedule', 'level2') = 6;
    mSettingsEff('schedule', 'level3') = 12;
    mSettingsEff('schedule', 'level4') = 18;
    //mSettingsEff('schedule', 'level1') = 1;
    //mSettingsEff('schedule', 'level2') = 24;
    //mSettingsEff('schedule', 'level3') = 48;
    //mSettingsEff('schedule', 'level4') = 168;

    // Define active model features
    active('schedule', 'storageValue') = yes;

    // Define model stochastic parameters
    mSettings('schedule', 'samples') = 1;
    mSettings('schedule', 'forecasts') = 3;
    mSettings('schedule', 'readForecastsInTheLoop') = 1;
    mf('schedule', f)$[ord(f)-1 <= mSettings('schedule', 'forecasts')] = yes;
    mfRealization('schedule', f) = no;
    mfRealization('schedule', 'f00') = yes;
    mfCentral('schedule', f) = no;
    mfCentral('schedule', 'f02') = yes;
    msInitial('schedule', s) = no;
    msInitial('schedule', 's000') = yes;
    msCentral('schedule', s) = no;
    msCentral('schedule', 's001') = yes;

    p_stepLength('schedule', f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later
    p_msProbability('schedule', s) = 0;
    p_msProbability('schedule', 's000') = 1;
    p_mfProbability('schedule', f) = 0;
    p_mfProbability(mfRealization('schedule', f)) = 1;
    p_mfProbability('schedule', 'f01') = 0.2;
    p_mfProbability('schedule', 'f02') = 0.6;
    p_mfProbability('schedule', 'f03') = 0.2;

    msStart('schedule', 's000') = 1;
    msEnd('schedule', 's000') = msStart('invest', 's000') + 8759;
);

Model schedule /
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
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
*    q_fixedGenCap1U
*    q_fixedGenCap2U

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
*    q_capacityMargin
*    q_emissioncap
*    q_instantaneousShareMax
*    q_energyShareMax
*    q_energyShareMin
*    q_inertiaMin
/;

