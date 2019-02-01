* Ensure scenario reduction setting are given
if(mSettings(mSolve, 'red_num_leaves')
   or mSettings(mSolve, 'red_percentage'),

* Get probabilitiesfor samples
p_sProbability(s)$ms(mSolve, s) = p_msProbability_orig(mSolve, s);

* SCENRED2 parameters
ScenRedParms('red_num_leaves') = mSettings(mSolve, 'red_num_leaves');
ScenRedParms('red_percentage') = mSettings(mSolve, 'red_percentage');
ScenRedParms('scen_red') = 1;  // Reduce scenarios
ScenRedParms('tree_con') = 0;  // No tree construction
*ScenRedParms('report_level') = 2;
ScenRedParms('run_time_limit') = 30;
$ifthen %debug% == 'yes'
ScenRedParms('visual_init') = 1;
ScenRedParms('visual_red') = 1;
$endif

* Data exchange and execute SCENRED2
execute_unload 'srin.gdx', ScenRedParms,
                                  s, ss, p_sProbability,
                                  ts_influx_, ts_cf_;
execute 'scenred2 inc/scenred.cmd';
if(errorLevel, abort "Scenario reduction (SCENRED2) failed");
execute_load 'srout.gdx', ScenRedReport,
                          p_sProbability=red_prob;

* Update probabilities
p_msProbability(mSolve, s) = p_sProbability(s);

* Update sets
s_active(s) = p_sProbability(s);
msft(mSolve, s, f, t)$msft(mSolve, s, f, t) = s_active(s);
sft(s, f, t)$sft(s, f, t) = s_active(s);

* Clear data from removed samples
ts_influx_(gn, ft, s)$(not s_active(s)) = 0;
ts_cf_(flowNode, ft, s)$(not s_active(s)) = 0;


else
    put log "!!! No scenario reduction setting given, skipping scenario reduction!"/;
);

