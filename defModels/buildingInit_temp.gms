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
* --- Model Definition - Building ---------------------------------------------
* =============================================================================

if (mType('building'),
    m('building') = yes; // Definition, that the model exists by its name

* --- Define Key Execution Parameters in Time Indeces -------------------------

    // Define simulation start and end time indeces
    mSettings('building', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('building', 't_end') = 8760;

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('building', 't_horizon') = 336;
    mSettings('building', 't_jump') = 168;

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    // Number of samples used by the model
    mSettings('building', 'samples') = 1;

    // Define Initial and Central samples
    ms_initial('building', s) = no;
    ms_initial('building', 's000') = yes;
    ms_central('building', s) = no;
    ms_central('building', 's000') = yes;

    // Define time span of samples
    msStart('building', 's000') = mSettings('building', 't_start');
    msEnd('building', 's000') = msStart('building', 's000') + mSettings('building', 't_horizon');

    // Define the probability (weight) of samples
    p_msProbability('building', s) = 0;
    p_msProbability('building', 's000') = 1;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('building', 'intervalInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('building', 'intervalLength', 'c000') = 1;
    mInterval('building', 'intervalEnd', 'c000') = 336;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('building', 'forecasts') = 0;

    // Define forecast properties and features
    mSettings('building', 't_forecastStart') = 0;
    mSettings('building', 't_forecastLengthUnchanging') = 0;  // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('building', 't_forecastLengthDecreasesFrom') = 0;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('building', 't_forecastJump') = 0;

    // Define Realized and Central forecasts
*    mf_realization('building', f) = no;
    mf_realization('building', 'f00') = yes;
*    mf_central('building', f) = no;
    mf_central('building', 'f00') = yes;

    // Define forecast probabilities (weights)
*    p_mfProbability('building', f) = 0;
    p_mfProbability(mf_realization('building', f)) = 1;

    // Define active model features
*    active('building', 'storageValue') = yes;

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* --- Define Reserve Properties -----------------------------------------------

    // Lenght of reserve horizon
    mSettings('building', 't_reserveLength') = 0;

* --- Define Unit Approximations ----------------------------------------------

    // Define unit aggregation threshold
    mSettings('building', 't_aggregate') = 0;

    // Define unit aggregation and efficiency levels starting indeces
    mSettingsEff('building', 'level1') = 1;

    // Define threshold for omitting start-up and shutdown trajectories
    mSettings('building', 't_omitTrajectories') = 8761;

* --- Define output settings for results --------------------------------------

    // Define when to start outputting results - allows to skip an initialization period. Uses ord(t) > results_t_start in the code.
    mSettings('building', 'results_t_start') = 1;

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('building', 'loadPoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('building', 'savePoint') = 2;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

); // END if(mType)
