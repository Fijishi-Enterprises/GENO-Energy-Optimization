    if (mSolve('schedule'),
        settings(mSetting) = mSettings(mSolve, mSetting);
        solve schedule   using mip   minimizing v_obj;
        tDispatchCurrent = 0;
        put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_', tDispatchCurrent:0:0, '.gdx';
        $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information
        loop(restypeDirectionNode(restypeDirection(restype, up_down), node),
             if (not mod(tSolveFirst-1, p_nReserves(node, restype, 'update_frequency')),
                 v_reserve.fx(nuRescapable(restype, up_down, node, unit_elec), ft(f,t))$( nuft(node, unit_elec, f, t)
                                                                                                and ord(t) > p_nReserves(node, restype, 'gate_closure')
                                                                                                and ord(t) <= p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'gate_closure')
                                                                                             )
                   = v_reserve.l(restype, up_down, node, unit_elec, f, t);
             );
        );

        tSolveDispatch(t) = no;
        tSolveDispatch(t)$(ord(t) >= tSolveFirst and ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')) = yes;
        loop(tSolveDispatch,
            tDispatchCurrent = tDispatchCurrent + 1;
            $$include 'defModels\periodicLoopDispatch.gms';

            loop(restypeDirectionNode(restypeDirection(restype, up_down), node),
                v_reserve.fx(nuRescapable('tertiary', up_down, node, unit_elec), ft_realized(f,t))$nuft(node, unit_elec, f, t) = 0;
            );

            solve schedule_dispatch    using mip    minimizing v_obj;
            put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_d', tDispatchCurrent:0:0, '.gdx';
            $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information

            // Remaining solves will use bound start value for v_state once it has been established
            v_state.fx(grid, node, ft_limits(f, t))$(gn_state(grid,node) and tSolveDispatch(t))
              = v_state.l(grid, node, f, t);
            // Remaining solves
            v_online.fx(uft_limits_online(unit, f, t))$(ord(t) = tDispatchCurrent + 1) = round(v_online.l(unit, f, t));

        );
    );
*    if (mSolve('storage'),    solve storage    using lp   minimizing v_obj; );
