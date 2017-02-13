* иии Generate model rules from basic patterns defined in the model definition files ииииииииииииииииииииииииииииииииииииииииииииииииииии

* Check the modelSolves for preset patterns for model solve timings
* If not found, then use mSettings to set the model solve timings
loop(m,
    if(sum(t$modelSolves(m, t), 1) = 0,
        t_skip_counter = 0;
        loop(t$( ord(t) = mSettings(m, 't_start') + mSettings(m, 't_jump') * t_skip_counter and ord(t) <= mSettings(m, 't_end') ),
            modelSolves(m, t)=yes;
            t_skip_counter = t_skip_counter + 1;
        );
        p_stepLengthNoReset(m, f, t) = no;
    );
);

* Select samples for the model
loop(m,
    // Set samples in use for the models
    if (not sum(s, ms(m, s)),  // unless they have been provided as input
        ms(m, s)$(ord(s) <= mSettings(m, 'samples')) = yes;
        if (mSettings(m, 'samples') = 0,     // Use all samples if mSettings/samples is 0
            ms(m, s) = yes;
        );
    );
    // Set forecasts in use for the models
    if (not sum(f, mf(m, f)),  // unless they have been provided as input
        mf(m, f)$(ord(f) <= 1 + mSettings(m, 'forecasts')) = yes;  // realization needs one f, therefore 1 + number of forecasts
    );
);


* Calculate the length of the time series
continueLoop = 1;
ts_length = 0;
loop(m$(continueLoop),
    loop(gn(grid, node),
        ts_length = max(sum(t$ts_energyDemand(grid, node, 'f00', t), 1), ts_length); // Find the maximum length of the given time series
    );
    ct(t)$(
            ord(t) > ts_length
        and ord(t) <= ts_length + max(mSettings(m, 't_forecastLength'), mSettings(m, 't_horizon'))
        and ord(t) <= mSettings(m, 't_end') + max(mSettings(m, 't_forecastLength'), mSettings(m, 't_horizon'))
    ) = -ts_length;
    continueLoop = 0;
);

loop(m,
    tmp = 0;
    continueLoop = 1;
    loop(counter$continueLoop,
        if(not mInterval(m, 'intervalEnd', counter),
            continueLoop = 0;
        else
            abort$(mod(mInterval(m, 'intervalEnd', counter) - mInterval(m, 'intervalEnd', counter-1), mInterval(m, 'intervalLength', counter))) "IntervalLength is not evenly divisible within the interval", m, continueLoop;
            continueLoop = continueLoop + 1;
        );
    );
);


* Parse through effLevelSelectorUnit and convert selected effSelectors into sets representing those selections
loop(unit,
    cum_lambda = 0;
    cum_slope = 0;
    loop(effLevel$sum(m, mSettingsEff(m, effLevel)),
        // effSelector using DirectOn
        if (sum(effSelector$effDirectOn(effSelector), effLevelGroupUnit(effLevel, effSelector, unit)),
            loop(effSelector$effDirectOn(effSelector),
                if(effLevelGroupUnit(effLevel, effSelector, unit),
                    effGroup(effSelector) = yes;
                    effGroupSelector(effSelector, effSelector) = yes;
                    effLevelSelectorUnit(effLevel, effSelector, unit) = yes;
                );
            );
        );
        // effSelector using DirectOff
        if (sum(effSelector$effDirectOff(effSelector), effLevelGroupUnit(effLevel, effSelector, unit)),
            loop(effSelector$effDirectOff(effSelector),
                if(effLevelGroupUnit(effLevel, effSelector, unit),
                    effGroup(effSelector) = yes;
                    effGroupSelector(effSelector, effSelector) = yes;
                    effLevelSelectorUnit(effLevel, effSelector, unit) = yes;
                );
            );
        );

        // effSelectors using Lambda
        if (sum(effSelector_$effLambda(effSelector_), effLevelGroupUnit(effLevel, effSelector_, unit)),
            count = 0;
            loop(effSelector$effLambda(effSelector),
                count = count + 1;
                if(effLevelGroupUnit(effLevel, effSelector, unit),
                    count_lambda = count;
                    cum_lambda = cum_lambda + count_lambda;
                    effGroup(effSelector) = yes;
                );
            );
            count = 0;
            loop(effSelector$effLambda(effSelector),
                count = count + 1;
                if( count > cum_lambda - count_lambda and count <= cum_lambda,
                    effLevelSelectorUnit(effLevel, effSelector, unit) = yes;
                    effGroupSelectorUnit(effGroup, unit, effSelector)$effLevelGroupUnit(effLevel, effGroup, unit) = yes;
                );
                if ( count = count_lambda,
                    count_lambda2 = 0;
                    loop(effSelector_$effLambda(effSelector_),
                        count_lambda2 = count_lambda2 + 1;
                        if (count_lambda2 > cum_lambda - count_lambda and count_lambda2 <= cum_lambda,
                            effGroupSelector(effSelector, effSelector_) = yes;
                        );
                    );
                );
            );
        );
        // effSelectors using Slope
        if (sum(effSelector_$effSlope(effSelector_), effLevelGroupUnit(effLevel, effSelector_, unit)),
            count = 0;
            loop(effSelector$effSlope(effSelector),
                count = count + 1;
                if(effLevelGroupUnit(effLevel, effSelector, unit),
                    count_slope = count;
                    cum_slope = cum_slope + count_slope;
                    effGroup(effSelector) = yes;
                );
            );
            count = 0;
            loop(effSelector$effSlope(effSelector),
                count = count + 1;
                if( count > cum_slope - count_slope and count <= cum_slope,
                    effLevelSelectorUnit(effLevel, effSelector, unit) = yes;
                    effGroupSelectorUnit(effGroup, unit, effSelector)$effLevelGroupUnit(effLevel, effGroup, unit) = yes;
                );
                if (count = count_slope,
                    count_slope2 = 0;
                    loop(effSelector_$effSlope(effSelector_),
                        count_slope2 = count_slope2 + 1;
                        if( count_slope2 > cum_slope - count_slope and count_slope2 <= cum_slope,
                            //effSelectorFirstSlope(effSelector, effSelector_) = yes;
                            effGroupSelector(effSelector, effSelector_) = yes;
                        );
                    );
                );
            );
        );
        // Calculate parameters for units using direct input output conversion with online variable
        loop(effSelector$sum(effDirectOn$effGroupSelector(effDirectOn, effSelector), 1),
            p_effUnit(effSelector, unit, 'lb') = p_unit(unit, 'rb00');
            p_effUnit(effSelector, unit, 'rb') = p_unit(unit, 'rb01');
            p_effUnit(effSelector, unit, 'section')$(not p_unit(unit, 'eff01')) = 0;
            p_effUnit(effSelector, unit, 'slope')$(not p_unit(unit, 'eff01')) = 1 / p_unit(unit, 'eff00');
            p_effUnit(effSelector, unit, 'section')$p_unit(unit, 'eff01') =
              + 1 / p_unit(unit, 'eff01')
              - [p_unit(unit, 'rb01') - 0]
                  / [p_unit(unit, 'rb01') - p_unit(unit, 'rb00')]
                  * [1 / p_unit(unit, 'eff01') * p_unit(unit, 'rb01') - 1 / p_unit(unit, 'eff00') * p_unit(unit, 'rb00')];
            p_effUnit(effSelector, unit, 'slope')$p_unit(unit, 'eff01') =
              + 1 / p_unit(unit, 'eff01') - p_effUnit(effSelector, unit, 'section');
        );

        // Calculate parameters for units using direct input output conversion without online variable
        loop(effSelector$sum(effDirectOff$effGroupSelector(effDirectOff, effSelector), 1),
            p_effUnit(effSelector, unit, 'rb') = 1;
            p_effUnit(effSelector, unit, 'lb') = 0;
            p_effUnit(effSelector, unit, 'section')$(not p_unit(unit, 'eff01')) = 0;
            p_effUnit(effSelector, unit, 'slope')$(not p_unit(unit, 'eff01')) = 1 / p_unit(unit, 'eff00');
            p_effUnit(effSelector, unit, 'section')$p_unit(unit, 'eff01') = 0;
            p_effUnit(effSelector, unit, 'slope')$p_unit(unit, 'eff01') = 1 / p_unit(unit, 'eff01');
        );

        // Make calculations for different parts of the piecewise curve in the case of using slope
        count_slope2 = 0;
        loop(effSelector$(effSlope(effSelector) and effLevelSelectorUnit(effLevel, effSelector, unit)),
            p_effUnit(effSelector, unit, 'rb') = ((count_slope - count_slope2 - 1) * p_unit(unit, 'rb00') + (count_slope2 + 1) * p_unit(unit, 'rb01')) / count_slope;
            p_effUnit(effSelector, unit, 'lb') = ((count_slope - count_slope2) * p_unit(unit, 'rb00') + count_slope2 * p_unit(unit, 'rb01')) / count_slope;
            //if(count_slope2 = 0,
                //p_effUnit(effSelector, unit, 'slope') = ((count_slope-1 - count_slope2) * (1 / p_unit(unit, 'eff00')) + count_slope2 * (1 / p_unit(unit, 'eff01'))) / (count_slope - 1);
                //tmp = p_effUnit(effSelector, unit, 'slope');
            //else
                p_effUnit(effSelector, unit, 'slope')
                  = ((count_slope-1 - count_slope2) * (1 / p_unit(unit, 'eff00')) + (count_slope2 + 1) * (1 / p_unit(unit, 'eff01'))) / count_slope;
            //        - tmp;
            //);
            count_slope2 = count_slope2 + 1;
        );

        // Calculate lambdas
        count_lambda2 = 0;
        loop(effSelector$(effLambda(effSelector) and effLevelSelectorUnit(effLevel, effSelector, unit)),
            p_effUnit(effSelector, unit, 'rb') = ((count_lambda-1 - count_lambda2) * p_unit(unit, 'rb00') + count_lambda2 * p_unit(unit, 'rb01')) / (count_lambda - 1);
            //no lb for lambdas, since number of borders same as number of slopes   p_effUnit(effSelector, unit, 'lb') = ((count_lambda-1 - count_lambda2 + 1) * p_unit(unit, 'rb00') + (count_lambda2 - 1) * p_unit(unit, 'rb01')) / (count_lambda - 1);
            p_effUnit(effSelector, unit, 'slope')$effLevelSelectorUnit(effLevel, effSelector, unit)
              = ((count_lambda-1 - count_lambda2) * (1 / p_unit(unit, 'eff00')) + count_lambda2 * (1 / p_unit(unit, 'eff01'))) / (count_lambda - 1);
            count_lambda2 = count_lambda2 + 1;
        );

    );
);


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel$sum(m, mSettingsEff(m, effLevel)),
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            p_effGroupUnit(effGroup, unit, 'rb') = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effSelector, unit, 'rb'));
            p_effGroupUnit(effGroup, unit, 'lb') = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effSelector, unit, 'lb'));
        );
    );
);


* Ensure that efficiency levels extend to the end of the model horizon
loop(m,
    continueLoop = 0;
    loop(effLevel$mSettingsEff(m, effLevel),
        continueLoop = continueLoop + 1;
    );
    loop(effLevel$(ord(effLevel) = continueLoop),
        if (mSettingsEff(m, effLevel) <> mSettings(m, 't_horizon'),
            mSettingsEff(m, effLevel + 1) = mSettings(m, 't_horizon');
        );
    );
);


* Set slack direction
p_slackDirection(upwardSlack) = 1;
p_slackDirection(downwardSlack) = -1;
