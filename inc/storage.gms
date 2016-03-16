m('storage') = yes;
modelSolveRules('storage', 't_start') = 0;
modelSolveRules('storage', 't_horizon') = 8760;
modelSolveRules('storage', 'samples') = 0;
modelSolveRules('storage', 't_skip') = 24;
modelSolveRules('storage', 't_forecastLength') = 48;
modelSolveRules('storage', 't_interval') = 1;
mf('storage', fRealization) = yes;
p_stepLength(m, f, t)$(ord(f)=1 and ord(t)=1) = 0;   // set one p_stepLength value, so that unassigned values will not cause an error later

