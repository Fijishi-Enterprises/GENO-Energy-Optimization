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
* --- Update Forecast Data ----------------------------------------------------
* =============================================================================

put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
    put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
    execute_load ts_forecast = forecast;

    // Update tForecastNext
    tForecastNext(mSolve)${ ord(tSolve) >= tForecastNext(mSolve) }
        = tForecastNext(mSolve) + mSettings(mSolve, 't_ForecastJump');

    // Define tLatestForecast
    Option clear = tLatestForecast;
    tLatestForecast(tSolve) = yes;

    // Define updated time window
    Option clear = tt;
    tt(tFull(t))${  ord(t) >= ord(tSolve)
                    and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_forecastLength') + mSettings(mSolve, 't_ForecastJump')
                    }
        = yes;

* --- Update Data -------------------------------------------------------------

    // There should be only one latest forecast
    loop(tLatestForecast,
        ts_cf(flowNode(flow, node), fSolve(f), tt(t))${ ts_forecast(flow, node, tLatestForecast, f, t) // Only update data for capacity factors with forecast. NOTE! This results in problems if the forecast has values of zero!
                                                        and mf(mSolve, f)
                                                        }
            = ts_forecast(flow, node, tLatestForecast, f, t);
    ); // END loop(tLatestForecast)

    // Read the tertiary reserve requirements
    put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
    execute_load ts_tertiary;
    ts_reserveDemand(resTypeDirectionNode('tertiary', up_down, node), fSolve(f), tt(t))${   mf(mSolve, f)
                                                                                            and not mfRealization(mSolve, f)
                                                                                            }
*        = min(500, ts_tertiary('wind', node, tSolve, up_down, t) * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen')));
        = max(p_nReserves(node, 'primary', up_down), ts_tertiary('wind', node, tSolve, up_down, t) * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen')));

); // END IF readForecastsInTheLoop

putclose log;

* --- Improve forecasts -------------------------------------------------------

// !!! TEMPORARY MEASURES !!!
if(mSettings(mSolve, 'forecasts') > 0,

    // Define updated time window
    Option clear = tt;
    tt(t)${ ord(t) >= ord(tSolve)
            and ord(t) <= ord(tSolve) + f_improve
            }
        = yes;

    // Improve capacity factors, linear improvement towards fRealization
    loop(mfRealization(mSolve, f_),
        ts_cf(flowNode(flow, node), fSolve(f), tt(t))${ not mfRealization(mSolve, f)
                                                        and mf(mSolve, f)
                                                        }
            = [
                (ord(t) - ord(tSolve)) * ts_cf(flow, node, f, t)
                + (f_improve + ord(tSolve) - ord(t)) * ts_cf(flow, node, f_, t)
                ]
                / f_improve;
    );
); // END IF forecasts
