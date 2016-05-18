* ��� Generate model rules from basic patterns defined in the model definition files ����������������������������������������������������

* Check the modelSolves for preset patterns for model solve timings
* If not found, then use mSettings to set the model solve timings
loop(mType,
    if(sum(t$modelSolves(mType, t), 1) = 0,
        t_skip_counter = 0;
        loop(t$( ord(t) = mSettings(mType, 't_start') + mSettings(mType, 't_jump') * t_skip_counter and ord(t) <= mSettings(mType, 't_end') ),
            modelSolves(mType, t)=yes;
            t_skip_counter = t_skip_counter + 1;
        );
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


