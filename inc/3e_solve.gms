$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

    if (mSolve('schedule'),
        settings(mSetting) = mSettings(mSolve, mSetting);
        solve schedule   using mip   minimizing v_obj;

            aaSolveInfo('schedule', tSolve, 'modelStat') = schedule.modelStat;
            aaSolveInfo('schedule', tSolve, 'solveStat') = schedule.solveStat;
            aaSolveInfo('schedule', tSolve, 'totalTime') = schedule.etSolve;
            aaSolveInfo('schedule', tSolve, 'iterations') = schedule.iterUsd;
            aaSolveInfo('schedule', tSolve, 'nodes') = schedule.nodUsd;
            aaSolveInfo('schedule', tSolve, 'numEqu') = schedule.numEqu;
            aaSolveInfo('schedule', tSolve, 'numDVar') = schedule.numDVar;
            aaSolveInfo('schedule', tSolve, 'numVar') = schedule.numVar;
            aaSolveInfo('schedule', tSolve, 'numNZ') = schedule.numNZ;
            aaSolveInfo('schedule', tSolve, 'sumInfes') = schedule.sumInfes;
            aaSolveInfo('schedule', tSolve, 'objEst') = schedule.objEst;
            aaSolveInfo('schedule', tSolve, 'objVal') = schedule.objVal;

        put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_', tDispatchCurrent:0:0, '.gdx';
        $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information
        loop(restypeDirectionNode(restypeDirection(restype, up_down), node),
             if (not mod(tSolveFirst-1, p_nReserves(node, restype, 'update_frequency')),
                 v_reserve.fx(nuRescapable(restype, up_down, node, unit_elec), ft(f,t))$( nuft(node, unit_elec, f, t)
                                                                                                and ord(t) > p_nReserves(node, restype, 'gate_closure')
                                                                                                and ord(t) <= p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'gate_closure')
                                                                                                and not unit_flow(unit_elec)           // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
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

            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'modelStat') = schedule_dispatch.modelStat;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'solveStat') = schedule_dispatch.solveStat;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'totalTime') = schedule_dispatch.etSolve;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'iterations') = schedule_dispatch.iterUsd;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'nodes') = schedule_dispatch.nodUsd;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'numEqu') = schedule_dispatch.numEqu;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'numDVar') = schedule_dispatch.numDVar;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'numVar') = schedule_dispatch.numVar;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'numNZ') = schedule_dispatch.numNZ;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'sumInfes') = schedule_dispatch.sumInfes;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'objEst') = schedule_dispatch.objEst;
            aaSolveInfo('schedule_dispatch', tSolveDispatch, 'objVal') = schedule_dispatch.objVal;

            put_utility 'gdxout' / 'output\debug_', tSolveFirst:0:0, '_d', tDispatchCurrent:0:0, '.gdx';
            $$ifi '%debug%' == 'yes' execute_unload;   // Output debugging information

            // Remaining solves will use bound start value for v_state once it has been established
            v_state.fx(gn_state(grid, node), ft_fix(f,t)) = v_state.l(grid, node, f, t);
            // Remaining solves
            v_online.fx(uft_online(unit, ft_fix(f, t))) = round(v_online.l(unit, f, t));
            //v_startup.fx(uft_limits_online(unit, ft_fix(f,t))) = v_startup.l(unit,f,t);
            //v_gen.fx(gnu(grid, node, unit), ft_fix(f, t)) = v_gen.l(grid, node, unit, f, t);
            //v_spill.fx(gn(grid, node), ft_fix(f, t)) = v_spill.l(grid, node, f, t);
            //vq_gen.fx(inc_dec, gn(grid, node), ft_fix(f, t)) = vq_gen.l(inc_dec, grid, node, f, t);
        );
    ); // END IF SCHEDULE

*    if (mSolve('building'),
*        solve building using mip minimizing v_obj;
*    ); // END IF BUILDING
*    if (mSolve('storage'),    solve storage    using lp   minimizing v_obj; );
