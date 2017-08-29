if (mType('invest'),
    m('invest') = yes; // Definition, that the model exists by its name

    // Define the temporal structure of the model in time indeces
    mSettings('invest', 'intervalInHours') = 1; // Define the duration of a single time-step in hours
    mInterval('invest', 'intervalLength', 'c000') = 1;
    mInterval('invest', 'intervalEnd', 'c000') = 504;

    // Define the model execution parameters in time indeces
    mSettings('invest', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('invest', 't_horizon') = 8760;
    mSettings('invest', 't_jump') = 2184;
    mSettings('invest', 't_forecastStart') = 1; // Ord of first forecast available
    mSettings('invest', 't_forecastLength') = 2184;
    mSettings('invest', 't_forecastJump') = 2184;
    mSettings('invest', 't_end') = 2180;
    mSettings('invest', 't_reserveLength') = 36;

    // Define unit aggregation and efficiency levels starting indeces
    mSettings('invest', 't_aggregate') = 4392;
    mSettingsEff('invest', 'level1') = 1;
    mSettingsEff('invest', 'level2') = 1;
    mSettingsEff('invest', 'level3') = 1;
    mSettingsEff('invest', 'level4') = 4392;

    // Define active model features
    active('storageValue') = yes;

    // Define model stochastic parameters
    mSettings('invest', 'samples') = 1;
    mSettings('invest', 'forecasts') = 0;
    mSettings('invest', 'readForecastsInTheLoop') = 0;
    mf('invest', f)$[ord(f)-1 <= mSettings('invest', 'forecasts')] = yes;
    fRealization(f) = no;
    fRealization('f00') = yes;
    fCentral(f) = no;
    sInitial(s) = no;
    sInitial('s000') = yes;
    sCentral(s) = no;
    sCentral('s000') = yes;

    p_stepLength('invest', f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later
    p_sProbability(s) = 0;
    p_sProbability('s000') = 1;
    p_fProbability(f) = 0;
    p_fProbability(fRealization) = 1;

);

Model invest /
    q_obj
    q_balance
    q_resDemand
    q_resTransfer
    q_maxDownward
    q_maxUpward
    q_startup
    q_genRamp
    q_genRampChange
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
    q_outputRatioFixed
    q_outputRatioConstrained
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundState
    q_boundStateMaxDiff
    q_boundCyclic
    q_bidirectionalTransfer
    q_fixedGenCap1U
    q_fixedGenCap2U
    q_symmetricTransferCap
    q_onlineLimit
    q_rampUpLimit
    q_rampDownLimit
    q_startuptype
    q_minUp
    q_minDown
    q_capacityMargin
    q_emissionCap
/;
