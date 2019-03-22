* Ensure scenario reduction setting are given
if(mSettings(mSolve, 'red_num_leaves')
   or mSettings(mSolve, 'red_percentage'),

* Get probabilitiesfor samples
p_sProbability(s_active(s)) = p_msProbability(mSolve, s);

* SCENRED2 parameters
ScenRedParms('red_num_leaves') = min(mSettings(mSolve, 'red_num_leaves'),
                                     mSettings(mSolve, 'scenarios'));
ScenRedParms('red_percentage') = mSettings(mSolve, 'red_percentage');
ScenRedParms('scen_red') = 1$mSettings(mSolve, 'red_num_leaves'); // Reduce scenarios
ScenRedParms('tree_con') = 1$mSettings(mSolve, 'red_percentage');  // Tree construction
*ScenRedParms('report_level') = 2;
ScenRedParms('run_time_limit') = 30;
$ifthene %debug%>1
ScenRedParms('visual_init') = 1;
ScenRedParms('visual_red') = 1;
$endif

* Export data
execute_unload 'srin.gdx', ScenRedParms,
                           s_active, ss, p_sProbability,
                           ts_influx_, ts_cf_;
* Choose right null device
$ifthen %system.filesys% == 'MSNT' $set nuldev NUL
$else $set nuldev /dev/null
$endif
* Execute SCENRED2 and load data
put log "Executing SCENRED2"/; putclose log;
execute 'scenred2 inc/scenred.cmd > %nuldev%';

if(errorLevel,
    put log "!!! Scenario reduction (SCENRED2) failed. ";
    put log "See file 'sr.log' for details."/;
    putclose;
    execError = execError + 1;
else
    execute_load 'srout.gdx', ScenRedReport,
                              ss=red_ancestor,
                              p_sProbability=red_prob;

    // Update probabilities
    p_msProbability(mSolve, s) = p_sProbability(s);

    // Update sets
    ms(mSolve, s)$ms(mSolve, s) = yes$p_msProbability(mSolve, s);
    msf(mSolve, s, f)$msf(mSolve, s, f) = ms(mSolve, s);
    msft(mSolve, s, f, t)$msft(mSolve, s, f, t) = msf(mSolve, s, f);
    sft(s, f, t)$sft(s, f, t) = yes$p_msProbability(mSolve, s);

    // Update scenarios
    Option clear = s_scenario;
    count = 1;
    loop((mft_lastSteps(mSolve, f, t), msft(mSolve, s_, f, t)),  // Select each leaf sample
        Option clear = s_prev; s_prev(s_) = yes;
        loop(scenario$(ord(scenario) = count),
            s_scenario(s_, scenario) = yes;
            tmp = 0;
            repeat(
                loop(ss(s__, s)$s_prev(s__),
                    s_scenario(s, scenario) = yes;
                    Option clear = s_prev; s_prev(s) = yes;
                    tmp = ms_initial(mSolve, s);
                );
            until tmp);
        );
        count = count + 1;
    );

    // Clear data from removed samples
    ts_influx_(gn, ft, s_active(s))$(not p_sProbability(s)) = 0;
    ts_cf_(flowNode, ft, s_active(s))$(not p_sProbability(s)) = 0;

    s_active(s)$s_active(s) = yes$p_sProbability(s);
);

else
    put log "!!! No scenario reduction setting given, skipping scenario reduction!"/;
);
