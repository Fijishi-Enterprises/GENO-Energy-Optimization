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
* --- Fixing some variable values after solve ---------------------------------
* =============================================================================
    // Fix non-flow unit reserves ahead of time
    // Upper bound can be supplemented from the tertiary reserves when realized.
    v_reserve.fx(nuRescapable(restype, up_down, node, unit), f_solve(f), t_active(t))${ mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time periods that should be fixed
                                                                                        and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                                        and not unit_flow(unit) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
                                                                                        }
        = v_reserve.l(restype, up_down, node, unit, f, t);

    vq_resDemand.fx(restypeDirectionNode(restype, up_down, node), f_solve(f), t_active(t))${ mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time periods that should be fixed
                                                                                        and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                                        }
        = vq_resDemand.l(restype, up_down, node, f, t);

