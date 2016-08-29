if (mType('storage'),
    m('storage') = yes;
    mSettings('storage', 't_start') = 0;
    mSettings('storage', 't_horizon') = 8760;
    mSettings('storage', 't_jump') = 24;
    mSettings('storage', 't_forecastLength') = 168;
    mSettings('storage', 't_interval') = 1;
    mSettings('storage', 't_end') = 20;
    mSettings('storage', 'samples') = 1;
    mSettings('storage', 'forecasts') = 0;
    mf('storage', f)$[ord(f)-1 <= mSettings('storage', 'forecasts')] = yes;
    active('storageValue') = yes;

    fRealization(f) = no;
    fRealization('f00') = yes;
    fCentral(f) = no;
    fCentral('f01') = yes;
    sInitial(s) = no;
    sInitial('s000') = yes;
    sCentral(s) = no;
    sCentral('s001') = yes;

    p_stepLength(m, f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later
    p_sProbability(s) = 0;
    p_sProbability('s000') = 1;
    p_fProbability(f) = 0;
    p_fProbability(fRealization) = 1;
);

Model storage /
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
    q_maxState
    q_minState
    q_boundState
/;
