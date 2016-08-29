if (mType('schedule'),
    m('schedule') = yes;
    mSettings('schedule', 't_start') = 1;  // Ord of first solve (i.e. >0)
    mSettings('schedule', 't_horizon') = 8760;
    mSettings('schedule', 't_jump') = 48;
    mSettings('schedule', 't_forecastLength') = 8760;
    mSettings('schedule', 't_end') = 48;
    mSettings('schedule', 'samples') = 1;
    mSettings('schedule', 'forecasts') = 0;
    mf('schedule', f)$[ord(f)-1 <= mSettings('schedule', 'forecasts')] = yes;
    mInterval('schedule', 'intervalLength', 'c000') = 1;
    mInterval('schedule', 'intervalEnd', 'c000') = 48;
    mInterval('schedule', 'intervalLength', 'c001') = 3;
    mInterval('schedule', 'intervalEnd', 'c001') = 96;
    mInterval('schedule', 'intervalLength', 'c002') = 6;
    mInterval('schedule', 'intervalEnd', 'c002') = 168;
    mInterval('schedule', 'intervalLength', 'c003') = 24;
    mInterval('schedule', 'intervalEnd', 'c003') = 4*168+24;
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
    q_storageDynamics
    q_storageConversion
    q_bindStorage
    q_startup
    q_bindOnline
    q_fuelUse
    q_conversion
    q_outputRatioFixed
    q_outputRatioConstrained
    q_stoMinContent
    q_stoMaxContent
    q_transferLimit
    q_boundState
/;
