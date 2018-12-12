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

if (mType('invest'),
    m('invest') = yes; // Definition, that the model exists by its name

* --- Define Key Execution Parameters in Time Indeces -------------------------

    // Define simulation start and end time indeces
    mSettings('invest', 't_start') = 1;  // First time step to be solved, 1 corresponds to t000001 (t000000 will then be used for initial status of dynamic variables)
    mSettings('invest', 't_end') = 8760; // Last time step to be included in the solve (may solve and output more time steps in case t_jump does not match)

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('invest', 't_horizon') = 8760;   // How many active time steps the solve contains (aggregation of time steps does not impact this, unless the aggregation does not match)
    mSettings('invest', 't_jump') = 8760;      // How many time steps the model rolls forward between each solve

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    // Number of samples used by the model
    mSettings('invest', 'samples') = 3;

    // Define Initial and Central samples
    ms_initial('invest', s) = no;
    ms_initial('invest', 's000') = yes;
    ms_central('invest', s) = no;
    ms_central('invest', 's000') = yes;

    // Define time span of samples
    msStart('invest', 's000') = 1;
    msEnd('invest', 's000') = msStart('invest', 's000') + 168;
    msStart('invest', 's001') = 1 + 18*168;
    msEnd('invest', 's001') = msStart('invest', 's001') + 168;
    msStart('invest', 's002') = 1 + 35*168;
    msEnd('invest', 's002') = msStart('invest', 's002') + 168;

    // Define the probability (weight) of samples
    p_msProbability('invest', s) = 0;
    p_msProbability('invest', 's000') = 8760/504;
    p_msProbability('invest', 's001') = 8760/504;
    p_msProbability('invest', 's002') = 8760/504;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('invest', 'stepLengthInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('invest', 'stepsPerInterval', 'c000') = 1;
    mInterval('invest', 'lastStepInIntervalBlock', 'c000') = 8760;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('invest', 'forecasts') = 0;

    // Define forecast properties and features
    mSettings('invest', 't_forecastStart') = 0;                // At which time step the first forecast is available ( 1 = t000001 )
    mSettings('invest', 't_forecastLengthUnchanging') = 0;     // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('invest', 't_forecastLengthDecreasesFrom') = 0;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('invest', 't_forecastJump') = 0;                 // How many time steps before new forecast is available

    // Define Realized and Central forecasts
    mf_realization('invest', f) = no;
    mf_realization('invest', 'f00') = yes;
    mf_central('invest', f) = no;
    mf_central('invest', 'f00') = yes;

    // Define forecast probabilities (weights)
    p_mfProbability('invest', f) = 0;
    p_mfProbability(mf_realization('invest', f)) = 1;

    // Define active model features
    active('invest', 'storageValue') = yes;

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* --- Define Reserve Properties -----------------------------------------------

    // Lenght of reserve horizon
    mSettingsReservesInUse('invest', 'primary', 'up') = no;
    mSettingsReservesInUse('invest', 'primary', 'down') = no;
    mSettingsReservesInUse('invest', 'secondary', 'up') = no;
    mSettingsReservesInUse('invest', 'secondary', 'down') = no;
    mSettingsReservesInUse('invest', 'tertiary', 'up') = no;
    mSettingsReservesInUse('invest', 'tertiary', 'down') = no;

* --- Define Unit Approximations ----------------------------------------------

    // Define the last time step for each unit aggregation and efficiency level (3a_periodicInit.gms ensures that there is a effLevel until t_horizon)
    mSettingsEff('invest', 'level1') = inf;

    // Define the horizon when start-up and shutdown trajectories are considered
    mSettings('invest', 't_trajectoryHorizon') = 8760;

* --- Define output settings for results --------------------------------------

    // Define the length of the initialization period. Results outputting starts after the period. Uses ord(t) > t_start + t_initializationPeriod in the code.
    mSettings('invest', 't_initializationPeriod') = 0;  // r_state and r_online are stored also for the last step in the initialization period, i.e. ord(t) = t_start + t_initializationPeriod

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('invest', 'loadPoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('invest', 'savePoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

); // END if(mType)


