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

tmp = round(sum(m, mSettings(m, 't_end')) / sum(m, mSettings(m, 't_jump')), 0);

put log 'ord t_solve: ';
put log ord(t_solve):0:0 /;
put log 'solve count : '
put log solveCount:0:0 '/' tmp:0:0 /;

putclose log;

// Determine the necessary horizon for updating data
option clear = tmp;
tmp = max(  mSettings(mSolve, 't_forecastLengthUnchanging'),
            mSettings(mSolve, 't_forecastLengthDecreasesFrom')
            );

// Find time steps until the forecast horizon
option clear = tt_forecast;
tt_forecast(t_current(t))
    ${ ord(t) <= t_solveFirst + tmp }
    = yes;

if (ord(t_solve) = tForecastNext(mSolve) - mSettings(mSolve, 't_forecastJump'), // tForecastNext updated already in periodicLoop!

    // Update ts_unit
    if (mTimeseries_loop_read(mSolve, 'ts_unit'),
        put_utility 'gdxin' / '%input_dir%/ts_unit/' t_solve.tl:0 '.gdx';
        execute_load ts_unit_update=ts_unit;
        ts_unit(unit_timeseries(unit), param_unit, f_solve(f), tt_forecast(t)) // Only update if time series enabled for the unit
            ${not mf_realization(mSolve, f) // Realization not updated
              and (mSettings(mSolve, 'onlyExistingForecasts')
                   -> ts_unit_update(unit, param_unit, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_unit_update(unit, param_unit, f, t);
    ); // END if('ts_unit')

    // Update ts_influx
    if (mTimeseries_loop_read(mSolve, 'ts_influx'),
        put_utility 'gdxin' / '%input_dir%/ts_influx/' t_solve.tl:0 '.gdx';
        execute_load ts_influx_update=ts_influx;
        ts_influx(gn_influx(grid, node), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_influx_update(grid, node, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_influx_update(grid, node, f, t);
    ); // END if('ts_influx')

    // Update ts_cf
    if (mTimeseries_loop_read(mSolve, 'ts_cf'),
        put_utility 'gdxin' / '%input_dir%/ts_cf/' t_solve.tl:0 '.gdx';
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
        put_utility 'gdxin' / '%input_dir%/ts_reserveDemand/' t_solve.tl:0 '.gdx';
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
        put_utility 'gdxin' / '%input_dir%/ts_node/' t_solve.tl:0 '.gdx';
        execute_load ts_node_update=ts_node;
        ts_node(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), f_solve(f), tt_forecast(t))
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_node_update(grid, node, param_gnBoundaryTypes, f ,t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_node_update(grid, node, param_gnBoundaryTypes, f, t);
    ); // END if('ts_node')

    // Update ts_gnn
    if (mTimeseries_loop_read(mSolve, 'ts_gnn'),
        put_utility 'gdxin' / '%input_dir%/ts_gnn/' t_solve.tl:0 '.gdx';
        execute_load ts_gnn_update=ts_gnn;
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f_solve(f), tt_forecast(t)) // Only update if time series enabled
            ${  not mf_realization(mSolve, f) // Realization not updated
                and (mSettings(mSolve, 'onlyExistingForecasts')
                     -> ts_gnn_update(grid, node, node_, param_gnn, f, t)) // Update only existing values (zeroes need to be EPS)
                }
            = ts_gnn_update(grid, node, node_, param_gnn, f, t);
    ); // END if('ts_gnn')

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
        ${ ord(t) <= t_solveFirst + mSettings(mSolve, 't_improveForecast') }
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
        // ts_unitConstraintNode
        ts_unitConstraintNode(unit, constraint, node, f, tt(t))${unit_tsConstrained(unit)}
            = ts_unitConstraintNode(unit, constraint, node, f, t) - ts_unitConstraintNode(unit, constraint, node, f+ddf(f), t);
        // ts_influx
        ts_influx(gn_influx(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) - ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = ts_cf(flow, node, f, t) - ts_cf(flow, node, f+ddf(f), t);
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = ts_reserveDemand(restype, up_down, group, f, t) - ts_reserveDemand(restype, up_down, group, f+ddf(f), t);
        // ts_node
        ts_node(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), f, tt(t))
            = ts_node(grid, node, param_gnBoundaryTypes, f, t) - ts_node(grid, node, param_gnBoundaryTypes, f+ddf(f), t);
        // ts_gnn
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f, tt(t)) // Only update if time series enabled
            = ts_gnn(grid, node, node_, param_gnn, f, t) - ts_gnn(grid, node, node_, param_gnn, f+ddf(f), t);
    ); // END loop(f_solve)

* --- Linear improvement of the central forecast ------------------------------

    loop(mf_central(mSolve, f),
        // ts_unit
        ts_unit(unit_timeseries(unit), param_unit, f, tt(t)) // Only update for units with time series enabled
            = [ + (ord(t) - t_solveFirst)
                    * ts_unit(unit, param_unit, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_unit(unit, param_unit, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        ts_unitConstraintNode(unit, constraint, node, f, tt(t))${unit_tsConstrained(unit)}
            = [ + (ord(t) - t_solveFirst)
                    * ts_unitConstraintNode(unit, constraint, node, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_unitConstraintNode(unit, constraint, node, f+ddf_(f), t)
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
        ts_influx(gn_influx(grid, node), f, tt(t))
            = [ + (ord(t) - t_solveFirst)
                    * ts_influx(grid, node, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_influx(grid, node, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = [ + (ord(t) - t_solveFirst)
                    * ts_cf(flow, node, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_cf(flow, node, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = [ + (ord(t) - t_solveFirst)
                    * ts_reserveDemand(restype, up_down, group, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_reserveDemand(restype, up_down, group, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_node
        ts_node(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), f, tt(t))
            = [ + (ord(t) - t_solveFirst)
                    * ts_node(grid, node, param_gnBoundaryTypes, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
                    * ts_node(grid, node, param_gnBoundaryTypes, f+ddf_(f), t)
                ] / mSettings(mSolve, 't_improveForecast');
        // ts_gnn
        ts_gnn(gn2n_timeseries(grid, node, node_, param_gnn), f, tt(t)) // Only update if time series enabled
            = [ + (ord(t) - t_solveFirst)
                    * ts_gnn(grid, node, node_, param_gnn, f, t)
                + (t_solveFirst - ord(t) + mSettings(mSolve, 't_improveForecast'))
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
        ts_influx(gn_influx(grid, node), f, tt(t))
            = ts_influx(grid, node, f, t) + ts_influx(grid, node, f+ddf(f), t);
        // ts_cf
        ts_cf(flowNode(flow, node), f, tt(t))
            = max(min(ts_cf(flow, node, f, t) + ts_cf(flow, node, f+ddf(f), t), 1), 0); // Ensure that capacity factor forecasts remain between 0-1
        // ts_reserveDemand
        ts_reserveDemand(restypeDirectionGroup(restype, up_down, group), f, tt(t))
            = max(ts_reserveDemand(restype, up_down, group, f, t) + ts_reserveDemand(restype, up_down, group, f+ddf(f), t), 0); // Ensure that reserve demand forecasts remains positive
       // ts_node
        ts_node(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), f, tt(t))
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
        ${ sum(s, sft(s, f, t)) }
        = sum(tt_aggcircular(t, t_),
            ts_unit(unit, param_unit, f, t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);
    ts_unitConstraintNode_(unit, constraint, node, sft(s, f, tt_interval(t)))${unit_tsConstrained(unit)}
        = sum(tt_aggcircular(t, t_),
            ts_unitConstraintNode(unit, constraint, node, f, t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);

    // ts_influx_ for active t in solve including aggregated time steps
    ts_influx_(gn_influx(grid, node), sft(s, f, tt_interval(t)))
        = sum(tt_aggcircular(t, t_),
            ts_influx(grid, node, f + df_realization(f, t), t_)
            ) / mInterval(mSolve, 'stepsPerInterval', counter);

    // ts_cf_ for active t in solve including aggregated time steps
    ts_cf_(flowNode(flow, node), sft(s, f, tt_interval(t)))
        = sum(tt_aggcircular(t, t_),
            ts_cf(flow, node, f + df_realization(f, t), t_)
            ) / mInterval(mSolve, 'stepsPerInterval', counter);

    // Reserves relevant only until reserve_length
    ts_reserveDemand_(restypeDirectionGroup(restype, up_down, group), ft(f, tt_interval(t)))
      ${ord(t) <= t_solveFirst + p_groupReserves(group, restype, 'reserve_length')
        and sum(s, sft(s, f, t)) }
        = sum(tt_aggcircular(t, t_),
            ts_reserveDemand(restype, up_down, group, f + df_realization(f, t), t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);

    // ts_node_ for active t in solve including aggregated time steps
    ts_node_(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), sft(s, f, tt_interval(t)))
           // Take average if not a limit type
        = (sum(tt_aggcircular(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes, f + df_realization(f, t), t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter))$( not (sameas(param_gnBoundaryTypes, 'upwardLimit')
                                                                or sameas(param_gnBoundaryTypes, 'downwardLimit')
                                                                or slack(param_gnBoundaryTypes)))
          // Maximum lower limit
          + smax(tt_aggcircular(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes, f + df_realization(f, t), t_)
                )
                $(sameas(param_gnBoundaryTypes, 'downwardLimit') or downwardSlack(param_gnBoundaryTypes))
          // Minimum upper limit
          + smin(tt_aggcircular(t, t_),
                ts_node(grid, node, param_gnBoundaryTypes, f + df_realization(f, t), t_)
                )
                $(sameas(param_gnBoundaryTypes, 'upwardLimit') or upwardSlack(param_gnBoundaryTypes));

    // processing ts_gnn values for active ft including time step aggregation
    ts_gnn_(gn2n_timeseries(grid, node, node_, param_gnn), ft(f, tt_interval(t)))
        ${ sum(s, sft(s, f, t)) }
        = sum(tt_aggcircular(t, t_), ts_gnn(grid, node, node_, param_gnn, f, t_))
            / mInterval(mSolve, 'stepsPerInterval', counter);

    // vomCost calculations when one or more price time series
    ts_vomCost_(gnu(grid, node, unit), tt_interval(t))
        ${p_vomCost(grid, node, unit, 'useTimeseries')
          and sum((s, f), sft(s, f, t)) }
        = sum(tt_aggcircular(t, t_),
                // gnu specific cost. Always a cost (positive) if input or output.
                // vomCosts
                + p_gnu(grid, node, unit, 'vomCosts')

                // gnu specific emission cost (e.g. process related LCA emission). Always a cost if input or output.
                + sum(emissionGroup(emission, group)$ p_nEmission(node, emission),
                     + p_gnuEmission(grid, node, unit, emission, 'vomEmissions') // t/MWh
                     * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                         + ts_emissionPrice(emission, group, t_)$p_emissionPrice(emission, group, 'useTimeSeries')
                       )
                     ) // end sum(emissiongroup)

                // gn specific costs. Cost when input but income when output.
                // converting gn specific costs negative if output -> income
                + (+1$gnu_input(grid, node, unit)
                   -1$gnu_output(grid, node, unit)
                  )

                * ( // gn specific node cost, e.g. fuel price
                    + p_price(node, 'price')${p_price(node, 'useConstant')}
                    + ts_price(node, t_)${p_price(node, 'useTimeSeries')}

                    // gn specific emission cost, e.g. CO2 allowance price from fuel emissions.
                    + sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                        + p_nEmission(node, emission)  // t/MWh
                        * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                            + ts_emissionPrice(emission, group, t_)$p_emissionPrice(emission, group, 'useTimeSeries')
                          )
                        ) // end sum(emissiongroup)
                  ) // END * gnu_input/output
             ) // END sum(tt_aggcircular)
             / mInterval(mSolve, 'stepsPerInterval', counter) // dividing the sum by steplength to convert values in aggregated time steps to hourly values
    ;

    // Startup cost calculations
    ts_startupCost_(unit, starttype, tt_interval(t))
        ${p_startupCost(unit, starttype, 'useTimeSeries')
          and sum((s, f), sft(s, f, t)) }
      = sum(tt_aggcircular(t, t_),
        + p_uStartup(unit, starttype, 'cost') // CUR/start-up
        // Start-up fuel and emission costs
        + sum(nu_startup(node, unit),
            + p_unStartup(unit, node, starttype) // MWh/start-up
              * [
                  // Fuel costs
                  + p_price(node, 'price')$p_price(node, 'useConstant') // CUR/MWh
                  + ts_price(node, t_)$p_price(node, 'useTimeseries')// CUR/MWh
                  // Emission costs
                  // node specific emission prices
                  + sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                     + p_nEmission(node, emission) // t/MWh
                     * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                         + ts_emissionPrice(emission, group, t_)$p_emissionPrice(emission, group, 'useTimeSeries')
                       )
                    ) // end sum(emissionGroup)
                ] // END * p_unStartup
          ) // END sum(nu_startup)
        ) / mInterval(mSolve, 'stepsPerInterval', counter) // END sum(tt_aggcircular)
    ;

    // `storageValue`
    ts_storageValue_(gn_state(grid, node), sft(s, f, tt_interval(t)))${ p_gn(grid, node, 'storageValueUseTimeSeries') }
        = sum(tt_aggcircular(t, t_),
            ts_storageValue(grid, node, f + df_realization(f, t), t_)
            )
            / mInterval(mSolve, 'stepsPerInterval', counter);

); // END loop(counter)


* --- Process unit time series data -------------------------------------------

// Calculate time series form parameters for units using direct input output conversion without online variable
// Always constant 'lb', 'rb', and 'section', so need only to define 'slope'.
loop(effGroupSelectorUnit(effDirectOff, unit_timeseries(unit), effDirectOff_),
    ts_effUnit(effDirectOff, unit, effDirectOff_, 'slope', ft(f, t))
        ${ sum(eff, ts_unit_(unit, eff, f, t)) } // NOTE!!! Averages the slope over all available data.
        = sum(eff${ts_unit_(unit, eff, f, t)}, 1 / ts_unit_(unit, eff, f, t))
            / sum(eff${ts_unit_(unit, eff, f, t)}, 1);
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



