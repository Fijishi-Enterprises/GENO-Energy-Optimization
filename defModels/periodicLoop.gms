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

    fSolve(f) = no;
    fSolve(f)$mf(mSolve,f) = yes;

    tDispatchCurrent = 0;  // Reset dispatch loop
    tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve
    tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
    p_stepLength(mSolve, f, t) = no;
    ft_new(f,t) = no;

    tForecastNext(mSolve)$(ord(tSolve) >= tForecastNext(mSolve)) = tForecastNext(mSolve) + mSettings(mSolve, 't_ForecastJump');

    loop(tLatestForecast,  // There should be only one latest forecast
        ts_cf(flow,node,f,t)$(ord(f) > 1 and ord(f) <= mSettings(mSolve, 'forecasts') + 1 and ord(t) >= tSolveFirst + f_improve and ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength'))
          = ts_forecast(flow,node,tLatestForecast,f,t);
    );

$offOrder
    // Calculate parameters affected by model intervals
    if(sum(counter, mInterval(mSolve, 'intervalLength', counter)),  // But only if interval data has been set in the model definition file
        tCounter = 0;
        loop(counter$mInterval(mSolve, 'intervalLength', counter),  // Loop through all the different intervals set in the model definition file
            if (mInterval(mSolve, 'intervalLength', counter) = 1,  // Calculations are not needed if the time interval has the same length as original data
                tInterval(t) = no;
                tInterval(t)$(    ord(t) >= tSolveFirst + tCounter
                           and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                ) = yes;   // Set of t's where the interval is 1 (right border defined by intervalEnd) - but do not go beyond tSolveLast
                ts_influx_(grid, node, fSolve, t)$tInterval(t) = ts_influx(grid, node, fSolve, t+ct(t));
                ts_cf_(flow, node, fSolve, t)$tInterval(t) = ts_cf(flow, node, fSolve, t+ct(t));
                ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t)$tInterval(t) = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));
                ts_unit_(unit, param_unit, fSolve, t)$tInterval(t) = ts_unit(unit, param_unit, fSolve, t+ct(t));
                ts_reserveDemand_(restype, up_down, node, fSolve, t)$tInterval(t) = p_nReserves(node, resType, up_down);
                tCounter = mInterval(mSolve, 'intervalEnd', counter); // move tCounter to the next interval setting
                p_stepLength(mf(mSolve, fSolve), t)$tInterval(t) = mSettings(mSolve, 'intervalInHours');  // p_stepLength will hold the length of the interval in hours in model equations
                p_stepLengthNoReset(mSolve, fSolve, t)$tInterval(t) = mSettings(mSolve, 'intervalInHours');
                pt(t + 1)$tInterval(t) = -1;
            elseif mInterval(mSolve, 'intervalLength', counter) > 1, // intervalLength > 1 (not defined if intervalLength < 1)
                loop(t$[ord(t) >= tSolveFirst + tCounter and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)],  // Loop t relevant for each interval (interval borders defined by intervalEnd) - but do not go beyond tSolveLast
                    if (not mod(tCounter - mInterval(mSolve, 'intervalEnd', counter), mInterval(mSolve, 'intervalLength', counter)),  // Skip those t's that are not at the start of any interval
                        intervalLength = min(mInterval(mSolve, 'intervalLength', counter), max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon')) - tCounter);
                        p_stepLength(mf(mSolve, fSolve), t) = intervalLength * mSettings(mSolve, 'IntervalInHours');  // p_stepLength will hold the length of the interval in model equations
                        if (p_stepLengthNoReset(mSolve, 'f00', t) <> mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'IntervalInHours'),  // and skip those t's that have been calculated for the right interval previously
                            tInterval(t_) = no;
                            tInterval(t_)$(    ord(t_) >= ord(t)
                                           and ord(t_) < ord(t) + intervalLength
                            ) = yes;   // Set of t's within the interval (right border defined by intervalEnd) - but do not go beyond tSolveLast
                            ft_new(f,t_)$(mf(mSolve, f) and tInterval(t_)) = yes;
                            p_stepLengthNoReset(mf(mSolve, fSolve), t) = intervalLength * mSettings(mSolve, 'IntervalInHours');
                            // Aggregates the interval time series data by averaging the power data
                            ts_influx_(grid, node, fSolve, t) = sum{t_$tInterval(t_), ts_influx(grid, node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);  // Averages the absolute power terms over the interval
                            ts_cf_(flow, node, fSolve, t) = sum{t_$tInterval(t_), ts_cf(flow, node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);  // Averages the capacity factor over the inverval
                            ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t) = sum(t_${tInterval(t_)}, ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t_+ct(t_))) / p_stepLength(mSolve, fSolve, t); // Averages the time-dependent node state boundary conditions over the interval
                            ts_unit_(unit, param_unit, fSolve, t) = sum(t_${tInterval(t_)}, ts_unit(unit, param_unit, fSolve, t_+ct(t_))) / p_steplength(mSolve, fSolve, t); // Averages the time-dependent unit parameters over the interval
                            ts_reservedemand_(restype, up_down, node, fSolve, t) =  p_nReserves(node, resType, up_down); //Only static reserve for now
                            // Set the previous time step displacement
                            pt(t+intervalLength) = -intervalLength;
                        );
                    );  // end if that skips t's not at the start of any interval
                    tCounter = tCounter + 1;
                ); // end loop t
            ) // end if ... elseif
        ) // end loop for set intervals
    else
    // ...otherwise use all time periods with equal weight
        p_stepLength(mSolve, f, t)$(ord(t) >= tSolveFirst and ord(t) < tSolveLast and fRealization(f)) = mSettings(mSolve, 'IntervalInHours');
    );
    // Determine the time-series values for the last time step of the simulation, necessary for the state variables due to different indexing... NOTE! Doesn't aggregate in any way, uses raw data
    ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t)${ord(t) = tSolveLast} = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_influx_(grid, node, fSolve, t)${ord(t) = tSolveLast} = ts_influx(grid, node, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_cf_(flow, node, fSolve, t)${ord(t) = tSolveLast} = ts_cf(flow, node, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_unit_(unit, param_unit, fSolve, t)${ord(t) = tSolveLast} = ts_unit(unit, param_unit, fSolve, t+ct(t));
$onOrder

$include 'defModels\periodicLoopDispatch.gms';

ft_limits(f,t) = no;
ft_limits(f,t) = ft_full(f,t) + ft_realized(f,t);

uft_limits(unit, f, t) = no;
uft_limits(unit, f, t)$[ ft_limits(f, t)
                    and ord(t) <= tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                    and not unit_aggregate(unit)
                ] = yes;
uft_limits(unit, f, t)$[ ft_limits(f, t)
                    and ord(t) > tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                    and (unit_aggregate(unit) or unit_noAggregate(unit))
                ] = yes;

uft_limits_online(unit, f, t) = no;
loop(suft(effOnline, uft_limits(unit, f, t)), // Determine the time steps when units need to have online variables.
    uft_limits_online(unit, f, t) = yes;
);



// Calculate time series for unit parameters when necessary and/or possible
loop(unit${p_unit(unit, 'useTimeseries')},
    loop(effLevel${mSettingsEff(mSolve, effLevel)},

        // Calculate time series form parameters for units using direct input output conversion without online variable
        // Always constant 'lb', 'rb', and 'section', so need only to define 'slope'.
        loop(effGroupSelectorUnit(effDirectOff, unit, effDirectOff_),
            ts_effUnit(effDirectOff, unit, effDirectOff_, 'slope', ft(f, t))${sum(eff, ts_unit(unit, eff, f, t))} = // NOTE!!! Averages the slope over all available data.
                sum(eff${ts_unit(unit, eff, f, t)}, 1 / ts_unit(unit, eff, f, t)) / sum(eff${ts_unit(unit, eff, f, t)}, 1);
        );

        // NOTE! Using the same methodology for the directOn and lambda approximations in time series form might require looping over ft(f,t) to find the min and max 'eff' and 'rb'
        // Alternatively, one might require that the 'rb' is defined in a similar structure, so that the max 'rb' is located in the same index for all ft(f,t)

        // Calculate time series form parameters for units using direct input output conversion with online variable
*        loop(effGroupSelectorUnit(effDirectOn, unit, effDirectOn_),
*            ts_effUnit(effDirectOn, unit, effDirectOn_, 'lb', ft(f, t))${ts_unit(unit, 'rb00', f, t)} = ts_unit(unit, 'rb00', f, t); // rb00 contains the possible min load of the unit
*            ts_effUnit(effDirectOn, unit, effDirectOn_, 'rb', ft(f, t))${sum(rb, ts_unit(unit, rb, f, t))} = smax(rb, ts_unit(unit, rb, f, t)); // Maximum load determined by the largest 'rb' parameter found in data
*            loop(rb__${ts_unit(unit, rb__, ft(f, t)) = smax(rb, ts_unit(unit, rb, f, t))}, // Find the maximum defined 'rb'.
*                loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
*                    loop(rb_${ts_unit(unit, rb_, ft(f, t)) = smin(rb, ts_unit(unit, rb, f, t))}, // Find the minimum defined nonzero 'rb'.
*                        loop(eff_${ord(eff_) = ord(rb_)},                      // ... and the corresponding 'eff'.
*                            // Calculating the slope based on the first nonzero and the last defined data points.
*                            ts_effUnit(effDirectOn, unit, effDirectOn_, 'slope', ft(f, t)) =
*                                + (ts_unit(unit, rb__, f, t) / ts_unit(unit, eff__, f, t) - ts_unit(unit, rb_, f, t) / ts_unit(unit, eff_, f, t))
*                                    / (ts_unit(unit, rb__, f, t) - ts_unit(unit, rb_, f, t));
*                            // Calculating the section based on the slope and the last defined point.
*                            ts_effUnit(effDirectOn, unit, effDirectOn_, 'section', ft(f, t)) =
*                                ( 1 / ts_unit(unit, eff__, f, t) - ts_effUnit(effDirectOn, unit, effDirectOn_, 'slope', f, t) )
*                                    * ts_unit(unit, rb__, f, t);
*                        );
*                    );
*                );
*            );
*        );

        // Calculate lambdas
*        loop(effGroupSelectorUnit(effLambda, unit, effLambda_),
*            ts_effUnit(effLambda, unit, effLambda_, 'lb', ft(f, t)) = ts_unit(unit, 'rb00', f, t); // 'rb00' contains the possible minload of the unit, recorded for every lambda for ts_effGroupUnit.
*            // For the first lambda, simply use the first data point
*            if(ord(effLambda_) = 1,
*                ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = ts_unit(unit, 'rb00', f, t); // 'rb00' also works as the lowest lambda point.
*                ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = 1 / ts_unit(unit, 'eff00', f, t); // eff00 works as the lowest lambda slope.
*            // For the last lambda, use the last data point
*            elseif ord(effLambda_) = ord(effLambda),
*                loop(rb__${ts_unit(unit, rb__, ft(f, t)) = smax(rb, ts_unit(unit, rb, f, t))}, // Find the maximum defined 'rb'.
*                    loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
*                        ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = ts_unit(unit, rb__, f, t); // Last defined 'rb'.
*                        ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = 1 / ts_unit(unit, eff__, f, t); // Last defined 'eff'.
*                    );
*                );
*            // For the intermediary lambdas, use averages of the data points on each side.
*            else
*                count = sum(rb${ts_unit(unit, rb, ft(f, t))}, 1) + 1${not ts_unit(unit, 'rb00', f, t)}; // Count the data points to correctly establish the lambda intervals, have to separately account for the possibility of 'rb00' = 0.
*                count_lambda = floor( (ord(effLambda_) - 1) / (ord(effLambda) - 1) * count ); // Determine the data point index before the lambda
*                count_lambda2 = ceil( (ord(effLambda_) - 1) / (ord(effLambda) - 1) * count ); // Determine the data point index after the lambda
*                loop(rb__${ord(rb__) = count_lambda2}, // Find the ceiling data point 'rb'.
*                    loop(eff__${ord(eff__) = count_lambda2}, // ... and the corresponding 'eff'.
*                        loop(rb_${ord(rb_) = count_lambda}, // Find the floor data point 'rb'.
*                            loop(eff_${ord(eff_) = count_lambda}, // .. and the corresponding 'eff'.
*                                ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = (ts_unit(unit, rb__, f, t) + ts_unit(unit, rb_, f, t)) / 2; // Average the 'rb' between the found data points.
*                                ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = (1 / ts_unit(unit, eff__, f, t) + 1 / ts_unit(unit, eff_, f, t)) / 2; // Average the 'eff' between the found data points.
*                            );
*                        );
*                    );
*                );
*            );
*        );

    ); // END LOOP OVER effLevel
); // END LOOP OVER unit


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel${mSettingsEff(mSolve, effLevel)},
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            ts_effGroupUnit(effGroup, unit, 'rb', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'rb', f, t))} = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'rb', f, t));
            ts_effGroupUnit(effGroup, unit, 'lb', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t))} = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t));
            ts_effGroupUnit(effGroup, unit, 'slope', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'slope', f, t))} = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)); // Uses maximum efficiency for the group
        );
    );
);

