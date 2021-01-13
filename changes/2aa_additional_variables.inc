*---------------------Additional variables--------------------------------------

Binary variables
         v_flowFlag(ww_flowType, ww_range, s, f, t)                             "Flag for the respective flow range [one if inflow lies within respective range]"
;

Positive variables
         v_flagState(grid, node, ww_flowType, ww_range, s, f, t)                                      "The product of v_state and the binary v_flowHelper"
         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)                            "The product of v_transfer and the binary v_flowFlag"
;

