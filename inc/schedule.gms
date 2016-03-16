if (modelType('schedule'),
    m('schedule') = yes;
    modelSolveRules('schedule', 't_start') = 1;
    modelSolveRules('schedule', 't_horizon') = 168;
    modelSolveRules('schedule', 't_jump') = 24;
    modelSolveRules('schedule', 't_forecastLength') = 168;
    modelSolveRules('schedule', 't_interval') = 1;
    modelSolveRules('schedule', 't_end') = 20;
    modelSolveRules('schedule', 'samples') = 1;
    modelSolveRules('schedule', 'forecasts') = 0;
    mf('schedule', f)$[ord(f)-1 <= modelSolveRules('schedule', 'forecasts')] = yes;
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

Model schedule /
    q_obj
    q_balance
    q_resDemand
    q_maxDownward
    q_maxUpward
    q_storageControl
    q_storageDynamics
    q_bindStorage
    q_startup
    q_bindOnline
    q_fuelUse
    q_conversion
    q_outputRatioFixed
    q_outputRatioConstrained
    q_stoMinContent
    q_stoMaxContent
    q_maxHydropower
    q_transferLimit
/;
