if (mType('schedule'),
    m('schedule') = yes;
    mSettings('schedule', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('schedule', 't_horizon') = 8760;
    mSettings('schedule', 't_jump') = 48;
    mSettings('schedule', 't_forecastLength') = 8760;
    mSettings('schedule', 't_end') = 80;
    mSettings('schedule', 'samples') = 1;
    mSettings('schedule', 'forecasts') = 0;
    mSettings('schedule', 't_aggregate') = 72;
    mSettingsEff('schedule', 'level1') = 1;
    mSettingsEff('schedule', 'level2') = 24;
    mSettingsEff('schedule', 'level3') = 48;
    mSettingsEff('schedule', 'level4') = 168;
    mf('schedule', f)$[ord(f)-1 <= mSettings('schedule', 'forecasts')] = yes;
    mInterval('schedule', 'intervalLength', 'c000') = 1;
    mInterval('schedule', 'intervalEnd', 'c000') = 168;
    mInterval('schedule', 'intervalLength', 'c001') = 3;
    mInterval('schedule', 'intervalEnd', 'c001') = 336;
    mInterval('schedule', 'intervalLength', 'c002') = 6;
    mInterval('schedule', 'intervalEnd', 'c002') = 1680;
    mInterval('schedule', 'intervalLength', 'c003') = 24;
    mInterval('schedule', 'intervalEnd', 'c003') = 4392;
    mInterval('schedule', 'intervalLength', 'c004') = 168;
    mInterval('schedule', 'intervalEnd', 'c004') = 8760;
    active('storageValue') = yes;

    fRealization(f) = no;
    fRealization('f00') = yes;
    fCentral(f) = no;
    fCentral('f01') = yes;
    sInitial(s) = no;
    sInitial('s000') = yes;
    sCentral(s) = no;
    sCentral('s001') = yes;

    p_stepLength('schedule', f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later
    p_sProbability(s) = 0;
    p_sProbability('s000') = 1;
    p_fProbability(f) = 0;
    p_fProbability(fRealization) = 1;
);

Model schedule /
    q_obj
    q_balance
    q_resDemand
    q_maxDownward
    q_maxUpward
    q_startup
    q_bindOnline
    q_conversionDirectInputOutput
    q_conversionSOS2InputIntermediate
    q_conversionSOS2Constraint
    q_conversionSOS2IntermediateOutput
    q_outputRatioFixed
    q_outputRatioConstrained
    q_transferLimit
    q_stateSlack
    q_stateUpwardLimit
    q_stateDownwardLimit
    q_boundState
    q_boundCyclic
/;
