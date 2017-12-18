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
* --- Update the Forecast Data ------------------------------------------------
* =============================================================================

put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
    put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
    execute_load ts_forecast = forecast;

    // Update the next forecast
    tForecastNext(mSolve)${ ord(tSolve) >= tForecastNext(mSolve) }
        = tForecastNext(mSolve) + mSettings(mSolve, 't_forecastJump');

    // Define t_latestForecast
    Option clear = t_latestForecast;
    t_latestForecast(tSolve) = yes;

    // Define updated time window
    Option clear = tt_forecast;
    tt_forecast(t_full(t))${    ord(t) >= ord(tSolve)
                                and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_forecastLength') + mSettings(mSolve, 't_forecastJump')
                                }
        = yes;

    // Define temporary time displacement to reach t_latestForecast
    Option clear = ddt;
    ddt(tt_forecast(t)) = ord(tSolve) - ord(t);

* --- Update Forecast Data ----------------------------------------------------

    ts_cf(flowNode(flow, node), f_solve(f), tt_forecast(t))${   ts_forecast(flow, node, t+ddt(t), f, t) // Only update data for capacity factors with forecast. NOTE! This results in problems if the forecast has values of zero!
                                                                and mf(mSolve, f)
                                                                }
        = ts_forecast(flow, node, t+ddt(t), f, t);

* --- Read the Tertiary Reserve Requirements ----------------------------------

    put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
    execute_load ts_tertiary;
    ts_reserveDemand(restypeDirectionNode('tertiary', up_down, node), f_solve(f), tt_forecast(t))${ mf(mSolve, f)
                                                                                                    and not mf_realization(mSolve, f)
                                                                                                    and flowNode('wind', node)
                                                                                                    }
        = ts_tertiary('wind', node, t+ddt(t), up_down, t)
            * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen'));

); // END IF readForecastsInTheLoop

putclose log;

* --- Improve forecasts -------------------------------------------------------
*$ontext
// !!! TEMPORARY MEASURES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

if(mSettings(mSolve, 'forecasts') > 0,

    // Define updated time window
    Option clear = tt;
    tt(tt_forecast(t))${    ord(t) > ord(tSolve)
                            and ord(t) <= ord(tSolve) + f_improve
                            }
        = yes;

    // Temporary forecast displacement to reach the central forecast
    Option clear = ddf;
    ddf(f_solve(f), tt(t))${ not mf_central(mSolve, f) }
        = sum(mf_central(mSolve, f_), ord(f_) - ord(f));

    // Temporary forecast displacement to reach the realized forecast
    Option clear = ddf_;
    ddf_(f_solve(f), tt(t))${ not mf_realization(mSolve, f) }
        = sum(mf_realization(mSolve, f_), ord(f_) - ord(f));

    // Calculate the upper and lower forecasts based on the original central forecast
    ts_cf(flowNode(flow, node), f_solve(f), tt(t))${    not mf_realization(mSolve, f)
                                                        and not mf_central(mSolve, f)
                                                        }
                = ts_cf(flow, node, f, t) - ts_cf(flow, node, f+ddf(f,t), t);

    // Improve forecasts during the dispatch
    // Improve central capacity factors, linear improvement towards fRealization
    ts_cf(flowNode(flow, node), f_solve(f), tt(t))${    not mf_realization(mSolve, f)
                                                        and mf_central(mSolve, f)
                                                        }
        = (
            (ord(t) - ord(tSolve)) * ts_cf(flow, node, f, t)
            + (f_improve + ord(tSolve) - ord(t)) * ts_cf(flow, node, f+ddf_(f,t), t)
            )
                / f_improve;

    // Update the upper and lower forecasts based on the improved central forecast
    ts_cf(flowNode(flow, node), f_solve(f), tt(t))${    not mf_realization(mSolve, f)
                                                        and not mf_central(mSolve, f)
                                                        }
        = min(max( ts_cf(flow, node, f, t) + ts_cf(flow, node, f+ddf(f,t), t), 0),1);

); // END IF forecasts
*$offtext
