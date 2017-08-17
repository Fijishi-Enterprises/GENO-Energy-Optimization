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
put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
  put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
  execute_load ts_forecast = forecast;
  tLatestForecast(t) = no;
  tLatestForecast(t)$(ord(t) = ord(tSolve)) = yes;

  put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
  execute_load ts_tertiary;
    ts_reserveDemand('tertiary', 'up', node, f, t)${ mf(mSolve, f)
                                                        and not fRealization(f)
        } = min(500, ts_tertiary('wind', node, tSolve, 'up', t) * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen')));
);

putclose log;
