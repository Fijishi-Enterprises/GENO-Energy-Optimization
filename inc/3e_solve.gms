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

* --- Solve commands ----------------------------------------------------------

    if (mSolve('schedule'),
        schedule.holdfixed = 1; // Enable holdfixed, which makes the GAMS compiler convert fixed variables into parameters for the solver.
        solve schedule using mip minimizing v_obj;
    ); // END IF SCHEDULE

*    if (mSolve('building'),
*        solve building using mip minimizing v_obj;
*    ); // END IF BUILDING
*    if (mSolve('storage'),    solve storage    using lp   minimizing v_obj; );
    if (mSolve('invest'),
        invest.holdfixed = 1; // Enable holdfixed, which makes the GAMS compiler convert fixed variables into parameters for the solver.
        solve invest using mip minimizing v_obj;
    );
