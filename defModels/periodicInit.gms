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
        loop(effGroupSelectorUnit(effDirectOff, unit, effDirectOff_)$effLevelGroupUnit(effLevel, effDirectOff, unit),
            p_effUnit(effDirectOff, unit, effDirectOff_, 'lb') = 0; // No min load for the DirectOff approximation
            p_effUnit(effDirectOff, unit, effDirectOff_, 'op') = 1; // No max load for the DirectOff approximation
            p_effUnit(effDirectOff, unit, effDirectOff_, 'slope') = 1 / smax(eff${p_unit(unit, eff)}, p_unit(unit, eff)); // Uses maximum found (nonzero) efficiency.
            p_effUnit(effDirectOff, unit, effDirectOff_, 'section') = 0; // No section for the DirectOff approximation
        );

        // Calculate parameters for units using direct input output conversion with online variable
        loop(effGroupSelectorUnit(effDirectOn, unit, effDirectOn_)$effLevelGroupUnit(effLevel, effDirectOn, unit),
            p_effUnit(effDirectOn, unit, effDirectOn_, 'lb') = p_unit(unit, 'op00'); // op00 contains the possible min load of the unit
            p_effUnit(effDirectOn, unit, effDirectOn_, 'op') = smax(op, p_unit(unit, op)); // Maximum load determined by the largest 'op' parameter found in data
            tmp_count_op = 0;
            loop(op$p_unit(unit, op),  // Determine the last operating point in use
                tmp_count_op = ord(op);
            );
            loop(op__$(ord(op__) = tmp_count_op), // Find the maximum defined 'op'.
                loop(eff__${ord(eff__) = ord(op__)},                     // ...  and the corresponding 'eff'.
                     if(p_unit(unit, 'op00') = 0,  // If the minimum operating point is at zero, then the section and slope are calculated with the assumption that the efficiency curve crosses at opFirstCross
                         heat_rate =  // heat rate at the cross between real efficiency curve and approximated efficiency curve
                            1 / {
                                  + p_unit(unit, 'eff00') * [ p_unit(unit, op__) - p_unit(unit, 'opFirstCross') ] / [ p_unit(unit, op__) - p_unit(unit, 'op00') ]
                                  + p_unit(unit, eff__) * [ p_unit(unit, 'opFirstCross') - p_unit(unit, 'op00') ] / [ p_unit(unit, op__) - p_unit(unit, 'op00') ]
                                };
                         put log unit.tl:20, heat_rate /;
                         p_effGroupUnit(effDirectOn, unit, 'section') = p_unit(unit, 'section');
                         p_effGroupUnit(effDirectOn, unit, 'section')$(not p_effGroupUnit(effDirectOn, unit, 'section')) =  // Unless section has been defined, it is calculated based on the opFirstCross
                              p_unit(unit, 'opFirstCross')
                                * ( heat_rate - 1 / p_unit(unit, eff__) )
                                / ( p_unit(unit, op__) - p_unit(unit, 'opFirstCross') );
                         p_effUnit(effDirectOn, unit, effDirectOn_, 'slope') =
                             1 / p_unit(unit, eff__) - p_effGroupUnit(effDirectOn, unit, 'section') / p_unit(unit, op__);
                     else  // If the minimum operating point is above zero, then the approximate efficiency curve crosses the real efficiency curve at minimum and maximum.
                          // Calculating the slope based on the first nonzero and the last defined data points.
                         p_effUnit(effDirectOn, unit, effDirectOn_, 'slope') =
                           + (p_unit(unit, op__) / p_unit(unit, eff__) - p_unit(unit, 'op00') / p_unit(unit, 'eff00'))
                                / (p_unit(unit, op__) - p_unit(unit, 'op00'));
                         // Calculating the section based on the slope and the last defined point.
                         p_effUnit(effDirectOn, unit, effDirectOn_, 'section') =
                             ( 1 / p_unit(unit, eff__) - p_effUnit(effDirectOn, unit, effDirectOn_, 'slope') )
                                * p_unit(unit, op__);
                     );
                );
            );
        );

        // Calculate lambdas
        loop(effGroupSelectorUnit(effLambda, unit, effLambda_)$effLevelGroupUnit(effLevel, effLambda, unit),
            p_effUnit(effLambda, unit, effLambda_, 'lb') = p_unit(unit, 'op00'); // op00 contains the min load of the unit
            tmp_count_op = 0;
            loop(op$p_unit(unit, op),  // Determine the last operating point in use
                tmp_count_op = ord(op);
            );
            tmp_op = (ord(effLambda_)-1) / (ord(effLambda) - 1); //  Calculate the relative location of the operating point in the lambdas
            p_effUnit(effLambda, unit, effLambda_, 'op') = tmp_op;  // Copy the operating point to the p_effUnit
            tmp_op$(ord(effLambda_) = 1 and not p_unit(unit, 'op00') and not p_unit(unit, 'section')) = p_unit(unit, 'opFirstCross');  // Copy the cross between the p_unit efficiency curve and opFirstCross to the temporary op parameter for further calculations
            // tmp_op falls between two p_unit defined operating points or then it is equal to one of them
            loop((op_, op__)$({[tmp_op > p_unit(unit, op_) and tmp_op < p_unit(unit, op__) and ord(op_) = ord(op__) - 1] or [p_unit(unit, op_) = tmp_op and ord(op_) = ord(op__)]} and ord(op__) <= tmp_count_op),
                loop((eff_, eff__)$(ord(op_) = ord(eff_) and ord(op__) = ord(eff__)),
                    tmp_dist = p_unit(unit, op__) - p_unit(unit, op_); // Calculate the distance between the operating points (zero if the points are the same)
                    if (tmp_dist, // If the operating points are not the same
                        heat_rate =  // Heat rate is a weighted average of the heat rates at the p_unit operating points
                            1 / {
                                  + p_unit(unit, eff_) * [ p_unit(unit, op__) - tmp_op ] / tmp_dist
                                  + p_unit(unit, eff__) * [ tmp_op - p_unit(unit, op_) ] / tmp_dist
                                };
                    else  // If the operating point is the same, the the heat rate can be used directly
                        heat_rate = 1 / p_unit(unit, eff_);
                    );
                    if (ord(effLambda_) = 1,
                        if(p_unit(unit, 'op00') or p_unit(unit, 'section'),  // If the min. load of the unit is not zero or the section has been pre-defined, then section is copied directly from the unit properties
                            p_effGroupUnit(effLambda, unit, 'section') = p_unit(unit, 'section');
                        else
                            p_effGroupUnit(effLambda, unit, 'section') =  // Calculate section based on the opFirstCross, which has been calculated into p_effUnit(effLambda, unit, effLambda_, 'op')
                                p_effUnit(effLambda, unit, effLambda_, 'op')
                                  * ( heat_rate - 1 / p_unit(unit, eff__) )
                                  / ( p_unit(unit, 'op01') - tmp_op );
                        );
                    );
                    p_effUnit(effLambda, unit, effLambda_, 'slope')$(ord(effLambda_) > 1 or p_unit(unit, 'op00')) =
                        heat_rate - p_effGroupUnit(effLambda, unit, 'section') / tmp_op;
                );
            );
        );
    ); // END LOOP OVER effLevel
); // END LOOP OVER unit


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel$sum(m, mSettingsEff(m, effLevel)),
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            p_effGroupUnit(effGroup, unit, 'op') = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'op'));
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
