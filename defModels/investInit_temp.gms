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
    mSettings('invest', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('invest', 't_end') = 8760;

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('invest', 't_horizon') = 8760;
    mSettings('invest', 't_jump') = 8760;

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
    msStart('invest', 's000') = mSettings('invest', 't_start');
    msEnd('invest', 's000') = msStart('invest', 's000') + 168;
    msStart('invest', 's001') = mSettings('invest', 't_start') + 18*168;
    msEnd('invest', 's001') = msStart('invest', 's001') + 168;
    msStart('invest', 's002') = mSettings('invest', 't_start') + 35*168;
    msEnd('invest', 's002') = msStart('invest', 's002') + 168;

    // Define the probability (weight) of samples
    p_msProbability('invest', s) = 0;
    p_msProbability('invest', 's000') = 8760/504;
    p_msProbability('invest', 's001') = 8760/504;
    p_msProbability('invest', 's002') = 8760/504;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('invest', 'intervalInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('invest', 'intervalLength', 'c000') = 1;
    mInterval('invest', 'intervalEnd', 'c000') = 8760;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('invest', 'forecasts') = 0;

    // Define forecast properties and features
    mSettings('invest', 't_forecastStart') = 0;
    mSettings('invest', 't_forecastLengthUnchanging') = 0;  // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('building', 't_forecastLengthDecreasesFrom') = 0;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('invest', 't_forecastJump') = 0;

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
    mSettings('invest', 't_reserveLength') = 36; // CHECK THIS

* --- Define Unit Efficiency Approximations -----------------------------------

    // Define unit aggregation threshold
    mSettings('invest', 't_aggregate') = 8761;

    // Define unit aggregation and efficiency levels starting indeces
    mSettingsEff('invest', 'level1') = 1;

* ---- Define output settings for results

    // Define when to start outputting results - allows to skip an initialization period. Uses ord(t) > results_t_start in the code.
    mSettings('schedule', 'results_t_start') = 1;
); // END if(mType)


