* =============================================================================
* --- Save investments results in changes.inc file to be used in child setups -
* =============================================================================

* Output file streams
file f_changes /'output\changes.inc'/;

put f_changes

* Do not allow investments in the child setups
loop(unit,
    put "p_unit('", unit.tl:0, "', 'maxUnitCount') = 0;"/;
);

* Update the number of subunits in the child setups (rounded here to the nearest integer)
loop(unit${r_invest(unit)},
*    tmp = round(r_invest(unit), 0)
    tmp = r_invest(unit)
    put "p_unit('", unit.tl:0, "', 'unitCount') = p_unit('", unit.tl:0, "', 'unitCount') + ", tmp, ";"/;
);

* Update capacity values in the child setups
loop(gnu_input(grid, node, unit)${r_invest(unit)},
*    tmp = round(r_invest(unit), 0) * p_gnu(grid, node, unit, 'unitSize');
    tmp = r_invest(unit) * p_gnu(grid, node, unit, 'unitSize');
    put "p_gnu_io('", grid.tl:0, "', '", node.tl:0, "', '", unit.tl:0, "', 'input', 'capacity') = p_gnu_io('", grid.tl:0, "', '", node.tl:0, "', '", unit.tl:0, "', 'input', 'capacity') + ", tmp, ";"/;
);

loop(gnu_output(grid, node, unit)${r_invest(unit)},
*    tmp = round(r_invest(unit), 0) * p_gnu(grid, node, unit, 'unitSize');
    tmp = r_invest(unit) * p_gnu(grid, node, unit, 'unitSize');
    put "p_gnu_io('", grid.tl:0, "', '", node.tl:0, "', '", unit.tl:0, "', 'output', 'capacity') = p_gnu_io('", grid.tl:0, "', '", node.tl:0, "', '", unit.tl:0, "', 'output', 'capacity') + ", tmp, ";"/;
);

* Do not allow investments in the child setups (
loop(gn2n_directional(grid, node, node_),
    put "p_gnn('", grid.tl:0, "', '", node.tl:0, "', '", node_.tl:0, "', 'transferCapInvLimit') = 0;"/;
    put "p_gnn('", grid.tl:0, "', '", node_.tl:0, "', '", node.tl:0, "', 'transferCapInvLimit') = 0;"/;
);

* Update transmission capacity in the child setups
loop(gn2n_directional(grid, node, node_)${sum(t_invest, r_investTransfer(grid, node, node_, t_invest))},
    tmp = sum(t_invest, r_investTransfer(grid, node, node_, t_invest));
    put "p_gnn('", grid.tl:0, "', '", node.tl:0, "', '", node_.tl:0, "', 'transferCap') = p_gnn('", grid.tl:0, "', '", node.tl:0, "', '", node_.tl:0, "', 'transferCap') + ", tmp, ";"/;
    put "p_gnn('", grid.tl:0, "', '", node_.tl:0, "', '", node.tl:0, "', 'transferCap') = p_gnn('", grid.tl:0, "', '", node_.tl:0, "', '", node.tl:0, "', 'transferCap') + ", tmp, ";"/;
);

loop(gn_state(grid, node)${sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio')) },
    tmp = sum(gnu(grid, node, unit),
            + p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
                * p_gnu(grid, node, unit, 'unitSize')
                * r_invest(unit)

            );
    put "p_gnBoundaryPropertiesForStates('", grid.tl:0, "', '", node.tl:0, "', 'upwardLimit', 'constant') = p_gnBoundaryPropertiesForStates('",
      grid.tl:0, "', '", node.tl:0, "', 'upwardLimit', 'constant') +", tmp, ";"/;
    put "p_gnBoundaryPropertiesForStates('", grid.tl:0, "', '", node.tl:0, "', 'upwardLimit', 'useConstant') = 1;"/;
);

putclose;
