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
    mSettings('schedule', 't_end') = 8760; // Last time step to be included in the solve (may solve and output more time steps in case t_jump does not match)

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('schedule', 't_horizon') = 8760;    // How many active time steps the solve contains (aggregation of time steps does not impact this, unless the aggregation does not match)
    mSettings('schedule', 't_jump') = 3;          // How many time steps the model rolls forward between each solve

    // Define length of data for proper circulation
    mSettings('schedule', 'dataLength') = 8760;

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    // Number of samples used by the model
    mSettings('schedule', 'samples') = 1;

    // Define Initial and Central samples
    ms_initial('schedule', s) = no;
    ms_initial('schedule', 's000') = yes;
    ms_central('schedule', s) = no;

    // Define time span of samples
    msStart('schedule', 's000') = 1;
    msEnd('schedule', 's000') = msStart('schedule', 's000') + mSettings('schedule', 't_end') + mSettings('schedule', 't_horizon');

    // Define the probability (weight) of samples
    p_msProbability('schedule', s) = 0;
    p_msProbability('schedule', 's000') = 1;
    p_msWeight('schedule', s) = 0;
    p_msWeight('schedule', 's000') = 1;
    p_msAnnuityWeight('schedule', s) = 0;
    p_msAnnuityWeight('schedule', 's000') = 1;


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

* --- z-structure for superpositioned nodes ----------------------------------

    // add the candidate periods to model
    // no need to touch this part
    // The set is mainly used in the 'invest' model
    mz('schedule', z) = no;

    // Mapping between typical periods (=samples) and the candidate periods (z).
    // Assumption is that candidate periods start from z000 and form a continuous
    // sequence.
    // The set is mainly used in the 'invest' model
    zs(z,s) = no;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('schedule', 'forecasts') = 3;

    // Define which nodes and timeseries use forecasts
    Option clear = gn_forecasts;  // By default includes everything, so clear first
    //gn_forecasts('wind', 'XXX', 'ts_cf') = yes;  // declare a time serie that has forecasts. Syntax: (*, node, timeseries) where * = grid, flow, or restype
    //gn_forecasts('hydro', 'XXX', 'ts_influx') = yes;  // declare a time serie that has forecasts. Syntax: (*, node, timeseries) where * = grid, flow, or restype

    // Define which units and timeseries use forecasts
    Option clear = unit_forecasts;  // By default includes everything, so clear first
    //unit_forecasts('XXX', 'ts_unit') = yes;  // declare a time serie that has forecasts. Syntax: (unit, timeseries)

    // Define forecast properties and features
    mSettings('schedule', 't_forecastStart') = 1;                  // At which time step the first forecast is available ( 1 = t000001 )
    mSettings('schedule', 't_forecastLengthUnchanging') = 36;      // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('schedule', 't_forecastLengthDecreasesFrom') = 168;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('schedule', 't_perfectForesight') = 0;               // How many time steps after there is perfect foresight (including t_jump)
    mSettings('schedule', 't_forecastJump') = 24;                  // How many time steps before new forecast is available
    mSettings('schedule', 't_improveForecast') = 0;                // Number of time steps ahead of time that the forecast is improved on each solve.

    // Define how forecast data is read
    mSettings(mSolve, 'onlyExistingForecasts') = no; // yes = Read only existing data; zeroes need to be EPS to be recognized as data.

    // Define what forecast data is read during the loop phase
    mTimeseries_loop_read('schedule', 'ts_reserveDemand') = no;
    mTimeseries_loop_read('schedule', 'ts_unit') = no;
    mTimeseries_loop_read('schedule', 'ts_influx') = no;
    mTimeseries_loop_read('schedule', 'ts_cf') = no;
    mTimeseries_loop_read('schedule', 'ts_reserveDemand') = no;
    mTimeseries_loop_read('schedule', 'ts_node') = no;

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


* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

    // Define active model features
    active('schedule', 'storageValue') = yes;


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
    mSettingsEff('schedule', 'level1') = 12;
    mSettingsEff('schedule', 'level2') = 36;

    // Define the horizon when start-up and shutdown trajectories are considered
    mSettings('schedule', 't_trajectoryHorizon') = 8760;

* --- Define output settings for results --------------------------------------

    // Define the length of the initialization period. Results outputting starts after the period. Uses ord(t) > t_start + t_initializationPeriod in the code.
    mSettings('schedule', 't_initializationPeriod') = 0;  // r_state_gnft and r_online_uft are stored also for the last step in the initialization period, i.e. ord(t) = t_start + t_initializationPeriod

* --- Define the use of additional constraints for units with incremental heat rates

    // How to use q_conversionIncHR_help1 and q_conversionIncHR_help2
    mSettings('schedule', 'incHRAdditionalConstraints') = 0;
    // 0 = use the constraints but only for units with non-convex fuel use
    // 1 = use the constraints for all units represented using incremental heat rates

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('schedule', 'loadPoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('schedule', 'savePoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

); // END if(mType)
