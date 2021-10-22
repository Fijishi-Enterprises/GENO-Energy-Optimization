* Ensure scenario reduction setting are given
if(mSettings(mSolve, 'red_num_leaves')
   or mSettings(mSolve, 'red_percentage'),

    // Get probabilitiesfor samples
    Option clear = p_sProbability;
    p_sProbability(s_active(s)) = p_msProbability(mSolve, s);

    // SCENRED2 parameters
    ScenRedParms('red_num_leaves') = min(mSettings(mSolve, 'red_num_leaves'),
                                     mSettings(mSolve, 'scenarios'));
    ScenRedParms('red_percentage') = mSettings(mSolve, 'red_percentage');
    ScenRedParms('scen_red') = 1$mSettings(mSolve, 'red_num_leaves'); // Reduce scenarios
    ScenRedParms('tree_con') = 1$mSettings(mSolve, 'red_percentage');  // Tree construction
    //ScenRedParms('report_level') = 2;
    ScenRedParms('run_time_limit') = 30;

$ifthene.debug3 %debug%>1
    ScenRedParms('visual_init') = 1;
    ScenRedParms('visual_red') = 1;
$endif.debug3

    // Calculate data for scenario reduction
    Option clear = ts_energy_;
    ts_energy_(s)
        = sum(sft(s, f, t)$mf_central(mSolve, f),
              sum(gn(grid, node),
                  ts_influx_(grid, node, s, f, t)
                   + sum((flowNode(flow, node), flowUnit(flow, unit))
                          $gnu_output(grid, node, unit),
                         ts_cf_(flow, node, s, f, t)
                          * p_gnu(grid, node, unit, 'capacity')
                     )
              ) * p_stepLength(mSolve, f, t)
          );

    // Export data
    execute_unload 'srin.gdx', ScenRedParms,
                           s_active, ss, p_sProbability,
                           ts_energy_;

    // Choose right null device
$ifthen.nullDevice %system.filesys% == 'MSNT' $set nuldev NUL
$else.nullDevice $set nuldev /dev/null
$endif.nullDevice

    // Execute SCENRED2 and load data
    put log "Executing SCENRED2"/; putclose log;
    execute 'scenred2 inc/scenred.cmd > %nuldev%';

    if(errorLevel,
        put log "!!! Scenario reduction (SCENRED2) failed. ";
        put log "See file 'sr.log' for details."/;
        put_utility log, 'Click' / 'sr.log';
        putclose;
        execError = execError + 1;
    else
        execute_load 'srout.gdx', ScenRedReport,
                                  ss=red_ancestor,
                                  p_sProbability=red_prob;

        // Update probabilities
        // Account for small errors from SCENRED2 where the probability of a single
        // scenario can be slightly above one.
        p_msProbability(mSolve, s) = min(p_sProbability(s), 1);

        // Update scenarios
        loop(mft_lastSteps(mSolve, f, t), // Select last time step
            // Select each scenario and the leaf sample of the scenario (using non-reduced msft)
            loop((scenario, msft(mSolve, s_, f, t))$s_scenario(s_, scenario),
                // Drop scenarios with zero probability
                s_scenario(s, scenario)$(not p_msProbability(mSolve, s_)) = no;
                // Build scenarios starting from the leaf samples
                Option clear = s_prev; s_prev(s_) = yes;
                tmp = 0;
                // Re-construct scenarios left from reduction
                while(not tmp and p_msProbability(mSolve, s_),
                    loop(ss(s__, s)$s_prev(s__),
                        s_scenario(s, scenario) = yes$p_msProbability(mSolve, s);
                        Option clear = s_prev; s_prev(s) = yes;
                        tmp = ms_initial(mSolve, s);
                    );
                );
            );
        );

$ifthene.debug2 %debug%>0
            put log "Used scenarios are:"/;
            loop((ms_initial(mSolve, s), s_scenario(s, scenario)),
                put log scenario.tl/;
            );
            putclose log;
$endif.debug2

        // Update sets
        sft(s, f, t)$sft(s, f, t) = yes$p_msProbability(mSolve, s);

        // Update the model specific sets and the reversed dimension set
        Options clear mft, cear=ms, clear=msf, clear=ms_central, clear=msft;
        msft(mSolve, sft(s, f, t)) = yes;
        Options mft < msft, ms < msft, msf < msft, mst < msft;
        Option ms_central < ms;

        mst_start(mSolve, s, t)$mst_start(mSolve, s, t) = ms(mSolve, s);
        mst_end(mSolve, s, t)$mst_end(mSolve, s, t) = ms(mSolve, s);

        // Clear data from removed samples
        ts_influx_(gn, s_active(s), ft)$(not p_sProbability(s)) = 0;
        ts_cf_(flowNode, s_active(s), ft)$(not p_sProbability(s)) = 0;
        ts_node_(gn, param_gnBoundaryTypes, s_active(s), ft)$(not p_sProbability(s)) = 0;

        s_active(s)$s_active(s) = yes$p_sProbability(s);
    );

else
    put log "!!! No scenario reduction setting given, skipping scenario reduction!"/;
);
