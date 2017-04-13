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
        ts_length = max(sum(t$ts_influx(grid, node, 'f00', t), 1), ts_length); // Find the maximum length of the given time series
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


* Parse through effLevelGroupUnit and convert selected effSelectors into sets representing those selections
loop(unit,
    loop(effLevel$sum(m, mSettingsEff(m, effLevel)),
        // effSelector using DirectOff
        if (sum(effDirectOff, effLevelGroupUnit(effLevel, effDirectOff, unit)),
            loop(effDirectOff${effLevelGroupUnit(effLevel, effDirectOff, unit)},
                    effGroup(effDirectOff) = yes;
                    effGroupSelector(effDirectOff, effDirectOff) = yes;
                    effGroupSelectorUnit(effDirectOff, unit, effDirectOff) = yes;
            );
        );

        // effSelector using DirectOn
        if (sum(effDirectOn, effLevelGroupUnit(effLevel, effDirectOn, unit)),
            loop(effDirectOn${effLevelGroupUnit(effLevel, effDirectOn, unit)},
                    effGroup(effDirectOn) = yes;
                    effGroupSelector(effDirectOn, effDirectOn) = yes;
                    effGroupSelectorUnit(effDirectOn, unit, effDirectOn) = yes;
            );
        );

        // effSelectors using Lambda
        if (sum(effLambda, effLevelGroupUnit(effLevel, effLambda, unit)),
            loop(effLambda${effLevelGroupUnit(effLevel, effLambda, unit)},
                    effGroup(effLambda) = yes;
                    loop(effLambda_${ord(effLambda_) <= ord(effLambda)},
                            effGroupSelector(effLambda, effLambda_) = yes;
                            effGroupSelectorUnit(effLambda, unit, effLambda_) = yes;
                    );
            );
        );

        // Calculate parameters for units using direct input output conversion without online variable
        loop(effGroupSelectorUnit(effDirectOff, unit, effDirectOff_),
            p_effUnit(effDirectOff, unit, effDirectOff_, 'lb') = 0; // No min load for the DirectOff approximation
            p_effUnit(effDirectOff, unit, effDirectOff_, 'rb') = 1; // No max load for the DirectOff approximation
            p_effUnit(effDirectOff, unit, effDirectOff_, 'slope') = 1 / smax(eff${p_unit(unit, eff)}, p_unit(unit, eff)); // Uses maximum found (nonzero) efficiency.
            p_effUnit(effDirectOff, unit, effDirectOff_, 'section') = 0; // No section for the DirectOff approximation
        );

        // Calculate parameters for units using direct input output conversion with online variable
        loop(effGroupSelectorUnit(effDirectOn, unit, effDirectOn_),
            p_effUnit(effDirectOn, unit, effDirectOn_, 'lb') = p_unit(unit, 'rb00'); // rb00 contains the possible min load of the unit
            p_effUnit(effDirectOn, unit, effDirectOn_, 'rb') = smax(rb, p_unit(unit, rb)); // Maximum load determined by the largest 'rb' parameter found in data
            loop(rb__${p_unit(unit, rb__) = smax(rb, p_unit(unit, rb))}, // Find the maximum defined 'rb'.
                loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
                    loop(rb_${p_unit(unit, rb_) = smin(rb${p_unit(unit, rb)}, p_unit(unit, rb))}, // Find the minimum defined nonzero 'rb'.
                        loop(eff_${ord(eff_) = ord(rb_)},                      // ... and the corresponding 'eff'.
                            // Calculating the slope based on the first nonzero and the last defined data points.
                            p_effUnit(effDirectOn, unit, effDirectOn_, 'slope') =
                                + (p_unit(unit, rb__) / p_unit(unit, eff__) - p_unit(unit, rb_) / p_unit(unit, eff_))
                                    / (p_unit(unit, rb__) - p_unit(unit, rb_));
                            // Calculating the section based on the slope and the last defined point.
                            p_effUnit(effDirectOn, unit, effDirectOn_, 'section') =
                                ( 1 / p_unit(unit, eff__) - p_effUnit(effDirectOn, unit, effDirectOn_, 'slope') )
                                    * p_unit(unit, rb__);
                        );
                    );
                );
            );
        );

        // Calculate lambdas
        loop(effGroupSelectorUnit(effLambda, unit, effLambda_),
            p_effUnit(effLambda, unit, effLambda_, 'lb') = p_unit(unit, 'rb00'); // 'rb00' contains the possible minload of the unit, recorded for every lambda for p_effGroupUnit.
            // For the first lambda, simply use the first data point
            if(ord(effLambda_) = 1,
                p_effUnit(effLambda, unit, effLambda_, 'rb') = p_unit(unit, 'rb00'); // 'rb00' also works as the lowest lambda point.
                p_effUnit(effLambda, unit, effLambda_, 'slope') = 1 / p_unit(unit, 'eff00'); // eff00 works as the lowest lambda slope.
                p_effUnit(effLambda, unit, effLambda_, 'section')${not p_unit(unit, 'rb00')} = p_unit(unit, 'rb01') * ( 1 / p_unit(unit, 'eff00') - 1 / p_unit(unit, 'eff01') ) / (ord(effLambda) - 1)**2; // Dummy section if scalable from zero.
            // For the last lambda, use the last data point
            elseif ord(effLambda_) = ord(effLambda),
                loop(rb__${p_unit(unit, rb__) = smax(rb, p_unit(unit, rb))}, // Find the maximum defined 'rb'.
                    loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
                        p_effUnit(effLambda, unit, effLambda_, 'rb') = p_unit(unit, rb__); // Last defined 'rb'.
                        p_effUnit(effLambda, unit, effLambda_, 'slope') = 1 / p_unit(unit, eff__); // Last defined 'eff'.
                    );
                );
            // For the intermediary lambdas, use interpolation of the data points on each side.
            else
                count = sum(rb${p_unit(unit, rb)}, 1) + 1${not p_unit(unit, 'rb00')}; // Count the data points to correctly establish the lambda intervals, have to separately account for the possibility of 'rb00' = 0.
                tmp = (ord(effLambda_) - 1) / (ord(effLambda) - 1 ) * count; // Determines the lambda interval.
                count_lambda = floor(tmp); // Determine the data point index before the lambda
                count_lambda2 = ceil(tmp); // Determine the data point index after the lambda
                loop(rb__${ord(rb__) = count_lambda2}, // Find the ceiling data point 'rb'.
                    loop(eff__${ord(eff__) = count_lambda2}, // ... and the corresponding 'eff'.
                        loop(rb_${ord(rb_) = count_lambda}, // Find the floor data point 'rb'.
                            loop(eff_${ord(eff_) = count_lambda}, // .. and the corresponding 'eff'.
                                p_effUnit(effLambda, unit, effLambda_, 'rb') = (tmp - count_lambda) * p_unit(unit, rb__) + (count_lambda2 - tmp) * p_unit(unit, rb_); // Average the 'rb' between the found data points, weighted by tmp.
                                p_effUnit(effLambda, unit, effLambda_, 'slope') = (tmp - count_lambda) / p_unit(unit, eff__) + (count_lambda2 - tmp) / p_unit(unit, eff_); // Average the 'eff' between the found data points, weighed by tmp.
                            );
                        );
                    );
                );
            );
        );

    ); // END LOOP OVER effLevel
); // END LOOP OVER unit


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel$sum(m, mSettingsEff(m, effLevel)),
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            p_effGroupUnit(effGroup, unit, 'rb') = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'rb'));
            p_effGroupUnit(effGroup, unit, 'lb') = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, p_effUnit(effGroup, unit, effSelector, 'lb'));
            p_effGroupUnit(effGroup, unit, 'slope') = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, p_effUnit(effGroup, unit, effSelector, 'slope')); // NOTE! Uses maximum efficiency for the group.
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
