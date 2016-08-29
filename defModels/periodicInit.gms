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
loop(m$(continueLoop),
    loop(gn(grid, node),
        ts_length = sum(t$ts_energyDemand(grid, node, 'f00', t), 1);
    );
    ct(t)$(
            ord(t) > ts_length
        and ord(t) <= ts_length + max(mSettings(m, 't_forecastLength'), mSettings(m, 't_horizon'))
        and ord(t) <= mSettings(m, 't_end') + max(mSettings(m, 't_forecastLength'), mSettings(m, 't_horizon'))
    ) = -ts_length;
    continueLoop = 0;
);