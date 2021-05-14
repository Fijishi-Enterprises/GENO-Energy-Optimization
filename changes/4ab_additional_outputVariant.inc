*------------- Additional results symbols ---------------------------------------------------

* =============================================================================
* --- Realized parameter values  ---------------------------------------------
* =============================================================================
//$ontext
// --- Result arrays required by model dynamics --------------------------------
if(tSolveFirst >= mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod') - mSettings(mSolve, 't_jump')
   and firstResultsOutputSolve,
    loop(msf(mSolve, s, f_solve),
        firstResultsOutputSolve = 0;
        r_flagState(gn_state(grid, node), ww_flowType, ww_range, f_solve, t) $[ord(t) = mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
          = v_flagState.l(grid, node, ww_flowType, ww_range, s, f_solve, t);
    );
);
// Realized flag states
loop(sft_realized(s, f, t),
    r_flagState(gn_state(grid, node), ww_flowType, ww_range, f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_flagState.l(grid, node, ww_flowType, ww_range, s, f, t);

    // Realized state history - initial state values in samples
    r_flagState(gn_state(grid, node), ww_flowType, ww_range, f_solve(f), t+dt(t))${   ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')
                                                           and sum(ms(mSolve, s), mst_start(mSolve, s, t))
                                                       }
        = v_flagState.l(grid, node, ww_flowType, ww_range, s, f, t+dt(t));
); // END loop(m)

