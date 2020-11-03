* ===============================================================================
* --- eqDeclarations - Declaration of additional equations
* ===============================================================================

Equations
//Switching function between locally valid linearisation parameters in order to obtain a globally valid wastewater treatment plant model
q_ww_lowerLimit(grid, node, node_, ww_flowType, ww_range, s, f, t)        "Activates v_flagTransfer if flow is bigger than the lower limit of the flow range"
q_ww_upperLimit(grid, node, node_, ww_flowType, ww_range, s, f, t)        "Activates v_flagTransfer if flow is smaller than the upper limit of the flow range"
//Helper equations to limit the product of a binary and a continuous variable for the switching function
q_ww_limithelp1(grid, node, node_, ww_flowType, ww_range, s, f, t)        "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
q_ww_limithelp2(grid, node, node_, ww_flowType, ww_range, s, f, t)        "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
q_ww_limithelp3(grid, node, node_, ww_flowType, ww_range, s, f, t)        "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"

q_ww_flowSum(ww_flowType, s , f, t)                                       "Exactly one of the binary variables for each flow range has to equal one"

q_ww_transferShareInfluent(grid, node_, node, s, f, t)                 "The transfer of one node pair equals the transfer share depending on the transfer of another node pair"
q_ww_transferShareEffluent(grid, node, node_, s, f, t)                 "The transfer of one node pair equals the transfer share depending on the transfer of another node pair"

//Specific balance equation for the wastewater treatment reaction nodes
q_ww_balance(grid, node, mType, s, f, t)                                  "Reaction within the nodes of the wastewater reaction tank"

//Helper equations to limit the product of a binary and a continuous variable for the ww balance equation
q_ww_flagState1(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_helperState, the product of v_flowHelper and v_state"
q_ww_flagState2(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_helperState, the product of v_flowHelper and v_state"
q_ww_flagState3(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_helperState, the product of v_flowHelper and v_state"
;

* ===============================================================================
* --- constraints - Formulation of additional equations
* ===============================================================================

*------Switching function for linearisation parameters--------------------------

*------ Limits for switching function ------------------------------------------

q_ww_lowerLimit(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_inflowNodes')}
..

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

         =G=

         p_ww_threshold(ww_flowType, ww_range, 'lower')* v_flowFlag(ww_flowType, ww_range, s, f, t)

;

q_ww_upperLimit(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_inflowNodes')}//should only hold for inflow node and DO reaction ..
..

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

         =L=

         p_ww_threshold(ww_flowType, ww_range, 'upper')* v_flowFlag(ww_flowType, ww_range, s, f, t)

;

*------------- Helper equations to linearise the switching function ----------------

q_ww_limithelp1(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_inflowNodes')
           OR gn2nGroup(grid, node, node_,'ww_flagTransfer')
           OR gn2nGroup(grid, node, node_,'ww_effluent')}
..

         BIG_M * v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

;

q_ww_limithelp2(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_inflowNodes')
           OR gn2nGroup(grid, node, node_,'ww_flagTransfer')
           OR gn2nGroup(grid, node, node_,'ww_effluent')}
..

         v_transfer(grid, node, node_, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)
;

q_ww_limithelp3(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_inflowNodes')
           OR gn2nGroup(grid, node, node_,'ww_flagTransfer')
           OR gn2nGroup(grid, node, node_,'ww_effluent')}
..

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

         =G=

         v_transfer(grid, node, node_, s, f, t) - ((1- v_flowFlag(ww_flowType, ww_range, s, f, t))* BIG_M)
;

q_ww_flowSum(ww_flowType, sft(s , f, t))    //Ensures that v_flowFlag is one ONLY for one element in ww_range
..
         sum(ww_range, v_flowFlag(ww_flowType, ww_range, s, f, t)) =E= 1

;

q_ww_transferShareInfluent(gn2n_directional(grid, node, node_), sft(s, f, t))
         ${ gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..
         v_transfer(grid, node, node_, s, f, t)

         =E=

         p_gnn(grid, node, node_, 'transferCoeff') * v_transfer('wastewater', 'Inlet_Q', 'Q_reaction', s, f, t)
;

q_ww_transferShareEffluent(gn2n_directional(grid, node, node_), sft(s, f, t))
         ${ gn2nGroup(grid, node, node_,'ww_effluent')}
..
         v_transfer(grid, node, node_, s, f, t)

         =G=

         p_gnn(grid, node, node_, 'transferCoeff') * v_transfer('wastewater', 'Q_reaction', 'waterbody', s, f, t)
;

*------New balance equation for wastewater reaction nodes-----------------------

q_ww_balance(gn(grid, node), msft(m, s, f, t))${ gnGroup(grid, node, 'ww_reactionGroup')}
..

    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    + p_gn(grid, node, 'energyStoredPerUnitOfState')${gn_state(grid, node)} // Unit conversion between v_state of a particular node and
                                                                            // energy variables (defaults to 1, but can have node based values
                                                                            // if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
        * [
            v_state(grid, node, s, f+df_central(f,t), t)   // The difference between current
            - v_state(grid, node, s+ds_state(grid,node,s,t), f+df(f,t+dt(t)), t+dt(t))// ... and previous state of the node
         ]
    =E=

    // The right side of the equation contains all the changes converted to energy terms
//    + p_stepLength(m, f, t) // Multiply with the length of the timestep to convert power into energy
//        * (

            // Energy diffusion from neighbouring nodes to this node
            // in the WWTP model, this is influence of the other node's concentration on the node's concentration
            + sum(gnn_state(grid, from_node, node),
                + [p_gnn(grid, from_node, node, 'diffCoeff')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, node)
                               * v_flagState(grid, from_node, ww_flowType, ww_range, s, f+df_central(f,t), t)
                          )
                       )//END sum(ww_flowType)
                  ]
                ) // END sum(from_node)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(gn2n_directional(grid, from_node, node),
                + v_transfer(grid, from_node, node, s, f, t)
                * p_gnn(grid, from_node, node, 'transferCoeff')
                ) // END sum(node_)


            //Controlled energy transfer from neighbouring nodes to this node
            //In the WWTP model, this is the transfer from the storage/inlet nodes to the reaction node
            + sum(ww_flowType,
                 sum(gn2nFlowType(grid, from_node, node, ww_flowType)${gn2nGroup(grid, from_node, node, 'ww_flagTransfer')},
                    sum(ww_range,
                         + p_ww_dilution(ww_flowType, ww_range)
                         * v_flagTransfer(grid, from_node, node, ww_flowType, ww_range, s, f, t)
                    )
                )
              )//END sum(ww_flowType)


            //This is an addition of the WWTP model. It defines the part of the effluent concentration
            //that depends on inflow and airflow.
            - [p_gn(grid, node, 'selfDischargeLoss')*
              sum(gn2n_directional(grid, node, to_node)${gn2nGroup(grid, node, to_node, 'ww_effluent')},
                 sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, node)
                             * v_flagTransfer(grid, node, to_node, ww_flowType, ww_range, s, f, t)
                         )
                 )
               )
               ]

            //This is an addition of the WWTP model. It defines the part of the effluent concentration
            //that depends on the dilution factor.
            - sum(gn2n_directional(grid, node, to_node)${gn2nGroup(grid, node, to_node, 'ww_effluent')},
                 sum(ww_flowType,
                    sum(ww_range,
                    p_ww_dilution(ww_flowType, ww_range)
                      * v_flagTransfer(grid, node, to_node, ww_flowType, ww_range, s, f, t)
                    )
                 )
              )* (-1${gn2n_directional('wastewater', 'X_reaction', 'waterbody')})

            // Effluent
            - sum(gn2n_directional(grid, node, to_node)${gn2nGroup(grid, node, to_node, 'ww_effluent')},
                p_gn(grid, node, 'decay')          //if decay=0, then v_transfer will not be considered in energy balance
                                                       //(required for node 'S_reaction')
                * v_transfer(grid, node, to_node, s, f, t)
                )
$ontext
            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            - vq_gen('decrease', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
$offtext
//    ) // END * p_stepLength
;
*------- Helper Constraints for the new balance equation -----------------------

*------------ Constraints for binding the product variable v_flagState ---------

q_ww_flagState1(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flowFlag(ww_flowType, ww_range, s, f, t) * BIG_M

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f, t)
;

q_ww_flagState2(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_state(grid, node, s, f, t)

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f, t)

;

q_ww_flagState3(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flagState(grid, node, ww_flowType, ww_range, s, f, t)

         =G=

         v_state(grid, node, s, f, t) - [(1-v_flowFlag(ww_flowType, ww_range, s, f, t)) * BIG_M]
;







