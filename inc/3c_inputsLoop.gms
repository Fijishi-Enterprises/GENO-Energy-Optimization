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

// Determine the necessary horizon for updating data
option clear = tmp;
tmp = max(  mSettings(mSolve, 't_forecastLengthUnchanging') + mSettings(mSolve, 't_forecastJump'),
            mSettings('schedule', 't_forecastLengthDecreasesFrom')
            );

// Find time steps until the forecast horizon
option clear = tt_forecast;
tt_forecast(t_current(t))
    ${ ord(t) <= tSolveFirst + tmp }
    = yes;

if (ord(tSolve) >= tForecastNext(mSolve),
$ontext
* These don't work due to the wild cards in the parameter definitions!
    // Update ts_unit
    if (mTimeseries_loop_read(mSolve, 'ts_unit'),
        put_utility 'gdxin' / '%input_dir%/ts_unit/' tSolve.tl:0 '.gdx';
        execute_load ts_unit_update=ts_unit;
        ts_unit(unit, *, f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                ts_unit_update(unit, *, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_unit_update(unit, *, f, t);
    ); // END if('ts_unit')

    // Update ts_effUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effUnit_update=ts_effUnit;
        ts_effUnit(effGroupSelectorUnit(effSelector, unit, effSelector), *, f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                ts_effUnit_update(effSelector, unit, effSelector, *, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_effUnit_update(effSelector, unit, effSelector, *, f, t);
    ); // END if('ts_effUnit')

    // Update ts_effGroupUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effGroupUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effGroupUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effGroupUnit_update=ts_effGroupUnit;
        ts_effGroupUnit(effSelector, unit, *, f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                ts_effGroupUnit_update(effSelector, unit, *, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_effGroupUnit_update(effSelector, unit, *, f, t);
    ); // END if('ts_effGroupUnit')
$offtext

    // Update ts_influx
    if (mTimeseries_loop_read(mSolve, 'ts_influx'),
        put_utility 'gdxin' / '%input_dir%/ts_influx/' tSolve.tl:0 '.gdx';
        execute_load ts_influx_update=ts_influx;
        ts_influx(gn(grid, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                and ts_influx_update(grid, node, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_influx_update(grid, node, f, t);
    ); // END if('ts_influx')

    // Update ts_cf
    if (mTimeseries_loop_read(mSolve, 'ts_cf'),
        put_utility 'gdxin' / '%input_dir%/ts_cf/' tSolve.tl:0 '.gdx';
        execute_load ts_cf_update=ts_cf;
        ts_cf(flowNode(flow, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                and ts_cf_update(flow, node, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_cf_update(flow, node, f, t);
    ); // END if('ts_cf')

    // Update ts_reserveDemand
    if (mTimeseries_loop_read(mSolve, 'ts_reserveDemand'),
        put_utility 'gdxin' / '%input_dir%/ts_reserveDemand/' tSolve.tl:0 '.gdx';
        execute_load ts_reserveDemand_update=ts_reserveDemand;
        ts_reserveDemand(restypeDirectionNode(restype, up_down, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                and ts_reserveDemand_update(restype, up_down, node, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_reserveDemand_update(restype, up_down, node, f, t);
    ); // END if('ts_reserveDemand')

    // Update ts_node
    if (mTimeseries_loop_read(mSolve, 'ts_node'),
        put_utility 'gdxin' / '%input_dir%/ts_node/' tSolve.tl:0 '.gdx';
        execute_load ts_node_update=ts_node;
        ts_node(gn(grid, node), param_gnBoundaryTypes, f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
*                and ts_node_update(grid, node, param_gnBoundaryTypes, f ,t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_node_update(grid, node, param_gnBoundaryTypes, f, t);
    ); // END if('ts_node')

* --- NO FORECAST DIMENSION, SHOULD THESE BE HANDLED SEPARATELY? --------------
// Currently, only updated until the forecast horizon, but is this correct?

    // Update ts_fuelPriceChange
    if (mTimeseries_loop_read(mSolve, 'ts_fuelPriceChange'),
        put_utility 'gdxin' / '%input_dir%/ts_fuelPriceChange/' tSolve.tl:0 '.gdx';
        execute_load ts_fuelPriceChange_update=ts_fuelPriceChange;
        ts_fuelPriceChange(fuel, tt_forecast(t))
*            ${ ts_fuelPriceChange_update(fuel, t) } // Update only existing values (zeroes need to be EPS)
            = ts_fuelPriceChange_update(fuel, t);
    ); // END if('ts_fuelPriceChange')

    // Update ts_unavailability
    if (mTimeseries_loop_read(mSolve, 'ts_unavailability'),
        put_utility 'gdxin' / '%input_dir%/ts_unavailability/' tSolve.tl:0 '.gdx';
        execute_load ts_unavailability_update=ts_unavailability;
        ts_unavailability(unit, tt_forecast(t))
*            ${ ts_unavailability_update(unit, t) } // Update only existing values (zeroes need to be EPS)
            = ts_unavailability_update(unit, t);
    ); // END if('ts_unavailability')

    // Update the next forecast
    tForecastNext(mSolve)
        = tForecastNext(mSolve) + mSettings(mSolve, 't_forecastJump');
); // END if(tForecastNext)

* =============================================================================
* --- Optional forecast improvement -------------------------------------------
* =============================================================================

if(mSettings(mSolve, 't_improveForecast'),
* Linear improvement of the central forecast towards the realized forecast,
* while preserving the difference between the central forecast and the
* remaining forecasts

    // Determine the set of improved time steps
    option clear = tt;
    tt(tt_forecast(t))
        ${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_improveForecast') }
        = yes;

    // Temporary forecast displacement to reach the central forecast
    option clear = ddf;
    ddf(f_solve(f))
        ${ not mf_central(mSolve, f) }
        = sum(mf_central(mSolve, f_), ord(f_) - ord(f));

    // Temporary forecast displacement to reach the realized forecast
    option clear = ddf_;
    ddf_(f_solve(f))
        ${ not mf_realization(mSolve, f) }
        = sum(mf_realization(mSolve, f_), ord(f_) - ord(f));

* --- Calculate the other forecasts relative to the central one ---------------

    loop(f_solve(f)${ not mf_realization(mSolve, f) and not mf_central(mSolve, f) },
$ontext
* These don't work due to the wild cards in the parameter definitions!
        // ts_unit
        ts_unit(unit, *, f, tt(t))
            = ts_unit(unit, *, f, t) - ts_unit(unit, *, f+ddf(f), t);
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit, effSelector), *, f, tt(t))
            = ts_effUnit(effSelector, unit, effSelector, *, f, t) - ts_effUnit(effSelector, unit, effSelector, *, f+ddf(f), t);
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit, *, f, tt(t))
            = ts_effGroupUnit(effSelector, unit, *, f, t) - ts_effGroupUnit(effSelector, unit, *, f+ddf(f), t);
$offtext
        // ts_influx
        ts_influx(gn(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) - ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = ts_cf(flow, node, f, t) - ts_cf(flow, node, f+ddf(f), t);
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionNode(restype, up_down, node), f, tt(t))
            = ts_reserveDemand(restype, up_down, node, f, t) - ts_reserveDemand(restype, up_down, node, f+ddf(f), t);
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = ts_node(grid, node, param_gnBoundaryTypes, f, t) - ts_node(grid, node, param_gnBoundaryTypes, f+ddf(f), t);
    ); // END loop(f_solve)

* --- Linear improvement of the central forecast ------------------------------

    loop(mf_central(mSolve, f),
$ontext
* These don't work due to the wild cards in the parameter definitions!
        // ts_unit
        ts_unit(unit, *, f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_unit(unit, *, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_unit(unit, *, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit, effSelector), *, f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_effUnit(effSelector, unit, effSelector, *, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_effUnit(effSelector, unit, effSelector, *, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit, *, f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_effGroupUnit(effSelector, unit, *, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_effGroupUnit(effSelector, unit, *, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
$offtext
        // ts_influx
        ts_influx(gn(grid, node), f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_influx(grid, node, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_influx(grid, node, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_cf(flow, node, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_cf(flow, node, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionNode(restype, up_down, node), f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_reserveDemand(restype, up_down, node, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_reserveDemand(restype, up_down, node, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_node(grid, node, param_gnBoundaryTypes, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_node(grid, node, param_gnBoundaryTypes, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
    ); // END loop(mf_central)

* --- Recalculate the other forecasts based on the improved central forecast --

    loop(f_solve(f)${ not mf_realization(mSolve, f) and not mf_central(mSolve, f) },
$ontext
* These don't work due to the wild cards in the parameter definitions!
        // ts_unit
        ts_unit(unit, *, f, tt(t))
            = ts_unit(unit, *, f, t) + ts_unit(unit, *, f+ddf(f), t);
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit, effSelector), *, f, tt(t))
            = ts_effUnit(effSelector, unit, effSelector, *, f, t) + ts_effUnit(effSelector, unit, effSelector, *, f+ddf(f), t);
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit, *, f, tt(t))
            = ts_effGroupUnit(effSelector, unit, *, f, t) + ts_effGroupUnit(effSelector, unit, *, f+ddf(f), t);
$offtext
        // ts_influx
        ts_influx(gn(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) + ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = max(min(ts_cf(flow, node, f, t) + ts_cf(flow, node, f+ddf(f), t), 1), 0); // Ensure that capacity factor forecasts remain between 0-1
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionNode(restype, up_down, node), f, tt(t))
            = max(ts_reserveDemand(restype, up_down, node, f, t) + ts_reserveDemand(restype, up_down, node, f+ddf(f), t), 0); // Ensure that reserve demand forecasts remains positive
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = ts_node(grid, node, param_gnBoundaryTypes, f, t) + ts_node(grid, node, param_gnBoundaryTypes, f+ddf(f), t);
    ); // END loop(f_solve)

); // END if(t_improveForecast)

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

* --- Select time series data matching the intervals, for stepsPerInterval = 1, this is trivial.

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

* --- If stepsPerInterval exceeds 1 (stepsPerInterval < 1 not defined) --------

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
* --- Input data processing ---------------------------------------------------
* =============================================================================

* --- Scenario reduction ------------------------------------------------------
s_active(s) = ms(mSolve, s);

if(active(mSolve, 'scenred'),
    $$include 'inc/scenred.gms'
);

* --- Smooting of stochastic scenarios ----------------------------------------
$ontext
First calculate standard deviation for over all samples, then smoothen the scenarios
following the methodology presented in [1, p. 443]. This avoids a discontinuity
`jump' after the initial sample.

[1] A. Helseth, B. Mo, A. Lote Henden, and G. Warland, "Detailed long-term hydro-
    thermal scheduling for expansion planning in the Nordic power system," IET Gener.
    Transm. Distrib., vol. 12, no. 2, pp. 441 - 447, 2018.
$offtext

* Influx
loop(gn(grid, node)$p_autocorrelation(grid, node, 'ts_influx'),
    ts_influx_mean(grid, node, ft(f, t))$mf_central(mSolve, f)
        = sum(s_parallel(s_active), ts_influx_(grid, node, f, t, s_active))
                / sum(s_parallel(s_active), 1);

    ts_influx_std(grid, node, ft(f, t))$mf_central(mSolve, f)
        = sqrt(sum(s_parallel(s_active), sqr(ts_influx_(grid, node, f, t, s_active)
                                         - ts_influx_mean(grid, node, f, t)))
                / sum(s_parallel(s_active), 1)
          );

    // Do smoothing
    loop(mst_end(ms_initial(mSolve, s_), t_),
        ts_influx_(grid, node, ft(f, t), s)$(ts_influx_std(grid, node, f, t_+dt_circular(t_))
                                             and sft(s, f, t)
                                             and not ms_initial(mSolve, s))
            = min(p_tsMaxValue(node, 'ts_influx'), max(p_tsMinValue(node, 'ts_influx'),
              ts_influx_(grid, node, f, t, s)
              + (ts_influx_(grid, node, f, t_, s_)
                 - ts_influx_(grid, node, f, t_, s))
                * (ts_influx_std(grid, node, f, t+dt_circular(t))
                    / ts_influx_std(grid, node, f, t_+dt_circular(t_)))
                * power(p_autocorrelation(grid, node, 'ts_influx'), abs(ord(t) - ord(t_)))
              ));
    );
);

* CF
loop(flowNode(flow, node)$p_autocorrelation(flow, node, 'ts_cf'),
    ts_cf_mean(flow, node, ft(f, t))$mf_central(mSolve, f)
        = sum(s_parallel(s_active), ts_cf_(flow, node, f, t, s_active))
                / sum(s_parallel(s_active), 1);

    ts_cf_std(flow, node, ft(f, t))$mf_central(mSolve, f)
        = sqrt(sum(s_parallel(s_active), sqr(ts_cf_(flow, node, f, t, s_active)
                                         - ts_cf_mean(flow, node, f, t)))
                / sum(s_parallel(s_active), 1)
          );

    // Do smoothing
    loop(mst_end(ms_initial(mSolve, s_), t_),
        ts_cf_(flow, node, ft(f, t), s)$(ts_cf_std(flow, node, f, t_+dt_circular(t_))
                                         and sft(s, f, t)
                                         and not ms_initial(mSolve, s))
            = min(p_tsMaxValue(node, 'ts_cf'), max(p_tsMinValue(node, 'ts_cf'),
              ts_cf_(flow, node, f, t, s)
              + (ts_cf_(flow, node, f, t_, s_)
                 - ts_cf_(flow, node, f, t_, s))
                * (ts_cf_std(flow, node, f, t+dt_circular(t))
                    / ts_cf_std(flow, node, f, t_+dt_circular(t_)))
                * power(p_autocorrelation(flow, node, 'ts_cf'), abs(ord(t) - ord(t_)))
              ));
    );
);