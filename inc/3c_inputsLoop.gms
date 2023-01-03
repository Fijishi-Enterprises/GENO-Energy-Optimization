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
tmp = max(  mSettings(mSolve, 't_forecastLengthUnchanging'),
            mSettings(mSolve, 't_forecastLengthDecreasesFrom')
            );

// Find time steps until the forecast horizon
option clear = tt_forecast;
tt_forecast(t_current(t))
    ${ ord(t) <= tSolveFirst + tmp }
    = yes;

if (ord(tSolve) = tForecastNext(mSolve) - mSettings(mSolve, 't_forecastJump'), // tForecastNext updated already in periodicLoop!

    // Update ts_unit
    if (mTimeseries_loop_read(mSolve, 'ts_unit'),
        put_utility 'gdxin' / '%input_dir%/ts_unit/' tSolve.tl:0 '.gdx';
        execute_load ts_unit_update=ts_unit;
        ts_unit(unit_timeseries(unit), param_unit, f_solve(f), tt_forecast(t)) // Only update if time series enabled for the unit
            ${not mf_realization(mSolve, f) // Realization not updated
              and (mSettings(mSolve, 'onlyExistingForecasts')
                   -> ts_unit_update(unit, param_unit, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_unit_update(unit, param_unit, f, t);
    ); // END if('ts_unit')
$ontext
* !!! NOTE !!!
* These probably shouldn't be read at all, as p_effUnit and p_effGroupUnit are
* not input data, but calculated based on p_unit
    // Update ts_effUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effUnit_update=ts_effUnit;
        ts_effUnit(effGroupSelectorUnit(effSelector, unit_timeseries(unit), effSelector), param_eff, f_solve(f), tt_forecast(t)) // Only update if time series enabled for the unit
            ${  not mf_realization(mSolve, f) // Realization not updated
*               and ts_effUnit_update(effSelector, unit, effSelector, param_eff, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_effUnit_update(effSelector, unit, effSelector, param_eff, f, t);
    ); // END if('ts_effUnit')

    // Update ts_effGroupUnit
    if (mTimeseries_loop_read(mSolve, 'ts_effGroupUnit'),
        put_utility 'gdxin' / '%input_dir%/ts_effGroupUnit/' tSolve.tl:0 '.gdx';
        execute_load ts_effGroupUnit_update=ts_effGroupUnit;
        ts_effGroupUnit(effSelector, unit_timeseries(unit), param_eff, f_solve(f), tt_forecast(t)) // Only update if time series enabled for the unit
            ${  not mf_realization(mSolve, f) // Realization not updated
*               and ts_effGroupUnit_update(effSelector, unit, param_eff, f, t) // Update only existing values (zeroes need to be EPS)
                }
            = ts_effGroupUnit_update(effSelector, unit, param_eff, f, t);
    ); // END if('ts_effGroupUnit')
$offtext
    // Update ts_influx
    if (mTimeseries_loop_read(mSolve, 'ts_influx'),
        put_utility 'gdxin' / '%input_dir%/ts_influx/' tSolve.tl:0 '.gdx';
        execute_load ts_influx_update=ts_influx;
        ts_influx(gn(grid, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_influx_update(grid, node, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_influx_update(grid, node, f, t);
    ); // END if('ts_influx')

    // Update ts_cf
    if (mTimeseries_loop_read(mSolve, 'ts_cf'),
        put_utility 'gdxin' / '%input_dir%/ts_cf/' tSolve.tl:0 '.gdx';
        execute_load ts_cf_update=ts_cf;
        ts_cf(flowNode(flow, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_cf_update(flow, node, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_cf_update(flow, node, f, t);
    ); // END if('ts_cf')

    // Update ts_reserveDemand
    if (mTimeseries_loop_read(mSolve, 'ts_reserveDemand'),
        put_utility 'gdxin' / '%input_dir%/ts_reserveDemand/' tSolve.tl:0 '.gdx';
        execute_load ts_reserveDemand_update=ts_reserveDemand;
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_reserveDemand_update(restype, up_down, group, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_reserveDemand_update(restype, up_down, group, f, t);
    ); // END if('ts_reserveDemand')

    // Update ts_node
    if (mTimeseries_loop_read(mSolve, 'ts_node'),
        put_utility 'gdxin' / '%input_dir%/ts_node/' tSolve.tl:0 '.gdx';
        execute_load ts_node_update=ts_node;
        ts_node(gn(grid, node), param_gnBoundaryTypes, f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_node_update(grid, node, param_gnBoundaryTypes, f ,t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_node_update(grid, node, param_gnBoundaryTypes, f, t);
    ); // END if('ts_node')

    // Update ts_gnn
    if (mTimeseries_loop_read(mSolve, 'ts_gnn'),
        put_utility 'gdxin' / '%input_dir%/ts_gnn/' tSolve.tl:0 '.gdx';
        execute_load ts_gnn_update=ts_gnn;
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f_solve(f), tt_forecast(t)) // Only update if time series enabled
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_gnn_update(grid, node, node_, param_gnn, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_gnn_update(grid, node, node_, param_gnn, f, t);
    ); // END if('ts_gnn')

* --- NO FORECAST DIMENSION, SHOULD THESE BE HANDLED SEPARATELY? --------------
// Currently, only updated until the forecast horizon, but is this correct?

    // Update ts_priceChange
    if (mTimeseries_loop_read(mSolve, 'ts_priceChange'),
        put log '!!! Abort: mTimeseries_loop_read(mSolve, ts_priceChange) currently not working!' /;
        abort "mTimeseries_loop_read(mSolve, ts_priceChange) currently not working!";
        put_utility 'gdxin' / '%input_dir%/ts_priceChange/' tSolve.tl:0 '.gdx';
        execute_load ts_priceChange_update=ts_priceChange;
        ts_priceChange(node, tt_forecast(t))
*            ${ ts_priceChange_update(fuel, t) } // Update only existing values (zeroes need to be EPS)
            = ts_priceChange_update(node, t);
    ); // END if('ts_priceChange')

    // Update ts_unavailability
    if (mTimeseries_loop_read(mSolve, 'ts_unavailability'),
        put_utility 'gdxin' / '%input_dir%/ts_unavailability/' tSolve.tl:0 '.gdx';
        execute_load ts_unavailability_update=ts_unavailability;
        ts_unavailability(unit, tt_forecast(t))
*            ${ ts_unavailability_update(unit, t) } // Update only existing values (zeroes need to be EPS)
            = ts_unavailability_update(unit, t);
    ); // END if('ts_unavailability')

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
        // ts_unit
        ts_unit(unit_timeseries(unit), param_unit, f, tt(t))// Only update for units with time series enabled
            = ts_unit(unit, param_unit, f, t) - ts_unit(unit, param_unit, f+ddf(f), t);
$ontext
* Should these be handled here at all? See above note
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit_timeseries(unit), effSelector), param_eff, f, tt(t)) // Only update for units with time series enabled
            = ts_effUnit(effSelector, unit, effSelector, param_eff, f, t) - ts_effUnit(effSelector, unit, effSelector, param_eff, f+ddf(f), t);
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit_timeseries(unit), param_eff, f, tt(t)) // Only update for units with time series enabled
            = ts_effGroupUnit(effSelector, unit, param_eff, f, t) - ts_effGroupUnit(effSelector, unit, param_eff, f+ddf(f), t);
$offtext
        // ts_influx
        ts_influx(gn(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) - ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = ts_cf(flow, node, f, t) - ts_cf(flow, node, f+ddf(f), t);
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = ts_reserveDemand(restype, up_down, group, f, t) - ts_reserveDemand(restype, up_down, group, f+ddf(f), t);
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = ts_node(grid, node, param_gnBoundaryTypes, f, t) - ts_node(grid, node, param_gnBoundaryTypes, f+ddf(f), t);
        // ts_gnn
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f, tt(t)) // Only update if time series enabled
            = ts_gnn(grid, node, node_, param_gnn, f, t) - ts_gnn(grid, node, node_, param_gnn, f+ddf(f), t);
    ); // END loop(f_solve)

* --- Linear improvement of the central forecast ------------------------------

    loop(mf_central(mSolve, f),
        // ts_unit
        ts_unit(unit_timeseries(unit), param_unit, f, tt(t)) // Only update for units with time series enabled
            = [ + (ord(t) - tSolveFirst)
                    * ts_unit(unit, param_unit, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_unit(unit, param_unit, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
$ontext
* Should these be handled here at all? See above note
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit_timeseries(unit), effSelector), param_eff, f, tt(t)) // Only update for units with time series enabled
            = [ + (ord(t) - tSolveFirst)
                    * ts_effUnit(effSelector, unit, effSelector, param_eff, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_effUnit(effSelector, unit, effSelector, param_eff, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit_timeseries(unit), param_eff, f, tt(t)) // Only update for units with time series enabled
            = [ + (ord(t) - tSolveFirst)
                    * ts_effGroupUnit(effSelector, unit, param_eff, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_effGroupUnit(effSelector, unit, param_eff, f+ddf_(f), t)
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
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_reserveDemand(restype, up_down, group, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_reserveDemand(restype, up_down, group, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = [ + (ord(t) - tSolveFirst)
                    * ts_node(grid, node, param_gnBoundaryTypes, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_node(grid, node, param_gnBoundaryTypes, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_gnn
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f, tt(t)) // Only update if time series enabled
            = [ + (ord(t) - tSolveFirst)
                    * ts_gnn(grid, node, node_, param_gnn, f, t)
                + (tSolveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_gnn(grid, node, node_, param_gnn, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
    ); // END loop(mf_central)

* --- Recalculate the other forecasts based on the improved central forecast --

    loop(f_solve(f)${ not mf_realization(mSolve, f) and not mf_central(mSolve, f) },
        // ts_unit
        ts_unit(unit_timeseries(unit), param_unit, f, tt(t)) // Only update for units with time series enabled
            = ts_unit(unit, param_unit, f, t) + ts_unit(unit, param_unit, f+ddf(f), t);
$ontext
* Should these be handled here at all? See above note
        // ts_effUnit
        ts_effUnit(effGroupSelectorUnit(effSelector, unit_timeseries(unit), effSelector), param_eff, f, tt(t)) // Only update for units with time series enabled
            = ts_effUnit(effSelector, unit, effSelector, param_eff, f, t) + ts_effUnit(effSelector, unit, effSelector, param_eff, f+ddf(f), t);
        // ts_effGroupUnit
        ts_effGroupUnit(effSelector, unit_timeseries(unit), param_eff, f, tt(t)) // Only update for units with time series enabled
            = ts_effGroupUnit(effSelector, unit, param_eff, f, t) + ts_effGroupUnit(effSelector, unit, param_eff, f+ddf(f), t);
$offtext
        // ts_influx
        ts_influx(gn(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) + ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = max(min(ts_cf(flow, node, f, t) + ts_cf(flow, node, f+ddf(f), t), 1), 0); // Ensure that capacity factor forecasts remain between 0-1
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = max(ts_reserveDemand(restype, up_down, group, f, t) + ts_reserveDemand(restype, up_down, group, f+ddf(f), t), 0); // Ensure that reserve demand forecasts remains positive
        // ts_node
        ts_node(gn(grid, node), param_gnBoundaryTypes, f, tt(t))
            = ts_node(grid, node, param_gnBoundaryTypes, f, t) + ts_node(grid, node, param_gnBoundaryTypes, f+ddf(f), t);
        // ts_gnn
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f, tt(t)) // Only update if time series enabled
            = ts_gnn(grid, node, node_, param_gnn, f, t) + ts_gnn(grid, node, node_, param_gnn, f+ddf(f), t);
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

    // Select and average time series data matching the intervals
    ts_unit_(unit_timeseries(unit), param_unit, ft(f, tt_interval(t)))
        = sum(tt_aggcircular(t, t_),
            ts_unit(unit, param_unit, f, t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
$ontext
* Should these be handled here at all? See above comment
    ts_effUnit_(effGroupSelectorUnit(effSelector, unit_timeseries(unit), effSelector), param_eff, ft(f, tt_interval(t)))
        = sum(tt_aggcircular(t, t_),
            ts_effUnit(effSelector, unit, effSelector, param_eff, f, t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
    ts_effGroupUnit_(effSelector, unit_timeseries(unit), param_eff, ft(f, tt_interval(t)))
        = sum(tt_aggcircular(t, t_),
            ts_effGroupUnit(effSelector, unit, param_eff, f, t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
$offtext
    ts_influx_(gn, sft(s, f, tt_interval(t)))$gn_scenarios(gn, 'ts_influx')
        = sum(tt_aggregate(t, t_),
            ts_influx(gn,
                f + (  df_realization(f, t)$(not gn_forecasts(gn, 'ts_influx'))
                     + df_scenario(f, t)),
                t_+ (+ dt_scenarioOffset(gn, 'ts_influx', s)))
            ) / mInterval(mSolve, 'stepsPerInterval', counter);
    ts_influx_(gn, sft(s, f, tt_interval(t)))$(not gn_scenarios(gn, 'ts_influx'))
        = sum(tt_aggcircular(t, t_),
            ts_influx(gn,
                f + (  df_realization(f, t)$(not gn_forecasts(gn, 'ts_influx'))),
                t_  )
            ) / mInterval(mSolve, 'stepsPerInterval', counter);
    ts_cf_(flowNode(flow, node), sft(s, f, tt_interval(t)))
        = sum(tt_aggregate(t, t_),
            ts_cf(flow, node,
                f + (  df_realization(f, t)$(not gn_forecasts(flow, node, 'ts_cf'))
                     + df_scenario(f, t)$gn_scenarios(flow, node, 'ts_cf')),
                t_+ (  dt_scenarioOffset(flow, node, 'ts_cf', s)
                     + dt_circular(t_)$(not gn_scenarios(flow, node, 'ts_cf'))))
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
    // Reserves relevant only until reserve_length
    ts_reserveDemand_(restypeDirectionGroup(restype, up_down, group), ft(f, tt_interval(t)))
      ${ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'reserve_length')  }
        = sum(tt_aggcircular(t, t_),
            ts_reserveDemand(restype, up_down, group,
                f + (  df_realization(f, t)${not sum(gnGroup(grid, node, group), gn_forecasts(restype, node, 'ts_reserveDemand'))}
                     + df_scenario(f, t)${sum(gnGroup(grid, node, group), gn_scenarios(restype, node, 'ts_reserveDemand'))} ), t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
    ts_node_(gn_state(grid, node), param_gnBoundaryTypes, sft(s, f, tt_interval(t)))
      $p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
           // Take average if not a limit type
        = (sum(tt_aggregate(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes,
                    f + (  df_realization(f, t)$(not gn_forecasts(grid, node, 'ts_node'))
                         + df_scenario(f, t)$gn_scenarios(grid, node, 'ts_node')),
                    t_+ (   + dt_scenarioOffset(grid, node, param_gnBoundaryTypes, s)
                            + dt_circular(t_)$(not gn_scenarios(grid, node, 'ts_node'))))
            )
            / mInterval(mSolve, 'stepsPerInterval', counter))$( not (sameas(param_gnBoundaryTypes, 'upwardLimit')
                                                                or sameas(param_gnBoundaryTypes, 'downwardLimit')
                                                                or slack(param_gnBoundaryTypes)))
          // Maximum lower limit
          + smax(tt_aggregate(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes,
                    f + (  df_realization(f, t)$(not gn_forecasts(grid, node, 'ts_node'))
                         + df_scenario(f, t)$gn_scenarios(grid, node, 'ts_node')),
                    t_+ (   + dt_scenarioOffset(grid, node, param_gnBoundaryTypes, s)
                            + dt_circular(t_)$(not gn_scenarios(grid, node, 'ts_node'))))
                )
                $(sameas(param_gnBoundaryTypes, 'downwardLimit') or downwardSlack(param_gnBoundaryTypes))
          // Minimum upper limit
          + smin(tt_aggregate(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes,
                    f + (  df_realization(f, t)$(not gn_forecasts(grid, node, 'ts_node'))
                         + df_scenario(f, t)$gn_scenarios(grid, node, 'ts_node')),
                    t_+ (   + dt_scenarioOffset(grid, node, param_gnBoundaryTypes, s)
                            + dt_circular(t_)$(not gn_scenarios(grid, node, 'ts_node'))))
                )
                $(sameas(param_gnBoundaryTypes, 'upwardLimit') or upwardSlack(param_gnBoundaryTypes));

    ts_gnn_(gn2n_timeseries(grid, node, node_, param_gnn), ft(f, tt_interval(t)))
        = sum(tt_aggregate(t, t_),
            ts_gnn(grid, node, node_, param_gnn, f, t_+dt_circular(t_))
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);

    // Node price time series
    ts_vomCost_(gnu(grid, node, unit), tt_interval(t))
        = + p_gnu(grid, node, unit, 'vomCosts')
          // input node cost
          + (
             + p_price(node, 'price')$p_price(node, 'useConstant')
             + sum(tt_aggcircular(t, t_), ts_price(node, t_))$p_price(node, 'useTimeSeries')
                 / mInterval(mSolve, 'stepsPerInterval', counter)
            )$gnu_input(grid, node, unit)
          // output node cost (if price > 0 --> ts_vomCost_ < 0, i.e. considered as revenue)
          - (
             + p_price(node, 'price')$p_price(node, 'useConstant')
             + sum(tt_aggcircular(t, t_), ts_price(node, t_))$p_price(node, 'useTimeSeries')
                 / mInterval(mSolve, 'stepsPerInterval', counter)
            )$gnu_output(grid, node, unit)
          // emission cost
          + sum(emission$p_unitEmissionCost(unit, node, emission), // Emission taxes
              + p_unitEmissionCost(unit, node, emission)
            ); // END sum(emission)

    // Calculating startup cost time series
    ts_startupCost_(unit, starttype, tt_interval(t))
      =
        + p_uStartup(unit, starttype, 'cost') // CUR/start-up
        // Start-up fuel and emission costs
        + sum(nu_startup(node, unit),
            + p_unStartup(unit, node, starttype) // MWh/start-up
              * [
                  // Fuel costs
                  + p_price(node, 'price')$p_price(node, 'useConstant') // CUR/MWh
                  + sum(tt_aggcircular(t, t_),
                      + ts_price(node, t_) // CUR/MWh
                    )$p_price(node, 'useTimeseries')
                    / mInterval(mSolve, 'stepsPerInterval', counter)
                  // Emission costs
                  + sum(emission$p_nEmission(node, emission),
                      + p_nEmission(node, emission) // kg/MWh
                          / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
                          * sum(gnGroup(grid, node, group),
                              + p_groupPolicyEmission(group, 'emissionTax', emission) // CUR/t
                              ) // END sum(gnGroup)
                      ) // END sum(emission)
                ] // END * p_unStartup
            ); // END sum(nu_startup)

    // `storageValue`
    ts_storageValue_(gn_state(grid, node), sft(s, f, tt_interval(t)))${ p_gn(grid, node, 'storageValueUseTimeSeries') }
        = sum(tt_aggregate(t, t_),
            ts_storageValue(grid, node,
                f + (  df_realization(f, t)$(not gn_forecasts(grid, node, 'ts_storageValue'))
                     + df_scenario(f, t)$gn_scenarios(grid, node, 'ts_storageValue')),
                t_+ (+ dt_scenarioOffset(grid, node, 'ts_storageValue', s)
                     + dt_circular(t_)$(not gn_scenarios(grid, node, 'ts_storageValue'))))
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);

); // END loop(counter)


* --- Process unit time series data -------------------------------------------

// Calculate time series form parameters for units using direct input output conversion without online variable
// Always constant 'lb', 'rb', and 'section', so need only to define 'slope'.
loop(effGroupSelectorUnit(effDirectOff, unit_timeseries(unit), effDirectOff_),
    ts_effUnit(effDirectOff, unit, effDirectOff_, 'slope', ft(f, t))
        ${ sum(eff, ts_unit(unit, eff, f, t)) } // NOTE!!! Averages the slope over all available data.
        = sum(eff${ts_unit(unit, eff, f, t)}, 1 / ts_unit(unit, eff, f, t))
            / sum(eff${ts_unit(unit, eff, f, t)}, 1);
); // END loop(effGroupSelectorUnit)

// NOTE! Using the same methodology for the directOn and lambda approximations in time series form might require looping over ft(f,t) to find the min and max 'eff' and 'rb'
// Alternatively, one might require that the 'rb' is defined in a similar structure, so that the max 'rb' is located in the same index for all ft(f,t)

// Calculate unit wide parameters for each efficiency group
loop(effLevelGroupUnit(effLevel, effGroup, unit)${  mSettingsEff(mSolve, effLevel)
                                                    and p_unit(unit, 'useTimeseries')
                                                    },
    ts_effGroupUnit(effGroup, unit, 'lb', ft(f, t))${   sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t))}
        = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t));
    ts_effGroupUnit(effGroup, unit, 'slope', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'slope', f, t))}
        = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)); // Uses maximum efficiency for the group
); // END loop(effLevelGroupUnit)


* =============================================================================
* --- Input data processing ---------------------------------------------------
* =============================================================================

$ifthen.scenarios defined scenario
* --- Scenario reduction ------------------------------------------------------
if(active(mSolve, 'scenred') and mSettings('schedule', 'scenarios') > 1,
    $$include 'inc/scenred.gms'
);
$endif.scenarios

* --- Update probabilities ----------------------------------------------------
Option clear = p_msft_probability;
p_msft_probability(msft(mSolve, s, f, t))
    = p_mfProbability(mSolve, f)
        / sum(f_$ft(f_, t),
              p_mfProbability(mSolve, f_)
          ) * p_msProbability(mSolve, s)
            * p_msWeight(mSolve, s);


* --- Calculate sample displacements ------------------------------------------
Options clear = ds, clear = ds_state;
loop((mst_start(mSolve, s, t), ss(s, s_)),
    ds(s, t) = -(ord(s) - ord(s_));
    ds_state(gn_state(grid, node), s, t)
      ${not sum(s__, gnss_bound(grid, node, s__, s))
        and not sum(s__, gnss_bound(grid, node, s, s__))} = ds(s, t);
);


* --- Smooting of stochastic scenarios ----------------------------------------
$ontext
Smoothen the scenarios following the methodology presented in [1, p. 443].
This avoids a discontinuity `jump' after the initial sample.

[1] A. Helseth, B. Mo, A. Lote Henden, and G. Warland, "Detailed long-term hydro-
    thermal scheduling for expansion planning in the Nordic power system," IET Gener.
    Transm. Distrib., vol. 12, no. 2, pp. 441 - 447, 2018.
$offtext

* Check that we have values for the autocorrelations
$ifthen.autocorr defined p_autocorrelation

// Do smoothing
if(mSettings(mSolve, 'scenarios') > 0,  // Only do smooting if using long-term scenarios
    // Select the initial sample, the last time in it (t_)
    // and the forecast (f_) of the last simulated time step (t__) in it
    loop((ms_initial(mSolve, s_), t_, ft(f_, t__))
        $[ord(t_) = msEnd(mSolve, s_) + tSolveFirst - 1
          and mst_end(mSolve, s_, t__)
          and (mf_realization(mSolve, f_) xor mf_central(mSolve, f_))
         ],
        $$batinclude 'inc/smoothing.gms' ts_influx
        $$batinclude 'inc/smoothing.gms' ts_cf
    );
); // END if('scenarios')
$endif.autocorr

* --- Calculate relative error -------------------------------------------------
$iftheni %diag% == 'yes'

// Forecast/scenario values with time aggregation
p_netLoad_model(t_current(t))$[ord(t) > ord(tSolve)]
     = sum(msft(mSolve, s, f, t_)$tt_aggregate(t_, t),
        p_msft_probability(mSolve, s, f, t_) * sum(gn(grid, node),
            -1 * ts_influx_(grid, node, s, f, t_)
            - sum((gnu(grid, node, unit), flowUnit(flow, unit)),
                    ts_cf_(flow, node, s, f, t_) * p_gnu(grid, node, unit, 'capacity')
              )
        )
      );

// Actual values
p_netLoad_real(t_current(t))$[ord(t) > ord(tSolve)]
     = sum((mf_realization(mSolve, f), gn(grid, node)),
        -1 * ts_influx(grid, node, f, t)
        - sum((gnu(grid, node, unit), flowUnit(flow, unit)),
            ts_cf(flow, node, f, t) * p_gnu(grid, node, unit, 'capacity')
          )
    );

// Calculate total horizon expected net load error
d_totalNetLoad_error(tSolve) =
    sum(t_current(t)$[ord(t) > ord(tSolve) + mSettings(mSolve, 't_jump')],
        p_netLoad_model(t)
    ) / sum(t_current(t)$[ord(t) > ord(tSolve) + mSettings(mSolve, 't_jump')],
        p_netLoad_real(t)
      ) - 1;

// Calculate forecast period expected net load error
loop(ms_initial(mSolve, s),
    d_totalNetLoad_error_fcast(tSolve) =
        sum(t_current(t)$[
          ord(t) > ord(tSolve) + mSettings(mSolve, 't_jump')
          and ord(t) < msEnd(mSolve, s) + tSolveFirst
        ],
            p_netLoad_model(t)
        ) / sum(t_current(t)$[
            ord(t) > ord(tSolve) + mSettings(mSolve, 't_jump')
            and ord(t) < msEnd(mSolve, s) + tSolveFirst
        ],
            p_netLoad_real(t)
          ) - 1;
);
$endif
