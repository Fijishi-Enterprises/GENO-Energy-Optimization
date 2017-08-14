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

* --- Determine the forecast-time indeces included in the current solve -------
// Select the forecasts included in the current solve
fSolve(f) = no;
fSolve(f)$mf(mSolve,f) = yes;

// Reset dispatch loop
tDispatchCurrent = 0;

// Determine the first and last timesteps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve
tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
p_stepLength(mSolve, f, t) = no;
*ft_new(f,t) = no;

// Determine the next and latest forecasts (???)
tForecastNext(mSolve)${ ord(tSolve) >= tForecastNext(mSolve)
                        } = tForecastNext(mSolve) + mSettings(mSolve, 't_ForecastJump');
loop(tLatestForecast,  // There should be only one latest forecast
    ts_cf(flow,node,f,t)${  ord(f) > 1
                            and ord(f) <= mSettings(mSolve, 'forecasts') + 1
                            and ord(t) >= tSolveFirst + f_improve and
                            ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength')
                            } = ts_forecast(flow,node,tLatestForecast,f,t);
);

// Initializing sets and counters
tCounter = 0;
p_stepLength(mf(mSolve, fSolve), t) = no;
ft(f,t) = no;
ft_dynamic(f,t) = no;
ft_full(f,t) = no;

// Build the forecast-time structure using the intervals
loop(counter${mInterval(mSolve, 'intervalLength', counter)},

    // Initialize tInterval
    tInterval(t) = no;

    // If intervalLength equals one, simply use all the steps within the interval
    if(mInterval(mSolve, 'intervalLength', counter) = 1,
        tInterval(t)${  ord(t) >= tSolveFirst + tCounter
                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                        } = yes; // Include all time steps within the interval
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');
        pt(t + 1)${tInterval(t)} = -1;

        // Determine the forecast-time steps
        ft(fCentral(fSolve), tInterval(t))${    ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                                } = yes; // Include the full horizon for the central forecast
        ft(fRealization(fSolve), tInterval(t))${    ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')
                                                    } = yes; // Include the t_jump for the realization
        ft(fSolve, tInterval(t))${  not fCentral(fSolve)
                                    and not fRealization(fSolve)
                                    and ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                    and ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    } = yes; // Include up to forecastLength for forecasts
        ft_dynamic(fSolve, t + 1)${ ft(fSolve, t)
                                    and tInterval(t)
                                    } = yes; // Displace ft_dynamic by 1 step
        ft_full(fSolve, t) = ft(fSolve, t) + ft_dynamic(fSolve, t);

        // Select time series data matching the intervals, for intervalLength = 1, this is trivial.
        ts_influx_(grid, node, ft_full(fSolve, t)) = ts_influx(grid, node, fSolve, t+ct(t));
        ts_cf_(flow, node, ft(fSolve, tInterval(t))) = ts_cf(flow, node, fSolve, t+ct(t));
        ts_unit_(unit, param_unit, ft(fSolve, tInterval(t))) = ts_unit(unit, param_unit, fSolve, t+ct(t));
        ts_reserveDemand_(restype, up_down, node, ft(fSolve, tInterval(t))) = ts_reserveDemand(restype, up_down, node, fSolve, t+ct(t));
        // nodeState uses ft_dynamic, requiring displacement
        ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, ft_full(fSolve, t)) = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));

    // If intervalLength exceeds 1 (intervalLength < 1 not defined)
    elseif mInterval(mSolve, 'intervalLength', counter) > 1,
        tInterval(t)${  ord(t) >= tSolveFirst + tCounter
                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                        and mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'intervalLength', counter)) = 0
                        } = yes;
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
        pt(t + mInterval(mSolve, 'intervalLength', counter))${tInterval(t)} = -mInterval(mSolve, 'intervalLength', counter);

        // Determine the forecast-time steps
        ft(fCentral(fSolve), tInterval(t))${    ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                                } = yes; // Include the full horizon for the central forecast
        ft(fRealization(fSolve), tInterval(t))${    ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')
                                                    } = yes; // Include the t_jump for the realization
        ft(fSolve, tInterval(t))${  not fCentral(fSolve)
                                    and not fRealization(fSolve)
                                    and ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                    and ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    } = yes; // Include up to forecastLength for forecasts
        ft_dynamic(fSolve, t + mInterval(mSolve, 'intervalLength', counter))${  ft(fSolve, t)
                                                                                and tInterval(t)
                                                                                } = yes; // Displace ft_dynamic by intervalLength
        ft_full(fSolve, t) = ft(fSolve, t) + ft_dynamic(fSolve, t);
$offOrder
        // Select and average time series data matching the intervals, for intervalLength > 1
        loop(ft(fSolve, tInterval(t)), // Loop over the t:s of the interval
            tt(t_) = no;
            tt(t_)${ord(t_) >= ord(t)
                    and ord(t_) < ord(t) + mInterval(mSolve, 'intervalLength', counter)
                    } = yes; // Select t:s within the interval
            ts_influx_(grid, node, fSolve, t) = sum(tt, ts_influx(grid, node, fSolve, tt+ct(tt))) / p_stepLength(mSolve, fSolve, t);
            ts_cf_(flow, node, fSolve, t) = sum(tt, ts_cf(flow, node, fSolve, tt+ct(tt))) / p_stepLength(mSolve, fSolve, t);
            ts_unit_(unit, param_unit, fSolve, t) = sum(tt, ts_unit(unit, param_unit, fSolve, tt+ct(tt))) / p_stepLength(mSolve, fSolve, t);
            ts_reserveDemand_(restype, up_down, node, fSolve, t) = sum(tt, ts_reserveDemand(restype, up_down, node, fSolve, tt+ct(tt))) / p_stepLength(mSolve, fSolve, t);
            // nodeState uses ft_dynamic, requiring displacement
            ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t + mInterval(mSolve, 'intervalLength', counter)) = sum(tt, ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, tt+ct(tt))) / p_stepLength(mSolve, fSolve, t);
        ); // END LOOP tInterval
$onOrder

    // Abort if intervalLength is less than one
    elseif mInterval(mSolve, 'intervalLength', counter) < 1, abort "intervalLength < 1 is not defined!"

    ); // END IF intervalLenght

    // Update tCounter for the next interval
    tCounter = mInterval(mSolve, 'intervalEnd', counter);

); // END LOOP COUNTER

* --- Determine various sets required for the model ---------------------------
// Set of realized time steps in the solve
ft_realized(f,t) = no;
ft_realized(ft_full(fRealization(f),t)) = yes;
ft_realizedLast(f,t) = no;
ft_realizedLast(ft_realized(f,t))${ ord(t) = tSolveFirst + mSettings(mSolve, 't_jump')
                                    } = yes;

// Set of locked forecast-time steps for the reserves
ft_nReserves(node, restype, f, t) = no;
ft_nReserves(node, restype, fRealization(f), t)${   p_nReserves(node, restype, 'update_frequency')
                                                    and p_nReserves(node, restype, 'gate_closure')
                                                    and ord(t) >= tSolveFirst
                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency'))
                                                    } = yes;

// Set of fixed time steps (necessary???)
*ft_fix(f,t) = no;
*ft_fix(ft(ft_realized)) = yes;

// Set of limited ft (necessary???)
*ft_limits(f,t) = no;
*ft_limits(f,t) = ft_full(f,t) + ft_realized(f,t);

// Current forecast displacement between realized and forecasted timesteps
cf(f,t) = no;
cf(ft(f,t))${   ord(t) = tSolveFirst + mSettings(mSolve, 't_jump')
                } = sum(f_${fRealization(f_)}, ord(f_) - ord(f));

// Previous forecast displacement between realized and forecasted timesteps
pf(f,t) = no;
pf(ft_dynamic(f,t))${   ord(t) = tSolveFirst + mSettings(mSolve, 't_jump') + 1
                        } = sum(f_${fRealization(f_)}, ord(f_)) - ord(f);

// Previous nodal forecast displacement between realized and forecasted timesteps, required for locking reserves ahead of (dispatch) time.
pf_nReserves(node, restype, f, t) = no;
pf_nReserves(node, restype, ft_dynamic(f, t))${ p_nReserves(node, restype, 'update_frequency')
                                                and p_nReserves(node, restype, 'gate_closure')
                                                and ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1 + mSettings(mSolve, 't_jump'), p_nReserves(node, restype, 'update_frequency')) + mSettings(mSolve, 't_jump')
                                                } = sum(f_${fRealization(f_)}, ord(f_) - ord(f));

// Current nodal forecast displacement between realized and forecasted timesteps, required for locking reserves ahead of (dispatch) time.
cf_nReserves(node, restype, f, t) = no;
cf_nReserves(node, restype, ft(f, t))${ p_nReserves(node, restype, 'update_frequency')
                                        and p_nReserves(node, restype, 'gate_closure')
                                        and ord(t) < tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1 + mSettings(mSolve, 't_jump'), p_nReserves(node, restype, 'update_frequency')) + mSettings(mSolve, 't_jump')
                                        } = sum(f_${fRealization(f_)}, ord(f_) - ord(f));

// Model ft
mft(mSolve, f, t) = no;
mft(mSolve, ft) = yes;

// Starting model ft
mftStart(mSolve, f, t) = no;
mftStart(mSolve, ft(fSolve, t))${   ord(t) = tSolveFirst
                                    } = yes;

// Last steps of model fts
mftLastSteps(mSolve, f, t) = no;
mftLastSteps(mSolve, ft_full(f,t))${ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')
                                    } = yes;
mftLastSteps(mSolve, ft_full(f,t))${ord(t) = tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    and not fCentral(f)
                                    and not fRealization(f)
                                    } = yes;

// Samples
msft(mSolve, s, f, t) = no;
msft(mSolve, 's000', f, t) = mft(mSolve,f,t);

// mft Binds (???)
*mftBind(mSolve,f,t) = no;
*mft_bind(mSolve,f,t) = no;
*mt_bind(mSolve,t) = no;
$ontext
// Connect the realization of the dispatch to the branches of the forecast tree
mftBind(mft(mSolve,f,t))$[ord(t) = tSolveFirst + tDispatchCurrent] = yes;
mft_bind(mft(mSolve,f,t))$[ord(t) = tSolveFirst + tDispatchCurrent] = 1 - ord(f);
mt_bind(mSolve,t)$[ord(t) = tSolveFirst + tDispatchCurrent] = 1;

// Connect branches of the forecast tree to the central forecast at the end of the forecast period
mftBind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = yes;
mft_bind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = sum(f_$(fCentral(f_)), ord(f_)) - ord(f);
mt_bind(mSolve,t)$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = -1;
$offtext
* --- Defining unit aggregations and ramps ------------------------------------

uft(unit, f, t) = no;
uft(unit, f, t)$[ ft(f, t)
                    and ord(t) <= tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                    and not unit_aggregate(unit)
                ] = yes;

uft(unit, f, t)$[ ft(f, t)
                    and ord(t) > tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                    and (unit_aggregate(unit) or unit_noAggregate(unit))
                ] = yes;

uft_limits(unit, f, t) = no;

nuft(node, unit, f, t) = no;
nuft(node, unit, f, t)$(nu(node, unit) and uft(unit, f, t)) = yes;

gnuft(grid, node, unit, f, t) = no;
gnuft_ramp(grid, node, unit, f, t) = no;
gnuft(grid, node, unit, f, t)$(gn(grid, node) and nuft(node, unit, f, t)) = yes;
gnuft_ramp(gnuft(grid, node, unit, f, t))${ p_gnu(grid, node, unit, 'maxRampUp')
                                            OR p_gnu(grid, node, unit, 'maxRampDown')
                                            OR p_gnu(grid, node, unit, 'rampUpCost')
                                            OR p_gnu(grid, node, unit, 'rampDownCost') } = yes;

// Defining unit efficiency groups etc.
suft(effGroup, unit, f, t) = no;
loop(effLevel$mSettingsEff(mSolve, effLevel),
    tInterval(t) = no;
    tInterval(t)$(ord(effLevel) = 1 and ord(t) = tSolveFirst) = yes;
    tInterval(t)$(     ord(t) >= tSolveFirst + mSettingsEff(mSolve, effLevel)
                   and ord(t) < tSolveFirst + mSettingsEff(mSolve, effLevel+1)
                 ) = yes;
    loop(effLevelGroupUnit(effLevel, effGroup, unit)$(not sum(flow$flowUnit(flow, unit), 1)),
        suft(effGroup, unit, f, tInterval(t))$(effLevelGroupUnit(effLevel, effGroup, unit) and uft(unit, f, tInterval)) = yes;
    );
);
sufts(effGroup, unit, f, t, effSelector) = no;
sufts(effGroup, unit, f, t, effSelector)$(effGroupSelector(effGroup, effSelector) and suft(effGroup, unit, f, t)) = yes;
uft_online(unit, f, t) = no; // Initialize the 'uft_online' set so that no units use online variables by default.
loop(suft(effOnline, uft(unit, f, t)), // Determine the time steps when units need to have online variables.
    uft_online(unit, f, t) = yes;
    p_uft_online_last(unit, f, t) = ord(t);
);

// Unit limits
$ontext
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
$offtext

* --- Probabilities -----------------------------------------------------------
// Clear probabilities from previous solve
p_sft_probability(sInitial(s), f, t) = 0;
p_sft_probability(s, f, t)$(sInitial(s) and ft(f,t)) = p_fProbability(f) / sum(f_$ft(f_,t), p_fProbability(f_));
p_sft_probability(s, f, t)$(sInitial(s) and fCentral(f) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')) = p_fProbability(f) / sum(f_$(fCentral(f_) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')), p_fProbability(f_));
p_sft_probability(s, f, t)$(sInitial(s) and ord(f) > 1 and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon') and mSettings(mSolve, 't_forecastLength') >= mSettings(mSolve, 't_horizon')) = p_fProbability(f) / sum(f_$ft_dynamic(f_,t), p_fProbability(f_));

* --- BEGIN OLD CODE ----------------------------------------------------------

loop(gn(grid, node),
    restypeDirectionNode(restypeDirection(restype, up_down), node)$(p_nReserves(node, restype, 'use_time_series') and sum((f,t), ts_reserveDemand(restype, up_down, node, f, t))) = yes;
    restypeDirectionNode(restypeDirection(restype, up_down), node)$(not p_nReserves(node, restype, 'use_time_series') and p_nReserves(node, restype, up_down)) = yes;
);

*$include 'defModels\periodicLoopDispatch.gms';

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
