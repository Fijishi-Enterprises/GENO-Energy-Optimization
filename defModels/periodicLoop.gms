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
                tCounter = mInterval(mSolve, 'intervalEnd', counter); // move tCounter to the next interval setting
                p_stepLength(mf(mSolve, fSolve), t)$tInterval(t) = 1;  // p_stepLength will hold the length of the interval in model equations
                p_stepLengthNoReset(mSolve, fSolve, t)$tInterval(t) = 1;
                pt(t + 1)$tInterval(t) = -1;
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
                            // Calculate averages for the interval time series data
                            ts_energyDemand_(gn(grid, node), fSolve, t) = sum{t_$tInterval(t_), ts_energyDemand(grid, node, fSolve, t_+ct(t_))};
                            ts_absolute_(node, fSolve, t) = sum{t_$tInterval(t_), ts_absolute(node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);
                            ts_cf_(flow, node, fSolve, t) = sum{t_$tInterval(t_), ts_cf(flow, node, fSolve, t_+ct(t_))} / p_stepLength(mSolve, fSolve, t);
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
    ft_full(f,t) = mftLastSteps(mSolve, f, t);
    loop(counter$mInterval(mSolve, 'intervalLength', counter),
        lastCounter = ord(counter);
    );
    loop(counter$(ord(counter) = lastCounter),
        ft_dynamic(f,t)$(mf(mSolve, f) and ord(t) = min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)) = yes;
    );
    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) >= ord(tSolve) and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;
    ft_realizedLast(f,t) = no;
    ft_realizedLast(f,t)$[fRealization(f) and ord(t) = ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;

    uft(unit, f, t) = no;
    uft(unit, f, t)$[ ft(f, t)
                        and ord(t) <= mSettings(mSolve, 't_aggregate')
                        and not unit_aggregate(unit)
                    ] = yes;

    uft(unit, f, t)$[ ft(f, t)
                        and ord(t) > mSettings(mSolve, 't_aggregate')
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



