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


* =============================================================================
* --- Controlling the use of previous solutions to have a first guess ---------
* =============================================================================
* 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

    if (mSettings(mSolve, 'loadPoint') = 1 and solveCount > 1,
        put_utility 'gdxin' / mSolve.tl:0 '_p.gdx';
        execute_loadpoint;
    elseif mSettings(mSolve, 'loadPoint') = 2,
        put_utility 'gdxin' / 'schedule_p' solveCount:0:0 '.gdx';
        execute_loadpoint;
    elseif mSettings(mSolve, 'loadPoint') = 3 and solveCount = 1,
        put_utility 'gdxin' / mSolve.tl:0 '_p.gdx';
        execute_loadpoint;
    );

    if (mSettings(mSolve, 'savePoint') = 1,
        option savepoint = 1;
    elseif mSettings(mSolve, 'savePoint') = 2,
        option savepoint = 2;
    elseif mSettings(mSolve, 'savePoint') = 3 and solveCount = 1,
        option savepoint = 1;
    elseif mSettings(mSolve, 'savePoint') = 3 and solveCount > 1,
        option savepoint = 0;
    );


* =============================================================================
* --- Solve Commands ----------------------------------------------------------
* =============================================================================

    if (mSolve('schedule'),
        schedule.holdfixed = 1; // Enable holdfixed, which makes the GAMS compiler convert fixed variables into parameters for the solver.
        schedule.OptFile = 1;
        solve schedule using mip minimizing v_obj;
    ); // END IF SCHEDULE

    if (mSolve('building'),
        building.holdfixed = 1;
        building.OptFile = 1;
        solve building using mip minimizing v_obj;
    ); // END IF BUILDING

    if (mSolve('invest'),
        invest.holdfixed = 1; // Enable holdfixed, which makes the GAMS compiler convert fixed variables into parameters for the solver.
        invest.OptFile = 1;
        solve invest using mip minimizing v_obj;
    ); // END IF INVEST



