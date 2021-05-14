*------------- Additional results symbols ---------------------------------------------------

* =============================================================================
* --- Time Step Dependent Results ---------------------------------------------
* =============================================================================

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,

    // Incoming diffusion of a node in t
    r_incomingDiffusion(gnn_state(grid, from_node, node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = + p_gnn(grid, from_node, node, 'diffCoeff_in')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, from_node, node, 'diff_in')
                             * p_ww_dilution(ww_flowType, ww_range, from_node, node)
                        * r_flagState(grid, node, ww_flowType, ww_range, f, t)
                     )) // END sum(ww_flowType)
    ;

    // Outgoing diffusion of a node in t
    r_outgoingDiffusion(gnn_state(grid, node, to_node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = + p_gnn(grid, node, to_node, 'diffCoeff_out')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, node, to_node, 'diff_out')
                             * p_ww_dilution(ww_flowType, ww_range, node, to_node)
                        * r_flagState(grid, node, ww_flowType, ww_range, f, t)
                     )) // END sum(ww_flowType)
   ;

); // END loop(m)
//$offtext
