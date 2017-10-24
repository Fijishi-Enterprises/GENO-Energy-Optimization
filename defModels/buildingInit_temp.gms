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
    msInitial('building', s) = no;
    msInitial('building', 's000') = yes;
    msCentral('building', s) = no;
    msCentral('building', 's000') = yes;

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
    mSettings('building', 't_forecastLength') = 0;
    mSettings('building', 't_forecastJump') = 0;
    mSettings('building', 'readForecastsInTheLoop') = 0;

    // Define Realized and Central forecasts
*    mfRealization('building', f) = no;
    mfRealization('building', 'f00') = yes;
*    mfCentral('building', f) = no;
    mfCentral('building', 'f00') = yes;

    // Define forecast probabilities (weights)
*    p_mfProbability('building', f) = 0;
    p_mfProbability(mfRealization('building', f)) = 1;

    // Define active model features
*    active('building', 'storageValue') = yes;

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* --- Define Reserve Properties -----------------------------------------------

    // Lenght of reserve horizon
    mSettings('building', 't_reserveLength') = 0;

* --- Define Unit Efficiency Approximations -----------------------------------

    // Define unit aggregation threshold
    mSettings('building', 't_aggregate') = 0;

    // Define unit aggregation and efficiency levels starting indeces
    mSettingsEff('building', 'level1') = 1;

); // END if(mType)