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
    // Fix non-flow unit reserves at the gate closure of reserves
    v_reserve.fx(nuRescapable(restype, up_down, node, unit), f_solve(f), t_active(t))
        $ { mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time intervals that should be fixed
            and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
            and not unit_flow(unit) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
          }
      = v_reserve.l(restype, up_down, node, unit, f, t);

    // Fix transfer of reserves at the gate closure of reserves
    v_resTransferRightward.fx(restypeDirectionNode(restype, up_down, node), node_, f_solve(f), t_active(t))
        $ { sum(grid, gn2n(grid, node, node_))
            and mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time intervals that should be fixed
            and mft_nReserves(node_, restype, mSolve, f, t)
            and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
          }
      = v_resTransferRightward.l(restype, up_down, node, node_, f, t);

    v_resTransferLeftward.fx(restypeDirectionNode(restype, up_down, node), node_, f_solve(f), t_active(t))
        $ { sum(grid, gn2n(grid, node, node_))
            and mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time intervals that should be fixed
            and mft_nReserves(node_, restype, mSolve, f, t)
            and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
          }
      = v_resTransferLeftward.l(restype, up_down, node, node_, f, t);

    // Fix slack variable for reserves that is used before the reserves need to be locked (vq_resMissing is used after this)
    vq_resDemand.fx(restypeDirectionNode(restype, up_down, node), f_solve(f), t_active(t))
        $ { mft_nReserves(node, restype, mSolve, f, t)  // This set contains the combination of reserve types and time intervals that should be fixed
            and ord(t) > mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
          }
      = vq_resDemand.l(restype, up_down, node, f, t);


$ontext
// Release some fixed values

// Release BoundEnd for the last time periods in the previous solve
v_state.up(grid, node, ft(f,t))${   mft_lastSteps(mSolve, f, t)
                                    and p_gn(grid, node, 'boundEnd')
                                }
    = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// BoundEnd to a timeseries value
v_state.fx(grid, node, ft(f,t))${   mft_lastSteps(mSolve, f, t)
                                    and p_gn(grid, node, 'boundEnd')
                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                }
    = ts_node_(grid, node, 'reference', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
$offtext
