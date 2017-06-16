    // Set mft for the modelling period and model forecasts
    mft(mSolve,f,t) = no;
    mft(mSolve, f, t)$( p_stepLength(mSolve, f, t) and ord(t) < tSolveFirst + mSettings(mSolve, 't_horizon') and
        {
            [ ord(f) = 1 and ord(t) = tSolveFirst + tDispatchCurrent - 1]
              or
            [ ord(f) > 1 and ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength') and ord(t) >= tSolveFirst + tDispatchCurrent ]
              or
            [ fCentral(f) and ord(t) > mSettings(mSolve, 't_forecastLength') ]
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
    ft_dynamic('f00',tSolve+tDispatchCurrent)$(tDispatchCurrent > 0) = yes;
    ft_dynamic(f,t)$(ord(f) = sum(f_$(fCentral(f_)), ord(f_)) and ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')) = yes;
    ft_full(f,t) = no;
    ft_full(f,t) = ft(f,t) + ft_dynamic(f,t);

    ft_realized(f,t) = no;
    ft_realized(f,t)$[fRealization(f) and ord(t) >= ord(tSolve) and ord(t) <= ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;
    ft_realizedLast(f,t) = no;
    ft_realizedLast(f,t)$[fRealization(f) and ord(t) = ord(tSolve) + mSettings(mSolve, 't_jump')] = yes;

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
    );

    pf(f,t) = no;
    pf(ft(f,t))$(ord(t) eq ord(tSolve) + tDispatchCurrent) = 1 - ord(f);

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

