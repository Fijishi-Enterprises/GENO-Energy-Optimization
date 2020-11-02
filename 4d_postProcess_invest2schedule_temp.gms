* =============================================================================
* --- Save investments results in changes.inc file to be used in child setups -
* =============================================================================

* Output file streams
file f_changes /'output\changes.inc'/;

f_changes.lw = 26; // Field width of set label output, default in GAMS is 12, increase as needed

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
