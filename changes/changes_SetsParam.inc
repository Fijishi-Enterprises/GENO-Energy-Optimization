*-------------Additional sets---------------------------------------------------
//Base sets
Sets

ww_range                               "Possible ranges for linearization parameters in waste water treatment model"
ww_flowType                            "Possible types of flows for ranges in waste water treatment model"
ww_lowerUpper                          "Lower or upper threshold for ranges in waste water treatment model"
     /lower, upper/
diff_direction                         "Direction of diffusion between nodes"
     /diff_in, diff_out/
;

alias(ww_flowType, ww_flowType_);
alias(ww_range, ww_range_);

//Aggregate sets and subsets
Sets

ww_flowRange(ww_flowType, ww_range)                                       "Ranges of flow in which linearization parameters are valid (e.g. low,mid,high)"
gn2nFlowType(grid, node, node_, ww_flowType)
;

*-----------Additional parameters-----------------------------------------------

Parameters

p_ww_threshold(ww_flowType, ww_range, ww_lowerUpper)                          "Lower and upper thresholds for flow ranges"
p_ww_A(ww_flowType, ww_range, node, node_, diff_direction)                    "Linearization parameters A for the wastewater treatment model"
p_ww_dilution(ww_flowType, ww_range, node, node_)                             "Dilution factor D in the waste water treatment model for different inflow ranges and node pairs"
p_ww_dilutionUnit(ww_flowType, ww_range, node, unit)                          "Dilution factor D in the waste water treatment model for different inflow ranges and node unit pairs"
;

