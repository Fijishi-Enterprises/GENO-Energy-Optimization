    if (mSolve('schedule'),
        solve schedule   using mip   minimizing v_obj;
        tDispatchCurrent = 0;
        put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_', tDispatchCurrent:0:0, '.gdx';
        $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information
        tSolveDispatch(t) = no;
        tSolveDispatch(t)$(ord(t) >= tSolveFirst and ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')) = yes;
        loop(tSolveDispatch,
            tDispatchCurrent = tDispatchCurrent + 1;
            $$include 'defModels\periodicLoopDispatch.gms';
            solve schedule_dispatch    using mip    minimizing v_obj;
            put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_d', tDispatchCurrent:0:0, '.gdx';
            $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information

            // Remaining solves will use bound start value for v_state once it has been established
            v_state.fx(grid, node, ft_limits(f, t))$(gn_state(grid,node) and ord(t) = tDispatchCurrent + 1)
              = v_state.l(grid, node, f, t);
            // Remaining solves
            v_online.fx(uft_limits_online(unit, f, t))$(ord(t) = tDispatchCurrent + 1) = round(v_online.l(unit, f, t));
        );
    );
*    if (mSolve('storage'),    solve storage    using lp   minimizing v_obj; );
