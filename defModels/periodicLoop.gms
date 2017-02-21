    fSolve(f) = no;
    fSolve(f)$mf(mSolve,f) = yes;

    tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve
    tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
    p_stepLength(mSolve, f, t) = no;
    ft_new(f,t) = no;

$offOrder
    // Calculate parameters affected by model intervals
    if(sum(counter, mInterval(mSolve, 'intervalLength', counter)),  // But only if interval data has been set in the model definition file
        tCounter = 0;
        loop(counter$mInterval(mSolve, 'intervalLength', counter),  // Loop through all the different intervals set in the model definition file
            if (mInterval(mSolve, 'intervalLength', counter) = 1,  // Calculations are not needed if the time interval has the same length as original data
                tInterval(t) = no;
                tInterval(t)$(    ord(t) >= tSolveFirst + tCounter
                           and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast + 1)
                ) = yes;   // Set of t's where the interval is 1 (right border defined by intervalEnd) - but do not go beyond tSolveLast
                ts_energyDemand_(gn(grid, node), fSolve, t)$tInterval(t) = ts_energyDemand(grid, node, fSolve, t+ct(t));
                ts_absolute_(node, fSolve, t)$tInterval(t) = ts_absolute(node, fSolve, t+ct(t));
                ts_cf_(flow, node, fSolve, t)$tInterval(t) = ts_cf(flow, node, fSolve, t+ct(t));
                ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t)$tInterval(t) = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));
                ts_unit_(unit, param_nu, fSolve, t)$tInterval(t) = ts_unit(unit, param_nu, fSolve, t+ct(t));
                tCounter = mInterval(mSolve, 'intervalEnd', counter); // move tCounter to the next interval setting
                p_stepLength(mf(mSolve, fSolve), t)$tInterval(t) = 1;  // p_stepLength will hold the length of the interval in model equations
                p_stepLengthNoReset(mSolve, fSolve, t)$tInterval(t) = 1;
                pt(t + 1)$tInterval(t) = -1;
                mftLastSteps(mf(mSolve,fSolve),t)$[ord(t)-1 = mInterval(mSolve,'intervalEnd',counter)] = yes;
            elseif mInterval(mSolve, 'intervalLength', counter) > 1, // intervalLength > 1 (not defined if intervalLength < 1)
                loop(t$[ord(t) >= tSolveFirst + tCounter and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast + 1)],  // Loop t relevant for each interval (interval borders defined by intervalEnd) - but do not go beyond tSolveLast
                    if (not mod(tCounter - mInterval(mSolve, 'intervalEnd', counter), mInterval(mSolve, 'intervalLength', counter)),  // Skip those t's that are not at the start of any interval
                        intervalLength = min(mInterval(mSolve, 'intervalLength', counter), max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon')) - tCounter);
                        p_stepLength(mf(mSolve, fSolve), t) = intervalLength;  // p_stepLength will hold the length of the interval in model equations
                        if (p_stepLengthNoReset(mSolve, 'f00', t) <> mInterval(mSolve, 'intervalLength', counter),  // and skip those t's that have been calculated for the right interval previously
                            tInterval(t_) = no;
                            tInterval(t_)$(    ord(t_) >= ord(t)
                                           and ord(t_) < ord(t) + intervalLength
                            ) = yes;   // Set of t's within the interval (right border defined by intervalEnd) - but do not go beyond tSolveLast
                            ft_new(f,t_)$(mf(mSolve, f) and tInterval(t_)) = yes;
                            p_stepLengthNoReset(mf(mSolve, fSolve), t) = intervalLength;
                            // Aggregates the interval time series data by averaging the power data
                            ts_energyDemand_(gn(grid, node), fSolve, t) = sum{t_$tInterval(t_), ts_energyDemand(grid, node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);    // Averages the power demand over the interval
                            ts_absolute_(node, fSolve, t) = sum{t_$tInterval(t_), ts_absolute(node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);  // Averages the absolute power terms over the interval
                            ts_cf_(flow, node, fSolve, t) = sum{t_$tInterval(t_), ts_cf(flow, node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);  // Averages the capacity factor over the inverval
                            ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t) = sum(t_${tInterval(t_)}, ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t_+ct(t_))) / p_stepLength(mSolve, fSolve, t); // Averages the time-dependent node state boundary conditions over the interval
                            ts_unit_(unit, param_nu, fSolve, t) = sum(t_${tInterval(t_)}, ts_unit(unit, param_nu, fSolve, t_+ct(t_))) / p_steplength(mSolve, fSolve, t); // Averages the time-dependent unit parameters over the interval
                            // Set the previous time step displacement
                            pt(t+intervalLength) = -intervalLength;
                        );
                        if (mInterval(mSolve, 'intervalEnd', counter) <= mSettings(mSolve, 't_forecastLength'),
                             mftLastForecast(mf(mSolve,fSolve),t_) = no;
                             mftLastForecast(mf(mSolve,fSolve),t)$[ord(t) = tSolveFirst + tCounter] = yes;
                        );
                        if (mInterval(mSolve, 'intervalEnd', counter) <= tSolveLast,
                             mftLastSteps(mf(mSolve,fSolve),t_) = no;
                             mftLastSteps(mf(mSolve,fSolve),t+intervalLength)$[ord(t) = tSolveFirst + tCounter] = yes;
                        );
                    );  // end if that skips t's not at the start of any interval
                    tCounter = tCounter + 1;
                ); // end loop t
            ) // end if ... elseif
        ) // end loop for set intervals
    else
    // ...otherwise use all time periods with equal weight
        p_stepLength(mSolve, f, t)$(ord(t) >= tSolveFirst and ord(t) < tSolveLast and fRealization(f)) = 1;
    );
    // Determine the time-series values for the last time step of the simulation, necessary for the state variables due to different indexing... NOTE! Doesn't aggregate in any way, uses raw data
    ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t)${ord(t) = tSolveLast} = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_energyDemand_(gn(grid, node), fSolve, t)${ord(t) = tSolveLast} = ts_energyDemand(grid, node, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_absolute_(node, fSolve, t)${ord(t) = tSolveLast} = ts_absolute(node, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_cf_(flow, node, fSolve, t)${ord(t) = tSolveLast} = ts_cf(flow, node, fSolve, t+ct(t));
    $$ifi '%rampSched%' == 'yes' ts_unit_(unit, param_nu, fSolve, t)${ord(t) = tSolveLast} = ts_unit(unit, param_nu, fSolve, t+ct(t));
$onOrder

    // Set mft for the modelling period and model forecasts
    mft(mSolve,f,t) = no;
    mft(mSolve, f, t)$( p_stepLength(mSolve, f, t) and ord(t) < tSolveFirst + mSettings(mSolve, 't_horizon' ) ) = yes;
*    mft(mSolve, f, t)${ [ord(t) >= ord(tSolve)]
*                         $$ifi     '%rampSched%' == 'yes' and [ord(t) <=
*                         $$ifi not '%rampSched%' == 'yes' and [ord(t) <
*                            ord(tSolve) + mSettings(mSolve, 't_forecastLength')]
*                         and mf(mSolve, f)
*                       } = yes;
    mftStart(mSolve,f,t) = no;
    mftStart(mSolve,fRealization,t)$[ord(t) = ord(tSolve)] = yes;
    mftBind(mSolve,f,t) = no;
    mft_bind(mSolve,f,t) = no;
    mt_bind(mSolve,t) = no;
*    mftBind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = yes;
*    mft_bind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = 1 - ord(f);
*    mt_bind(mSolve,t)$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = -1;
    msft(mSolve, s, f, t) = no;
    msft(mSolve, 's000', f, t) = mft(mSolve,f,t);
    msft(mSolve, 's000', fRealization(f), t)${ [ord(t) >= ord(tSolve) + mSettings(mSolve, 't_forecastLength')]
                             $$ifi     '%rampSched%' == 'yes' and [ord(t) <=
                             $$ifi not '%rampSched%' == 'yes' and [ord(t) <
                                ord(tSolve) + mSettings(mSolve, 't_horizon')]
                             and mf(mSolve, f)
                           } = yes;
    ft(f,t) = no;
    ft(f,t) = mft(mSolve, f, t);
    ft_dynamic(f,t) = ft(f,t);
    ft_dynamic(f,tSolve) = no;
    ft_full(f,t) = no;
    ft_full(f,t) = ft(f,t);
    loop(counter$mInterval(mSolve, 'intervalLength', counter),
        lastCounter = ord(counter);
    );
    loop(counter$(ord(counter) = lastCounter),
        ft_dynamic(f,t)$(mf(mSolve, f) and ord(t) = min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)) = yes;
        ft_full(f,t)$   (mf(mSolve, f) and ord(t) = min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)) = yes;
    );
    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) >= ord(tSolve) and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;
    ft_realizedLast(f,t) = no;
    ft_realizedLast(f,t)$[fRealization(f) and ord(t) = ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;

    // Defining unit aggregations
    uft(unit, f, t) = no;
    uft(unit, f, t)$[ ft(f, t)
                        and ord(t) <= tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                        and not unit_aggregate(unit)
                    ] = yes;

    uft(unit, f, t)$[ ft(f, t)
                        and ord(t) > tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                        and (unit_aggregate(unit) or unit_noAggregate(unit))
                    ] = yes;

    nuft(node, unit, f, t) = no;
    nuft(node, unit, f, t)$(nu(node, unit) and uft(unit, f, t)) = yes;

    gnuft(grid, node, unit, f, t) = no;
    gnuft(grid, node, unit, f, t)$(gn(grid, node) and nuft(node, unit, f, t)) = yes;

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

    pf(ft(f,t))$(ord(t) eq ord(tSolve) + 1) = 1 - ord(f);

// Calculate time series for unit parameters when necessary and/or possible
loop(unit${p_unit(unit, 'useTimeseries')},
//    cum_lambda = 0;
//    cum_slope = 0;
    loop(effLevel${mSettingsEff(mSolve, effLevel)},
        // Calculate time series for unit parameters using direct input output conversion with online variable
        loop(effSelector$sum(effDirectOn$effGroupSelector(effDirectOn, effSelector), 1),
            ts_effUnit(effSelector, unit, 'lb', ft(f, t))$ts_unit_(unit, 'rb00', f, t) = ts_unit_(unit, 'rb00', f, t);
            ts_effUnit(effSelector, unit, 'rb', ft(f, t))$ts_unit_(unit, 'rb01', f, t) = ts_unit_(unit, 'rb01', f, t);
//            ts_effUnit(effSelector, unit, 'section', ft(f, t))$(not ts_unit(unit, 'eff01')) = 0;
//            ts_effUnit(effSelector, unit, 'slope')$(not p_unit(unit, 'eff01')) = 1 / p_unit(unit, 'eff00');
            ts_effUnit(effSelector, unit, 'section', ft(f, t))$ts_unit_(unit, 'eff01', f, t) =
              + 1 / ts_unit_(unit, 'eff01', f, t)
              - [p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f, t)} + ts_unit_(unit, 'rb01', f, t) - 0]
                  / [p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f, t)} + ts_unit_(unit, 'rb01', f, t)
                        - p_unit(unit, 'rb00')${not ts_unit_(unit, 'rb00', f, t)} - ts_unit_(unit, 'rb00', f, t)]
                  * [(p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f, t)} + ts_unit_(unit, 'rb01', f, t))
                        / (p_unit(unit, 'eff01')${not ts_unit_(unit, 'eff01', f, t)} + ts_unit_(unit, 'eff01', f, t))
                        - (p_unit(unit, 'rb00')${not ts_unit_(unit, 'rb00', f, t)} + ts_unit_(unit, 'rb00', f, t))
                        / (p_unit(unit, 'eff00')${not ts_unit_(unit, 'eff00', f, t)} + ts_unit_(unit, 'eff00', f, t))];
            ts_effUnit(effSelector, unit, 'slope', ft(f, t))$ts_unit_(unit, 'eff01', f, t) =
              + 1 / ts_unit_(unit, 'eff01', f, t) - ts_effUnit(effSelector, unit, 'section', f, t);
        );

        // Calculate time series for unit parameters using direct input output conversion without online variable
        loop(effSelector$sum(effDirectOff$effGroupSelector(effDirectOff, effSelector), 1),
//            p_effUnit(effSelector, unit, 'rb') = 1;
//            p_effUnit(effSelector, unit, 'lb') = 0;
//            p_effUnit(effSelector, unit, 'section')$(not p_unit(unit, 'eff01')) = 0;
            ts_effUnit(effSelector, unit, 'slope', ft(f, t))${ts_unit_(unit, 'eff00', f, t)} = 1 / ts_unit_(unit, 'eff00', f, t);
//            p_effUnit(effSelector, unit, 'section')${p_unit(unit, 'eff01')} = 0;
            ts_effUnit(effSelector, unit, 'slope', ft(f, t))${ts_unit_(unit, 'eff01', f, t)} = 1 / ts_unit_(unit, 'eff01', f, t);
        );

        // Make calculations for different parts of the piecewise curve in the case of using slope
        count_slope2 = 0;
        loop(effSelector$(effSlope(effSelector) and effLevelSelectorUnit(effLevel, effSelector, unit)),
            ts_effUnit(effSelector, unit, 'rb', ft(f, t))${ts_unit_(unit, 'rb00', f, t) OR ts_unit_(unit, 'rb01', f, t)} =
                + ((count_slope - count_slope2 - 1) * (p_unit(unit, 'rb00')${not ts_unit_(unit, 'rb00', f, t)} + ts_unit_(unit, 'rb00', f, t))
                    + (count_slope2 + 1) * (p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f, t)} + ts_unit_(unit, 'rb01', f, t)))
                / count_slope;
            ts_effUnit(effSelector, unit, 'lb', ft(f, t))${ts_unit_(unit, 'rb00', f, t) OR ts_unit_(unit, 'rb01', f, t)} =
                + ((count_slope - count_slope2) * (p_unit(unit, 'rb00')${not ts_unit_(unit, 'rb00', f, t)} + ts_unit_(unit, 'rb00', f, t))
                    + count_slope2 * (p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f, t)} + ts_unit_(unit, 'rb01', f, t)))
                / count_slope;
            //if(count_slope2 = 0,
                //p_effUnit(effSelector, unit, 'slope') = ((count_slope-1 - count_slope2) * (1 / p_unit(unit, 'eff00')) + count_slope2 * (1 / p_unit(unit, 'eff01'))) / (count_slope - 1);
                //tmp = p_effUnit(effSelector, unit, 'slope');
            //else
                ts_effUnit(effSelector, unit, 'slope', ft(f, t))${ts_unit_(unit, 'eff00', f, t) OR ts_unit_(unit, 'eff01', f, t)} =
                    + ((count_slope-1 - count_slope2) * (1 / (p_unit(unit, 'eff00')${not ts_unit_(unit, 'eff00', f, t)} + ts_unit_(unit, 'eff00', f, t)))
                        + (count_slope2 + 1) * (1 / (p_unit(unit, 'eff01')${not ts_unit_(unit, 'eff01', f, t)} + ts_unit_(unit, 'eff01', f, t))))
                    / count_slope;
            //        - tmp;
            //);
            count_slope2 = count_slope2 + 1;
        );

        // Calculate lambdas
        count_lambda2 = 0;
        loop(effSelector$(effLambda(effSelector) and effLevelSelectorUnit(effLevel, effSelector, unit)),
            ts_effUnit(effSelector, unit, 'rb', ft(f, t))${ts_unit_(unit, 'rb00', f, t) OR ts_unit_(unit, 'rb01', f, t)} =
                + ((count_lambda-1 - count_lambda2) * (p_unit(unit, 'rb00')${not ts_unit_(unit, 'rb00', f, t)} + ts_unit_(unit, 'rb00', f, t))
                    + count_lambda2 * (p_unit(unit, 'rb01')${not ts_unit_(unit, 'rb01', f ,t)} + ts_unit_(unit, 'rb01', f, t)))
                / (count_lambda - 1);
            //no lb for lambdas, since number of borders same as number of slopes   p_effUnit(effSelector, unit, 'lb') = ((count_lambda-1 - count_lambda2 + 1) * p_unit(unit, 'rb00') + (count_lambda2 - 1) * p_unit(unit, 'rb01')) / (count_lambda - 1);
            ts_effUnit(effSelector, unit, 'slope', ft(f, t))${effLevelSelectorUnit(effLevel, effSelector, unit) AND (ts_unit_(unit, 'eff00', f, t) OR ts_unit_(unit, 'eff01', f, t))} =
                + ((count_lambda-1 - count_lambda2) * (1 / (p_unit(unit, 'eff00')${not ts_unit_(unit, 'eff00', f, t)} + ts_unit_(unit, 'eff00', f, t)))
                    + count_lambda2 * (1 / (p_unit(unit, 'eff01')${not ts_unit_(unit, 'eff01', f, t)} + ts_unit_(unit, 'eff01', f, t))))
                / (count_lambda - 1);
            count_lambda2 = count_lambda2 + 1;
        );

    );
);


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel${mSettingsEff(mSolve, effLevel)},
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            ts_effGroupUnit(effGroup, unit, 'rb', ft(f, t))${sum(effSelector, ts_effUnit(effSelector, unit, 'rb', f, t))} = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effSelector, unit, 'rb', f, t));
            ts_effGroupUnit(effGroup, unit, 'lb', ft(f, t))${sum(effSelector, ts_effUnit(effSelector, unit, 'lb', f, t))} = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effSelector, unit, 'lb', f, t));
        );
    );
);

