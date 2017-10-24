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

if (mType('invest'),
    m('invest') = yes; // Definition, that the model exists by its name

    // Define the temporal structure of the model in time indeces
    mSettings('invest', 'intervalInHours') = 1; // Define the duration of a single time-step in hours
    mInterval('invest', 'intervalLength', 'c000') = 1;
    mInterval('invest', 'intervalEnd', 'c000') = 504;

    // Define the model execution parameters in time indeces
    mSettings('invest', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('invest', 't_horizon') = 8760;
    mSettings('invest', 't_jump') = 2184;
    mSettings('invest', 't_forecastStart') = 1; // Ord of first forecast available
    mSettings('invest', 't_forecastLength') = 2184;
    mSettings('invest', 't_forecastJump') = 2184;
    mSettings('invest', 't_end') = 2180;
    mSettings('invest', 't_reserveLength') = 36;

    // Define unit aggregation and efficiency levels starting indeces
    mSettings('invest', 't_aggregate') = 4392;
    mSettingsEff('invest', 'level1') = 1;
    mSettingsEff('invest', 'level2') = 1;
    mSettingsEff('invest', 'level3') = 1;
    mSettingsEff('invest', 'level4') = 4392;

    // Define active model features
    active('storageValue') = yes;

    // Define model stochastic parameters
    mSettings('invest', 'samples') = 1;
    mSettings('invest', 'forecasts') = 0;
    mSettings('invest', 'readForecastsInTheLoop') = 0;
    mf('invest', f)$[ord(f)-1 <= mSettings('invest', 'forecasts')] = yes;
    fRealization(f) = no;
    fRealization('f00') = yes;
    fCentral(f) = no;
    fCentral('f00') = yes;
    sInitial(s) = no;
    sInitial('s000') = yes;
    sCentral(s) = no;
    sCentral('s000') = yes;

    p_stepLength('invest', f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later
    p_sProbability(s) = 0;
    p_sProbability('s000') = 1;
    p_fProbability(f) = 0;
    p_fProbability(fRealization) = 1;

    msStart('invest', 's000') = 1;
    msEnd('invest', 's000') = msStart('invest', 's000') + 48;
);