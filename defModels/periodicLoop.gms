    tSolveOrd = ord(tSolve);
    tElapsed = tSolveOrd - mSettings(mSolve, 't_start');
    tLast = tElapsed + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));
    p_stepLength(mSolve, f, t) = no;

    // Set intervals, if there is interval data for the model
    if(sum(counter, mInterval(mSolve, 'intervalLength', counter)),
        tCounter = 1;
        loop(counter$mInterval(mSolve, 'intervalLength', counter),
            loop(t$[ord(t) >= tElapsed + tCounter and ord(t) <= min(tElapsed + mInterval(mSolve, 'intervalEnd', counter), tLast)],
                if (not mod(tCounter-1, mInterval(mSolve, 'intervalLength', counter)),
                    p_stepLength(mSolve, f, t)$mf(mSolve, f) = mInterval(mSolve, 'intervalLength', counter);
                    if (mInterval(mSolve, 'intervalLength', counter) = 1,
                        ts_energyDemand_(eg(etype, geo), f, t)$mf(mSolve,f) = ts_energyDemand(etype, geo, f, t);
                        ts_inflow_(unitHydro, f, t)$mf(mSolve,f) = ts_inflow(unitHydro, f, t);
                        ts_inflow_(storageHydro, f, t)$mf(mSolve,f) = ts_inflow(storageHydro, f, t);
                        ts_import_(eg(etype, geo), t) = ts_import(etype, geo, t);
                        ts_cf_(flow, geo, f, t)$mf(mSolve,f) = ts_cf(flow, geo, f, t);
                    );
                    if (mInterval(mSolve, 'intervalLength', counter) > 1,
                        ts_energyDemand_(eg(etype, geo), f, t)$mf(mSolve,f) =
                            sum{t_$[ ord(t_) >= tElapsed + tCounter
                                     and ord(t_) < tElapsed + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                   ], ts_energyDemand(etype, geo, f, t_)} / p_stepLength(mSolve, f, t);
                        ts_inflow_(unitHydro, f, t)$mf(mSolve,f) =
                            sum{t_$[ ord(t_) >= tElapsed + tCounter
                                     and ord(t_) < tElapsed + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                   ], ts_inflow(unitHydro, f, t_)} / p_stepLength(mSolve, f, t);
                        ts_inflow_(storageHydro, f, t)$mf(mSolve,f) =
                            sum{t_$[ ord(t_) >= tElapsed + tCounter
                                     and ord(t_) < tElapsed + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                   ], ts_inflow(storageHydro, f, t_)} / p_stepLength(mSolve, f, t);
                        ts_import_(eg(etype, geo), t) =
                            sum{t_$[ ord(t_) >= tElapsed + tCounter
                                     and ord(t_) < tElapsed + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                   ], ts_import(etype, geo, t_)} / sum(f$fRealization(f), p_stepLength(mSolve, f, t));
                        ts_cf_(flow, geo, f, t)$mf(mSolve,f) =
                            sum{t_$[ ord(t_) >= tElapsed + tCounter
                                     and ord(t_) < tElapsed + tCounter + mInterval(mSolve, 'intervalLength', counter)
                                   ], ts_cf(flow, geo, f, t_)} / p_stepLength(mSolve, f, t);
                    );
                    if ( mInterval(mSolve, 'intervalEnd', counter) <= mSettings(mSolve, 't_forecastLength'),
                        mftLastForecast(mSolve,f,t_) = no;
                        mftLastForecast(mSolve,f,t)$[mf(mSolve,f) and ord(t) = tElapsed + tCounter] = yes;
                    );
                    if ( mInterval(mSolve, 'intervalEnd', counter) <= tLast,
                        mftLastSteps(mSolve,f,t_) = no;
                        mftLastSteps(mSolve,f,t)$[mf(mSolve,f) and ord(t) = tElapsed + tCounter] = yes;
                    );
                    pt(t + mInterval(mSolve, 'intervalLength', counter)) = -mInterval(mSolve, 'intervalLength', counter);
                );
                tCounter = tCounter + 1;
            )
        )
    else
    // ...otherwise use all time periods with equal weight
        p_stepLength(mSolve, f, t)$(ord(t) >= tElapsed and ord(t) < tLast and fRealization(f)) = 1;
    );

    // Set mft for the modelling period and model forecasts
    mft(mSolve,f,t) = no;
    mft(mSolve, f, t)$( p_stepLength(mSolve, f, t) and ord(t) < tElapsed + mSettings(mSolve, 't_forecastLength' ) ) = yes;
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
    ft_dynamic(f,t)$(ord(t) = tSolveOrd) = no;
    loop(counter$mInterval(mSolve, 'intervalLength', counter),
        lastCounter = ord(counter);
    );
    loop(counter$(ord(counter) = lastCounter),
        ft_dynamic(f,t)$(mf(mSolve, f) and ord(t) = min(tElapsed + mInterval(mSolve, 'intervalEnd', counter), tLast)) = yes;
    );
    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) = ord(tSolve)] = yes;
    pf(ft(f,t))$(ord(t) eq ord(tSolve) + 1) = 1 - ord(f);

    // Arbitrary value for energy in storage
    p_storageValue(egs(etype, geo, storage), t)$sum(fRealization(f), ft(f,t)) = 50;
    // PSEUDO DATA
    ts_reserveDemand_(resType, resDirection, bus, fRealization(f), t) = 50;
