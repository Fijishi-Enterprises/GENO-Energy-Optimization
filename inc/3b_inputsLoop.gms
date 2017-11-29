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

* --- Update Forecast Data ----------------------------------------------------

    loop(t_latestForecast,  // There should be only one latest forecast
        ts_cf(flowNode(flow, node), f_solve(f), tt_forecast(t))${   ts_forecast(flow, node, t_latestForecast, f, t) // Only update data for capacity factors with forecast. NOTE! This results in problems if the forecast has values of zero!
                                                                    and mf(mSolve, f)
                                                                    }
            = ts_forecast(flow, node, t_latestForecast, f, t);

        // !!! REALVALUE SPECIFIC !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
$ontext
        // Force the upper and lower forecasts to include the realization
        ts_cf(flow, node, 'f01', tt(t))${   mf(mSolve, 'f01')
                                            and not fRealization('f01')
                                            and not fCentral('f01')
            } = min(ts_cf(flow, node, 'f01', t), sum(fRealization(f_), ts_cf(flow, node, f_, t)));
        ts_cf(flow, node, 'f03', tt(t))${   mf(mSolve, 'f03')
                                            and not fRealization('f03')
                                            and not fCentral('f03')
            } = max(ts_cf(flow, node, 'f03', t), sum(fRealization(f_), ts_cf(flow, node, f_, t)));
$offtext

        // Ambient temperatures, need to be weighted with the GFA densities of the different regions that are aggregated into the nodes
        ts_nodeState('heat', '74FI_ambient', 'reference', f_solve(f), tt_forecast(t))${  gn_state('heat', '74FI_ambient')
                                                                                        and mf_central(mSolve, f)
                                                                                        and not mf_realization(mSolve, f)
                                                                                        }
            = + 0.1075 * ts_forecast('temperature', 'FI_1', t_latestForecast, f, t)
                + 0.8925 * ts_forecast('temperature', 'FI_2', t_latestForecast, f, t)
        ;
        ts_nodeState('heat', '75FI_ambient', 'reference', f_solve(f), tt_forecast(t))${  gn_state('heat', '75FI_ambient')
                                                                                        and mf_central(mSolve, f)
                                                                                        and not mf_realization(mSolve, f)
                                                                                        }
            = + 0.3332 * ts_forecast('temperature', 'FI_3', t_latestForecast, f, t)
                + 0.1644 * ts_forecast('temperature', 'FI_4', t_latestForecast, f, t)
                + 0.0848 * ts_forecast('temperature', 'FI_5', t_latestForecast, f, t)
                + 0.1086 * ts_forecast('temperature', 'FI_6', t_latestForecast, f, t)
                + 0.3090 * ts_forecast('temperature', 'FI_7', t_latestForecast, f, t)
        ;
*$ontext
        // Minimum forecasts
        ts_nodeState('heat', '74FI_ambient', 'reference', 'f01', tt_forecast(t))${  gn_state('heat', '74FI_ambient')
                                                                                    and not mf_realization(mSolve, 'f01')
                                                                                    and not mf_central(mSolve, 'f01')
                                                                                    }
            = min(
                ts_forecast('temperature', 'FI_1', t_latestForecast, 'f01', t),
                ts_forecast('temperature', 'FI_2', t_latestForecast, 'f01', t)
                )
        ;
        ts_nodeState('heat', '75FI_ambient', 'reference', 'f01', tt_forecast(t))${  gn_state('heat', '75FI_ambient')
                                                                                    and not mf_realization(mSolve, 'f01')
                                                                                    and not mf_central(mSolve, 'f01')
                                                                                    }
            = min(
                ts_forecast('temperature', 'FI_3', t_latestForecast, 'f01', t),
                ts_forecast('temperature', 'FI_4', t_latestForecast, 'f01', t),
                ts_forecast('temperature', 'FI_5', t_latestForecast, 'f01', t),
                ts_forecast('temperature', 'FI_6', t_latestForecast, 'f01', t),
                ts_forecast('temperature', 'FI_7', t_latestForecast, 'f01', t)
                )
        ;
        // Maximum forecasts
        ts_nodeState('heat', '74FI_ambient', 'reference', 'f03', tt_forecast(t))${  gn_state('heat', '74FI_ambient')
                                                                                    and not mf_realization(mSolve, 'f03')
                                                                                    and not mf_central(mSolve, 'f03')
                                                                                    }
            = max(
                ts_forecast('temperature', 'FI_1', t_latestForecast, 'f03', t),
                ts_forecast('temperature', 'FI_2', t_latestForecast, 'f03', t)
                )
        ;
        ts_nodeState('heat', '75FI_ambient', 'reference', 'f03', tt_forecast(t))${  gn_state('heat', '75FI_ambient')
                                                                                    and not mf_realization(mSolve, 'f03')
                                                                                    and not mf_central(mSolve, 'f03')
                                                                                    }
            = max(
                ts_forecast('temperature', 'FI_3', t_latestForecast, 'f03', t),
                ts_forecast('temperature', 'FI_4', t_latestForecast, 'f03', t),
                ts_forecast('temperature', 'FI_5', t_latestForecast, 'f03', t),
                ts_forecast('temperature', 'FI_6', t_latestForecast, 'f03', t),
                ts_forecast('temperature', 'FI_7', t_latestForecast, 'f03', t)
                )
        ;
*$offtext
$ontext
        // Correction to the level of the central temperature forecast, starting from the current temperature
        ts_nodeState(gn_state(grid, node), 'reference', f, tt(t))${ mf(mSolve, f)
                                                                    and sum(param_gnBoundaryTypes, p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries'))
                                                                    and not fRealization(f)
            } = + ts_nodeState(grid, node, 'reference', f, t)
                - sum(fCentral(f_), ts_nodeState(grid, node, 'reference', f_, t_latestForecast))
                + sum(fRealization(f_), ts_nodeState(grid, node, 'reference', f_, t_latestForecast))
        ;

        // Force the minimum and maximum forecasts to include the realization
        ts_nodeState(gn_state(grid, node), 'reference', 'f01', tt(t))${ mf(mSolve, 'f01')
                                                                        and not fRealization('f01')
                                                                        and not fCentral('f01')
                                                                        and ts_nodeState(grid, node, 'reference', 'f01', t)
            } = min(ts_nodeState(grid, node, 'reference', 'f01', t), sum(fRealization(f_), ts_nodeState(grid, node, 'reference', f_, t)))
        ;
        ts_nodeState(gn_state(grid, node), 'reference', 'f03', tt(t))${ mf(mSolve, 'f03')
                                                                        and not fRealization('f03')
                                                                        and not fCentral('f03')
                                                                        and ts_nodeState(grid, node, 'reference', 'f03', t)
            } = max(ts_nodeState(grid, node, 'reference', 'f03', t), sum(fRealization(f_), ts_nodeState(grid, node, 'reference', f_, t)))
        ;
$offtext
    ); // END loop(t_latestForecast)

* --- Read the Tertiary Reserve Requirements ----------------------------------

    put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
    execute_load ts_tertiary;
    ts_reserveDemand(restypeDirectionNode('tertiary', up_down, node), f_solve(f), tt_forecast(t))${ mf(mSolve, f)
                                                                                                    and not mf_realization(mSolve, f)
                                                                                                    and flowNode('wind', node)
                                                                                                    }
        = ts_tertiary('wind', node, tSolve, up_down, t) * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen'));

    // Initialize ts_tertiary to conserve memory
    Option clear = ts_tertiary;

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

    // Improve forecasts during the dispatch
    loop(mf_realization(mSolve, f_),
        // Improve central capacity factors, linear improvement towards fRealization
        ts_cf(flowNode(flow, node), f_solve(f), tt(t))${ not mf_realization(mSolve, f)
                                                        and mf_central(mSolve, f)
                                                        }
            = (
                (ord(t) - ord(tSolve)) * ts_cf(flow, node, f, t)
                + (f_improve + ord(tSolve) - ord(t)) * ts_cf(flow, node, f_, t)
                )
                    / f_improve;

        // Upper and lower forecasts include realization?
        ts_cf(flowNode(flow, node), f_solve('f01'), tt(t))
            = min(
                    ts_cf(flow, node, 'f01', t),
                    ts_cf(flow, node, f_, t)
                    );
        ts_cf(flowNode(flow, node), f_solve('f03'), tt(t))
            = max(
                    ts_cf(flow, node, 'f03', t),
                    ts_cf(flow, node, f_, t)
                    );

        // !!! REALVALUE SPECIFIC !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // Also improve ambient temperature forecasts
        ts_nodeState(gn_state(grid, node), 'reference', f_solve(f), tt(t))${ not mf_realization(mSolve, f)
                                                                            and mf_central(mSolve, f)
                                                                            }
            = (
                (ord(t) - ord(tSolve)) * ts_nodeState(grid, node, 'reference', f, t)
                + (f_improve + ord(tSolve) - ord(t)) * ts_nodeState(grid, node, 'reference', f_, t)
                )
                    / f_improve;

        // Upper and lower forecasts include realization?
        ts_nodeState(gn_state(grid, node), 'reference', f_solve('f01'), tt(t))
            = min(
                    ts_nodeState(grid, node, 'reference', 'f01', t),
                    ts_nodeState(grid, node, 'reference', f_, t)
                    );
        ts_nodeState(gn_state(grid, node), 'reference', f_solve('f03'), tt(t))
            = max(
                    ts_nodeState(grid, node, 'reference', 'f03', t),
                    ts_nodeState(grid, node, 'reference', f_, t)
                    );
    ); // END loop(mfRealization)
); // END IF forecasts
*$offtext
