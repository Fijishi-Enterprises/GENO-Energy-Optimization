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
execute_unload 'output/srin.gdx', ScenRedParms,
                                  s, ss, p_sProbability,
                                  ts_influx_, ts_cf_;
execute 'scenred2 inc/scenred.cmd';
execute_load 'output/srout.gdx', ScenRedReport,
                                 p_sProbability=red_prob;

* Update probabilities
p_msProbability(mSolve, s) = p_sProbability(s);

* Update sets
msft(mSolve, s, f, t)$msft(mSolve, s, f, t) = p_msProbability(mSolve, s);
sft(s, f, t)$sft(s, f, t) = p_msProbability(mSolve, s);
s_parallel(s)$s_parallel(s) = p_sProbability(s);

else
    put log "!!! No scenario reduction setting given, skipping scenario reduction!"/;
);

