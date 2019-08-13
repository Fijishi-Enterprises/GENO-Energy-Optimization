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
* --- Model Definition - Schedule ---------------------------------------------
* =============================================================================

if (mType('schedule'),
    m('schedule') = yes; // Definition, that the model exists by its name

* --- Define Key Execution Parameters in Time Indeces -------------------------

    // Define simulation start and end time indeces
    mSettings('schedule', 't_start') = 1;  // First time step to be solved, 1 corresponds to t000001 (t000000 will then be used for initial status of dynamic variables)
    mSettings('schedule', 't_end') = 24; // Last time step to be included in the solve (may solve and output more time steps in case t_jump does not match)

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('schedule', 't_horizon') = 48;    // How many active time steps the solve contains (aggregation of time steps does not impact this, unless the aggregation does not match)
    mSettings('schedule', 't_jump') = 3;          // How many time steps the model rolls forward between each solve

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    // Number of samples used by the model
    mSettings('schedule', 'samples') = 0;

    // Define Initial and Central samples
    ms_initial('schedule', s) = no;
    ms_initial('schedule', 's000') = yes;
    ms_central('schedule', s) = no;
    ms_central('schedule', 's000') = yes;

    // Define time span of samples
    msStart('schedule', 's000') = 1;
    msEnd('schedule', 's000') = msStart('schedule', 's000') + mSettings('schedule', 't_horizon');

    // Define the probability (weight) of samples
    p_msProbability('schedule', s) = 0;
    p_msProbability('schedule', 's000') = 1;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('schedule', 'stepLengthInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('schedule', 'stepsPerInterval', 'c000') = 1;
    mInterval('schedule', 'lastStepInIntervalBlock', 'c000') = 48;
    mInterval('schedule', 'stepsPerInterval', 'c001') = 24;
    mInterval('schedule', 'lastStepInIntervalBlock', 'c001') = 168;
    mInterval('schedule', 'stepsPerInterval', 'c002') = 168;
    mInterval('schedule', 'lastStepInIntervalBlock', 'c002') = 840;
    mInterval('schedule', 'stepsPerInterval', 'c003') = 720;
    mInterval('schedule', 'lastStepInIntervalBlock', 'c003') = 8760;
    mInterval('schedule', 'stepsPerInterval', 'c004') = 168;
    mInterval('schedule', 'lastStepInIntervalBlock', 'c004') = 8760;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('schedule', 'forecasts') = 0;

    // Define forecast properties and features
    mSettings('schedule', 't_forecastStart') = 1;                  // At which time step the first forecast is available ( 1 = t000001 )
    mSettings('schedule', 't_forecastLengthUnchanging') = 36;      // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('schedule', 't_forecastLengthDecreasesFrom') = 168;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('schedule', 't_forecastJump') = 24;                  // How many time steps before new forecast is available

    mTimeseries_loop_read('schedule', 'ts_reserveDemand') = no;
    mTimeseries_loop_read('schedule', 'ts_unit') = no;
    mTimeseries_loop_read('schedule', 'ts_effUnit') = no;
    mTimeseries_loop_read('schedule', 'ts_effGroupUnit') = no;
    mTimeseries_loop_read('schedule', 'ts_influx') = no;
    mTimeseries_loop_read('schedule', 'ts_cf') = no;
    mTimeseries_loop_read('schedule', 'ts_reserveDemand') = no;
    mTimeseries_loop_read('schedule', 'ts_node') = no;
    mTimeseries_loop_read('schedule', 'ts_fuelPriceChange') = no;
    mTimeseries_loop_read('schedule', 'ts_unavailability') = no;

    // Define Realized and Central forecasts
    mf_realization('schedule', f) = no;
    mf_realization('schedule', 'f00') = yes;
    mf_central('schedule', f) = no;
    mf_central('schedule', 'f02') = yes;

    // Define forecast probabilities (weights)
    p_mfProbability('schedule', f) = 0;
    p_mfProbability(mf_realization('schedule', f)) = 1;
    p_mfProbability('schedule', 'f01') = 0.2;
    p_mfProbability('schedule', 'f02') = 0.6;
    p_mfProbability('schedule', 'f03') = 0.2;

    // Define active model features
    active('schedule', 'storageValue') = yes;

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* --- Define Reserve Properties -----------------------------------------------

    // Define whether reserves are used in the model
    mSettingsReservesInUse('schedule', 'primary', 'up') = yes;
    mSettingsReservesInUse('schedule', 'primary', 'down') = yes;
    mSettingsReservesInUse('schedule', 'secondary', 'up') = yes;
    mSettingsReservesInUse('schedule', 'secondary', 'down') = yes;
    mSettingsReservesInUse('schedule', 'tertiary', 'up') = yes;
    mSettingsReservesInUse('schedule', 'tertiary', 'down') = yes;

* --- Define Unit Approximations ----------------------------------------------

    // Define the last time step for each unit aggregation and efficiency level (3a_periodicInit.gms ensures that there is a effLevel until t_horizon)
    mSettingsEff('schedule', 'level1') = 48;

    // Define the horizon when start-up and shutdown trajectories are considered
    mSettings('schedule', 't_trajectoryHorizon') = 8760;

* --- Define output settings for results --------------------------------------

    // Define the length of the initialization period. Results outputting starts after the period. Uses ord(t) > t_start + t_initializationPeriod in the code.
    mSettings('schedule', 't_initializationPeriod') = 0;  // r_state and r_online are stored also for the last step in the initialization period, i.e. ord(t) = t_start + t_initializationPeriod

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('schedule', 'loadPoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('schedule', 'savePoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

); // END if(mType)