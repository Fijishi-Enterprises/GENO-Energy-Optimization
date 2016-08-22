    tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve
    tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
//    tElapsed = tSolveFirst - mSettings(mSolve, 't_start');  // tElapsed counts the starting point for current model solve
//    tLast = tElapsed + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));
    p_stepLength(mSolve, f, t) = no;

    // Calculate parameters affected by model intervals
    if(sum(counter, mInterval(mSolve, 'intervalLength', counter)),  // But only if interval data has been set in the model definition file
        tCounter = 0;
        loop(counter$mInterval(mSolve, 'intervalLength', counter),  // Loop thorough all the different intervals set in the model definition file
            loop(t$[ord(t) >= tSolveFirst + tCounter and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast + 1)],  // Loop t relevant for each interval (interval borders defined by intervalEnd) - but do not go beyond tSolveLast
                if (not mod(tCounter, mInterval(mSolve, 'intervalLength', counter)),  // Skip those t's that are not at the start of any interval
                    p_stepLength(mSolve, f, t)$mf(mSolve, f) = mInterval(mSolve, 'intervalLength', counter);  // p_stepLength will hold the length of the interval in model equations
                    if (p_stepLengthNoReset(mSolve, 'f00', t) <> mInterval(mSolve, 'intervalLength', counter),  // and skip those t's that have been calculated for the right interval previously
                        p_stepLengthNoReset(mSolve, 'f00', t) = mInterval(mSolve, 'intervalLength', counter);
                        if (mInterval(mSolve, 'intervalLength', counter) = 1,  // Calculations are not needed if the time interval has the same length as original data
                            ts_energyDemand_(gn(grid, node), f, t)$mf(mSolve,f) = ts_energyDemand(grid, node, f, t);
                            ts_inflow_(unitHydro, f, t)$mf(mSolve,f) = ts_inflow(unitHydro, f, t);
                            ts_inflow_(storageHydro, f, t)$mf(mSolve,f) = ts_inflow(storageHydro, f, t);
                            ts_import_(gn(grid, node), t) = ts_import(grid, node, t);
                            ts_cf_(flow, node, f, t)$mf(mSolve,f) = ts_cf(flow, node, f, t);
                        );
                        if (mInterval(mSolve, 'intervalLength', counter) > 1, // Calculate averages for the interval time series data
                            ts_energyDemand_(gn(grid, node), f, t)$mf(mSolve,f) =
                                sum{t_$[ ord(t_) >= tSolveFirst + tCounter
                                         and ord(t_) < tSolveFirst + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                       ], ts_energyDemand(grid, node, f, t_)};
                            ts_inflow_(unitHydro, f, t)$mf(mSolve,f) =
                                sum{t_$[ ord(t_) >= tSolveFirst + tCounter
                                         and ord(t_) < tSolveFirst + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                       ], ts_inflow(unitHydro, f, t_)} / p_stepLength(mSolve, f, t);
                            ts_inflow_(storageHydro, f, t)$mf(mSolve,f) =
                                sum{t_$[ ord(t_) >= tSolveFirst + tCounter
                                         and ord(t_) < tSolveFirst + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                       ], ts_inflow(storageHydro, f, t_)};
                            ts_import_(gn(grid, node), t) =
                                sum{t_$[ ord(t_) >= tSolveFirst + tCounter
                                         and ord(t_) < tSolveFirst + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                       ], ts_import(grid, node, t_)};
                            ts_cf_(flow, node, f, t)$mf(mSolve,f) =
                                sum{t_$[ ord(t_) >= tSolveFirst + tCounter
                                         and ord(t_) < tSolveFirst + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                       ], ts_cf(flow, node, f, t_)} / p_stepLength(mSolve, f, t);
                        );
                        if ( mInterval(mSolve, 'intervalEnd', counter) <= mSettings(mSolve, 't_forecastLength'),
                            mftLastForecast(mSolve,f,t_) = no;
                            mftLastForecast(mSolve,f,t)$[mf(mSolve,f) and ord(t) = tSolveFirst + tCounter] = yes;
                        );
                        if ( mInterval(mSolve, 'intervalEnd', counter) <= tSolveLast,
                            mftLastSteps(mSolve,f,t_) = no;
                            mftLastSteps(mSolve,f,t)$[mf(mSolve,f) and ord(t) = tSolveFirst + tCounter] = yes;
                        );
                        pt(t + mInterval(mSolve, 'intervalLength', counter)) = -mInterval(mSolve, 'intervalLength', counter);
                    );
                );
                tCounter = tCounter + 1;
            )
        )
    else
    // ...otherwise use all time periods with equal weight
        p_stepLength(mSolve, f, t)$(ord(t) >= tSolveFirst and ord(t) < tSolveLast and fRealization(f)) = 1;
    );

    // Set mft for the modelling period and model forecasts
    mft(mSolve,f,t) = no;
    mft(mSolve, f, t)$( p_stepLength(mSolve, f, t) and ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength' ) ) = yes;
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
    ft_dynamic(f,t)$(ord(t) = tSolveFirst) = no;
    loop(counter$mInterval(mSolve, 'intervalLength', counter),
        lastCounter = ord(counter);
    );
    loop(counter$(ord(counter) = lastCounter),
        ft_dynamic(f,t)$(mf(mSolve, f) and ord(t) = min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)) = yes;
    );
    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) = ord(tSolve)] = yes;
    pf(ft(f,t))$(ord(t) eq ord(tSolve) + 1) = 1 - ord(f);

    // Arbitrary value for energy in storage
    p_storageValue(gns(grid, node, storage), t)$sum(fRealization(f), ft(f,t)) = 50;


    // PSEUDO DATA
    ts_reserveDemand_(resType, resDirection, node, fRealization(f), t) = 50;
