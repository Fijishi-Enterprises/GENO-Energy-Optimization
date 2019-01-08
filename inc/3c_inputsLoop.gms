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
put log ord(tSolve):0:0 /;
putclose log;

if (ord(tSolve) >= tForecastNext(mSolve),

    // Find time steps until the forecast horizon
    option clear = tt;
    tt_forecast(t_current(t))
        ${ ord(t) <= tSolveFirst + currentForecastLength }
        = yes;
$ontext
    // Update ts_unit
    if (mTimeseries_loop_read(mSolve, 'ts_unit'),
        put_utility 'gdxin' / '%input_dir%/ts_unit/' tSolve.tl:0 '.gdx';
        execute_load ts_unit_update=ts_unit;
        ts_unit(unit, *, f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_unit_update(unit, *, f, t);
    ); // END if('ts_unit')

    // Update ts_effUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effUnit_update=ts_effUnit;
        ts_effUnit(effGroupSelectorUnit(effSelector, unit, effSelector), *, f_solve(f), tt_forecast(t)))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_effUnit_update(effSelector, unit, effSelector, *, ft(f, t));
    ); // END if('ts_effUnit')

    // Update ts_effGroupUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effGroupUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effGroupUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effGroupUnit_update=ts_effGroupUnit;
        ts_effGroupUnit(effSelector, unit, *, f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_effGroupUnit_update(effSelector, unit, *, f, t);
    ); // END if('ts_effGroupUnit')
$offtext

    // Update ts_influx
    if (mTimeseries_loop_read(mSolve, 'ts_influx'),
        put_utility 'gdxin' / '%input_dir%/ts_influx/' tSolve.tl:0 '.gdx';
        execute_load ts_influx_update=ts_influx;
        ts_influx(gn(grid, node), f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_influx_update(grid, node, f, t);
    ); // END if('ts_influx')

    // Update ts_cf
    if (mTimeseries_loop_read(mSolve, 'ts_cf'),
        put_utility 'gdxin' / '%input_dir%/ts_cf/' tSolve.tl:0 '.gdx';
        execute_load ts_cf_update=ts_cf;
        ts_cf(flowNode(flow, node), f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_cf_update(flow, node, f, t);
    ); // END if('ts_cf')

    // Update ts_reserveDemand
    if (mTimeseries_loop_read(mSolve, 'ts_reserveDemand'),
        put_utility 'gdxin' / '%input_dir%/ts_reserveDemand/' tSolve.tl:0 '.gdx';
        execute_load ts_reserveDemand_update=ts_reserveDemand;
        ts_reserveDemand(restypeDirectionNode(restype, up_down, node), f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_reserveDemand_update(restype, up_down, node, f, t);
    ); // END if('ts_reserveDemand')

    // Update ts_node
    if (mTimeseries_loop_read(mSolve, 'ts_node'),
        put_utility 'gdxin' / '%input_dir%/ts_node/' tSolve.tl:0 '.gdx';
        execute_load ts_node_update=ts_node;
        ts_node(gn(grid, node), param_gnBoundaryTypes, f_solve(f), tt_forecast(t))
            ${ not mf_realization(mSolve, f) } // Realization not updated
            = ts_node_update(grid, node, param_gnBoundaryTypes, f, t);
    ); // END if('ts_node')

* --- NO FORECAST DIMENSION, SHOULD THESE BE HANDLED SEPARATELY? --------------
// Currently, only updated until the forecast horizon, but is this correct?

    // Update ts_fuelPriceChange
    if (mTimeseries_loop_read(mSolve, 'ts_fuelPriceChange'),
        put_utility 'gdxin' / '%input_dir%/ts_fuelPriceChange/' tSolve.tl:0 '.gdx';
        execute_load ts_fuelPriceChange_update=ts_fuelPriceChange;
        ts_fuelPriceChange(fuel, tt_forecast(t))
            = ts_fuelPriceChange_update(fuel, t);
    ); // END if('ts_fuelPriceChange')

    // Update ts_unavailability
    if (mTimeseries_loop_read(mSolve, 'ts_unavailability'),
        put_utility 'gdxin' / '%input_dir%/ts_unavailability/' tSolve.tl:0 '.gdx';
        execute_load ts_unavailability_update=ts_unavailability;
        ts_unavailability(unit, tt_forecast(t))
            = ts_unavailability_update(unit, t);
    ); // END if('ts_unavailability')

    // Update the next forecast
    tForecastNext(mSolve)
        = tForecastNext(mSolve) + mSettings(mSolve, 't_forecastJump');
);

* =============================================================================
* --- Optional forecast improvement code here ---------------------------------
* =============================================================================

// Forecasts not improved

* =============================================================================
* --- Aggregate time series data for the time intervals -----------------------
* =============================================================================

// Loop over the defined blocks of intervals
loop(cc(counter),

    // Retrieve interval block time steps
    option clear = tt_interval;
    tt_interval(t) = tt_block(counter, t);

    // If stepsPerInterval equals one, simply use all the steps within the block
    if(mInterval(mSolve, 'stepsPerInterval', counter) = 1,

        // Select time series data matching the intervals, for stepsPerInterval = 1, this is trivial.
        loop(ft(f_solve, tt_interval(t)),
            ts_cf_(flowNode(flow, node), f_solve, t, s)$msf(mSolve, s, f_solve)
                = ts_cf(flow, node, f_solve, t + (dt_sampleOffset(flow, node, 'ts_cf', s) + dt_circular(t)));
            ts_influx_(gn(grid, node), f_solve, t, s)$msf(mSolve, s, f_solve)
                = ts_influx(grid, node, f_solve, t + (dt_sampleOffset(grid, node, 'ts_influx', s) + dt_circular(t)));
            ts_unit_(unit, param_unit, f_solve, t)
              ${p_unit(unit, 'useTimeseries')} // Only include units that have timeseries attributed to them
                = ts_unit(unit, param_unit, f_solve, t+dt_circular(t));
            // Reserve demand relevant only up until reserve_length
            ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), f_solve, t)
              ${ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')}
                = ts_reserveDemand(restype, up_down, node, f_solve, t+dt_circular(t));
            ts_node_(gn_state(grid, node), param_gnBoundaryTypes, f_solve, t, s)
              ${p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
                and msf(mSolve, s, f_solve)}
                = ts_node(grid, node, param_gnBoundaryTypes, f_solve, t + (dt_sampleOffset(grid, node, param_gnBoundaryTypes, s) + dt_circular(t)));
            // Fuel price time series
            ts_fuelPrice_(fuel, t)
                = ts_fuelPrice(fuel, t+dt_circular(t));
        ); // END loop(ft)

    // If stepsPerInterval exceeds 1 (stepsPerInterval < 1 not defined)
    elseif mInterval(mSolve, 'stepsPerInterval', counter) > 1,

        // Select and average time series data matching the intervals, for stepsPerInterval > 1
        // Loop over the t:s of the interval
        loop(ft(f_solve, tt_interval(t)),
            // Select t:s within the interval
            Option clear = tt;
            tt(t_)
                ${tt_interval(t_)
                  and ord(t_) >= ord(t)
                  and ord(t_) < ord(t) + mInterval(mSolve, 'stepsPerInterval', counter)
                 }
                = yes;
            ts_influx_(gn(grid, node), f_solve, t, s)$msf(mSolve, s, f_solve)
                = sum(tt(t_), ts_influx(grid, node, f_solve, t_ + (dt_sampleOffset(grid, node, 'ts_influx', s) + dt_circular(t_))))
                    / mInterval(mSolve, 'stepsPerInterval', counter);
            ts_cf_(flowNode(flow, node), f_solve, t, s)$msf(mSolve, s, f_solve)
                = sum(tt(t_), ts_cf(flow, node, f_solve, t_ + (dt_sampleOffset(flow, node, 'ts_cf', s) + dt_circular(t_))))
                    / mInterval(mSolve, 'stepsPerInterval', counter);
            ts_unit_(unit, param_unit, f_solve, t)
              ${ p_unit(unit, 'useTimeseries')} // Only include units with timeseries attributed to them
                = sum(tt(t_), ts_unit(unit, param_unit, f_solve, t_+dt_circular(t_)))
                    / mInterval(mSolve, 'stepsPerInterval', counter);
            // Reserves relevant only until reserve_length
            ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), f_solve, t)
              ${ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')  }
                = sum(tt(t_), ts_reserveDemand(restype, up_down, node, f_solve, t_+dt_circular(t_)))
                    / mInterval(mSolve, 'stepsPerInterval', counter);
            ts_node_(gn_state(grid, node), param_gnBoundaryTypes, f_solve, t, s)
              ${p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
                and msf(mSolve, s, f_solve)}
                   // Take average if not a limit type
                = (sum(tt(t_), ts_node(grid, node, param_gnBoundaryTypes, f_solve, t_ + (dt_sampleOffset(grid, node, param_gnBoundaryTypes, s) + dt_circular(t_))))
                    / mInterval(mSolve, 'stepsPerInterval', counter))$(not sameas(param_gnBoundaryTypes, 'upwardLimit') or sameas(param_gnBoundaryTypes, 'downwardLimit'))
                  // Maximum lower limit
                  + smax(tt(t_), ts_node(grid, node, param_gnBoundaryTypes, f_solve, t_ + (dt_sampleOffset(grid, node, param_gnBoundaryTypes, s) + dt_circular(t_))))
                      $sameas(param_gnBoundaryTypes, 'downwardLimit')
                  // Minimum upper limit
                  + smin(tt(t_), ts_node(grid, node, param_gnBoundaryTypes, f_solve, t_ + (dt_sampleOffset(grid, node, param_gnBoundaryTypes, s) + dt_circular(t_))))
                       $sameas(param_gnBoundaryTypes, 'upwardLimit');
            // Fuel price time series
            ts_fuelPrice_(fuel, t)
                = sum(tt(t_), ts_fuelPrice(fuel, t_+dt_circular(t_)))
                    / mInterval(mSolve, 'stepsPerInterval', counter);
            ); // END loop(ft)

    ); // END if(stepsPerInterval)
); // END loop(counter)

* =============================================================================
* --- Old code, potentially still helpful? ------------------------------------
* =============================================================================

$ontext
    // Define t_latestForecast
    Option clear = t_latestForecast;
    t_latestForecast(tSolve) = yes;

    // Define updated time window
    Option clear = tt_forecast;
    tt_forecast(t_full(t))${    ord(t) >= ord(tSolve)
                                and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_forecastLengthUnchanging') + mSettings(mSolve, 't_forecastJump')
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

    put_utility 'gdxin' / '%input_dir%/tertiary/' tSolve.tl:0 '.gdx';
    execute_load ts_tertiary;
    ts_reserveDemand(restypeDirectionNode('tertiary', up_down, node), f_solve(f), tt_forecast(t))${ mf(mSolve, f)
                                                                                                    and not mf_realization(mSolve, f)
                                                                                                    and flowNode('wind', node)
                                                                                                    }
        = ts_tertiary('wind', node, t+ddt(t), up_down, t)
            * sum(flowUnit('wind', unit), p_gnu('elec', node, unit, 'maxGen'));

$offtext


* --- Improve forecasts -------------------------------------------------------
$ontext
// !!! TEMPORARY MEASURES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

if(mSettings(mSolve, 'forecasts') > 0,

    // Define updated time window
    Option clear = tt_forecast;
    tt_forecast(t_full(t))${    ord(t) >= ord(tSolve)
                                and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_forecastLengthUnchanging') + mSettings(mSolve, 't_forecastJump')
                                }
        = yes;

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
$offtext
