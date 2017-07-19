    // Set mft for the modelling period and model forecasts
    mft(mSolve,f,t) = no;
    mft(mSolve, f, t)$( p_stepLength(mSolve, f, t) and ord(t) < tSolveFirst + mSettings(mSolve, 't_horizon') and
        {
            [ ord(f) = 1 and ord(t) = tSolveFirst + tDispatchCurrent - 1]
              or
            [ ord(f) > 1 and ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength') and ord(t) >= tSolveFirst + tDispatchCurrent ]
              or
            [ fCentral(f) and ord(t) > tSolveFirst + mSettings(mSolve, 't_forecastLength') ]
        } ) = yes;
*    mft(mSolve, f, t)${ [ord(t) >= ord(tSolve)]
*                         $$ifi     '%rampSched%' == 'yes' and [ord(t) <=
*                         $$ifi not '%rampSched%' == 'yes' and [ord(t) <
*                            ord(tSolve) + mSettings(mSolve, 't_forecastLength')]
*                         and mf(mSolve, f)
*                       } = yes;
    mftStart(mSolve,f,t) = no;
    mftStart(mSolve,f,t)${ tDispatchCurrent = 0 and fSolve(f) and ord(f) > 1 and ord(t) = tSolveFirst + tDispatchCurrent} = yes;
    mftStart(mSolve,f,t)${ tDispatchCurrent >= 1 and ord(f) = 1 and ord(t) = tSolveFirst + tDispatchCurrent - 1} = yes;
    //mftStart(mSolve,fRealization,t)$[ord(t) = ord(tSolve)] = yes;
    mftBind(mSolve,f,t) = no;
    mft_bind(mSolve,f,t) = no;
    mt_bind(mSolve,t) = no;

    // Connect the realization of the dispatch to the branches of the forecast tree
    mftBind(mft(mSolve,f,t))$[ord(t) = tSolveFirst + tDispatchCurrent] = yes;
    mft_bind(mft(mSolve,f,t))$[ord(t) = tSolveFirst + tDispatchCurrent] = 1 - ord(f);
    mt_bind(mSolve,t)$[ord(t) = tSolveFirst + tDispatchCurrent] = 1;

    // Connect branches of the forecast tree to the central forecast at the end of the forecast period
    mftBind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = yes;
    mft_bind(mft(mSolve,f,t))$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = sum(f_$(fCentral(f_)), ord(f_)) - ord(f);
    mt_bind(mSolve,t)$[ord(t) = ord(tSolve) + mSettings(mSolve, 't_forecastLength')] = -1;

    msft(mSolve, s, f, t) = no;
    msft(mSolve, 's000', f, t) = mft(mSolve,f,t);
*    msft(mSolve, 's000', fRealization(f), t)${ [ord(t) >= ord(tSolve) + mSettings(mSolve, 't_forecastLength')]
*                             $$ifi     '%rampSched%' == 'yes' and [ord(t) <=
*                             $$ifi not '%rampSched%' == 'yes' and [ord(t) <
*                                ord(tSolve) + mSettings(mSolve, 't_horizon')]
*                             and mf(mSolve, f)
*                           } = yes;
    ft(f,t) = no;
    ft(f,t) = mft(mSolve, f, t);
    ft_dynamic(f,t) = no;
    ft_dynamic(f,t) = ft(f,t);
    //fft_dynamic(f,f_,t) = no;
    //fft_dynamic(f,f_,t)$(ord(f) = ord(f_) and ft(f,t) and [ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength') + 1 or ord(t) > tSolveFirst + mSettings(mSolve, 't_forecastLength') + 1]) = yes;
    //fft_dynamic(f,f_,t)$(ord(f_) > 1 and mf(mSolve, f_) and ft(f,t) and ord(t) = tSolveFirst + mSettings(mSolve, 't_forecastLength') + 1) = yes;
    //fft_dynamic(f,f_,tSolve+tDispatchCurrent) = no;
    continueLoop = 1;
    cf(f,t) = no;
    loop(t$(ord(t) > tSolveFirst + mSettings(mSolve,'t_forecastLength') and continueLoop),  // Loop through all the different intervals set in the model definition file
        if(sum(f,p_stepLength(mSolve,f,t)),
            ft_dynamic(f,t)$(ord(f) > 1) = yes;
            cf(ft_dynamic(f,t)) = sum(f_$(fCentral(f_)), ord(f_)) - ord(f);
            continueLoop = 0;
        );
    );
    ft_dynamic(f,tSolve+max(0,(tDispatchCurrent -1))) = no;
    //ft_dynamic('f00',tSolve+(tDispatchCurrent-1))$(tDispatchCurrent > 1 or (tSolveFirst > 1 and tDispatchCurrent > 0)) = yes;
    ft_dynamic('f00',tSolve+(tDispatchCurrent))$(tDispatchCurrent > 0) = yes;
    //ft_dynamic(f,tSolve)$(tSolveFirst > 0 and tDispatchCurrent = 0 and ord(f) > 1) = yes;
    ft_dynamic(f,t)$(ord(f) = sum(f_$(fCentral(f_)), ord(f_)) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')) = yes;
    ft_full(f,t) = no;
    ft_full(f,t) = ft(f,t) + ft_dynamic(f,t);

    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) >= ord(tSolve) and ord(t) < ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;
    ft_realizedLast(f,t) = no;
    ft_realizedLast(f,t)$[fRealization(f) and ord(t) = ord(tSolve) + mSettings(mSolve, 't_jump') - 1] = yes;

    ft_fix(f,t) = no;
    ft_fix(f,tSolve + tDispatchCurrent) = yes;

    // Defining unit aggregations and ramps
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

    pf(f,t) = no;
    pf(ft(f,t))$(ord(t) eq ord(tSolve) + tDispatchCurrent) = 1 - ord(f);

    p_sft_probability(s, f, t)$(sInitial(s) and ft(f,t)) = p_fProbability(f) / sum(f_$ft(f_,t), p_fProbability(f_));
    p_sft_probability(s, f, t)$(sInitial(s) and fCentral(f) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')) = p_fProbability(f) / sum(f_$(fCentral(f_) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')), p_fProbability(f_));

$offOrder
    loop(counter$mInterval(mSolve, 'intervalLength', counter),  // Loop through all the different intervals set in the model definition file
        if (mSettings(mSolve, 't_horizon') > mInterval(mSolve, 'intervalEnd', counter-1) and mSettings(mSolve, 't_horizon') <= mInterval(mSolve, 'intervalEnd', counter) ,
            mftLastSteps(mf(mSolve,fSolve),t) = no;
            if (mInterval(mSolve, 'intervalEnd', counter) <= mSettings(mSolve, 't_forecastLength'),
                mftLastSteps(mf(mSolve,fSolve),t)$[ord(fSolve) > 1 and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')] = yes;
                mftLastForecast(mf(mSolve,fSolve),t) = no;
                mftLastForecast(mf(mSolve,fSolve),t)$[ord(fSolve) > 1 and ord(t) = tSolveFirst + mSettings(mSolve, 't_forecastLength')] = yes;
            else
                mftLastSteps(mf(mSolve,fSolve),t)$[fCentral(fSolve) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')] = yes;
            );
        );
    );
$onOrder;


// Rough approximation
$ontext
loop(m,
    ts_reserveDemand_(restypeDirection('tertiary', 'up'), node, ft(f, t))$[     gn('elec', node)
                                                           and ord(t) >= tSolveFirst and ord(t) <= tSolveFirst + mSettings(m, 't_reserveLength')
                                                           and mf(m, f)
                                                         ] = max(p_nReserves(node, 'tertiary', 'up'),
                                                                 sqrt{sum((grid, flowUnit(flow, unit_flow), fCentral)$(gnu(grid, node, unit_flow)),
                                                                       { ts_cf_(flow, node, fCentral, t)
                                                                         * p_gnu(grid, node, unit_flow, 'maxGen')
                                                                         * p_unit(unit_flow, 'availability')
                                                                         * 0.2
                                                                       }
                                                                      ) ** 2 }
                                                             );
    ts_reserveDemand_(restypeDirection('tertiary', 'down'), node, ft(f, t))$[     gn('elec', node)
                                                           and ord(t) >= tSolveFirst and ord(t) <= tSolveFirst + mSettings(m, 't_reserveLength')
                                                           and mf(m, f)
                                                         ] = max(p_nReserves(node, 'tertiary', 'down'),
                                                                 sqrt{sum((grid, flowUnit(flow, unit_flow), fCentral)$(gnu(grid, node, unit_flow)),
                                                                       { (1 - ts_cf_(flow, node, fCentral, t))
                                                                         * p_gnu(grid, node, unit_flow, 'maxGen')
                                                                         * p_unit(unit_flow, 'availability')
                                                                         * 0.2
                                                                       }
                                                                      ) ** 2 }
                                                             );
);
$offtext
loop(gn(grid, node),
    restypeDirectionNode(restypeDirection(restype, up_down), node)$(p_nReserves(node, restype, 'use_time_series') and sum((f,t), ts_reserveDemand(restype, up_down, node, f, t))) = yes;
    restypeDirectionNode(restypeDirection(restype, up_down), node)$(not p_nReserves(node, restype, 'use_time_series') and p_nReserves(node, restype, up_down)) = yes;
);

*  ts_cf_(flow,'FI_R',f,t)$(ord(f) > 1 and ord(f) <= mSettings(mSolve, 'forecasts') + 1 and ord(t) >= tSolveFirst and ord(t) < tSolveFirst + f_improve )
*    = ts_cf(flow,'FI_R',f,t) + [ts_cf(flow,'FI_R','f00',t) - ts_cf(flow,'FI_R',f,t)] * [1 - log10( {ord(t) - tSolveFirst + 1.7} / 1.47 ) ];
*  ts_cf_(flow,'SE_N',f,t)$(ord(f) > 1 and ord(f) <= mSettings(mSolve, 'forecasts') + 1 and ord(t) >= tSolveFirst and ord(t) < tSolveFirst + f_improve )
*    = ts_cf(flow,'SE_N',f,t) + [ts_cf(flow,'SE_N','f00',t) - ts_cf(flow,'SE_N',f,t)] * [1 - log10( {ord(t) - tSolveFirst + 1.7} / 1.47 ) ];
