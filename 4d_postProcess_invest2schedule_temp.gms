* =============================================================================
* --- Save investments results in changes.inc file to be used in child setups -
* =============================================================================

* Output file streams
file f_changes /'output\changes.inc'/;

f_changes.lw = 26; // Field width of set label output, default in GAMS is 12, increase as needed
f_changes.pw = 500; // Number of characters that may be placed on a single row of the page, default in GAMS is 255, increase as needed

put f_changes

* Do not allow investments in the child setups
loop(unit,
    put "p_unit('", unit.tl, "', 'maxUnitCount') = 0;"/;
);

* Update the number of subunits in the child setups (rounded here to the nearest integer)
loop(unit${r_invest(unit)},
    tmp = round(r_invest(unit), 0)
    put "p_unit('", unit.tl, "', 'unitCount') = p_unit('", unit.tl, "', 'unitCount') + ", tmp, ";"/;
);
* Update capacity values in the child setups
loop(gnu(grid, node, unit)${r_invest(unit)},
    tmp = round(r_invest(unit), 0) * p_gnu(grid, node, unit, 'unitSize');
    put "p_gnu('", grid.tl, "', '", node.tl, "', '", unit.tl, "', 'capacity') = p_gnu('", grid.tl, "', '", node.tl, "', '", unit.tl, "', 'capacity') + ", tmp, ";"/;);

* Example updates for storage units (commented out at the moment, use names etc. that work in your case)
*p_gnBoundaryPropertiesForStates('battery_grid', 'battery_node', 'upwardLimit', 'useConstant') = 1;
*p_gnBoundaryPropertiesForStates('battery_grid', 'battery_node', 'upwardLimit', 'multiplier') = 1;
*p_gnBoundaryPropertiesForStates('battery_grid', 'battery_node', 'upwardLimit', 'constant')
*    = p_gnu('battery_grid', 'battery_node', 'battery_charge', 'upperLimitCapacityRatio') * p_gnu('battery_grid', 'battery_node', 'battery_charge', 'capacity');
*p_gnu('battery_grid', 'battery_node', 'battery_charge', 'upperLimitCapacityRatio') = 0;
*uGroup('battery_charge', 'battery_online_group1') = yes;
*uGroup('battery_discharge', 'battery_online_group1') = yes;
*p_groupPolicy('battery_online_group1', 'constrainedOnlineTotalMax') = p_unit('battery_charge', 'unitCount');
*p_groupPolicy3D('battery_online_group1', 'constrainedOnlineMultiplier', 'battery_charge') = 1;
*p_groupPolicy3D('battery_online_group1', 'constrainedOnlineMultiplier', 'battery_discharge') = 1;

* Do not allow investments in the child setups (commented out at the moment)
*loop(gn2n_directional(grid, node, node_),
*    put "p_gnn('", grid.tl, "', '", node.tl, "', '", node_.tl, "', 'transferCapMax') = 0;"/;
*    put "p_gnn('", grid.tl, "', '", node_.tl, "', '", node.tl, "', 'transferCapMax') = 0;"/;
*);

* Update transmission capacity in the child setups
loop(gn2n_directional(grid, node, node_)${sum(t_invest, r_investTransfer(grid, node, node_, t_invest))},
    tmp = sum(t_invest, r_investTransfer(grid, node, node_, t_invest));
    put "p_gnn('", grid.tl, "', '", node.tl, "', '", node_.tl, "', 'transferCap') = p_gnn('", grid.tl, "', '", node.tl, "', '", node_.tl, "', 'transferCap') + ", tmp, ";"/;
    put "p_gnn('", grid.tl, "', '", node_.tl, "', '", node.tl, "', 'transferCap') = p_gnn('", grid.tl, "', '", node_.tl, "', '", node.tl, "', 'transferCap') + ", tmp, ";"/;
);

putclose;
