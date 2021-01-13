* ===============================================================================
* --- eqDeclarations - Declaration of additional equations
* ===============================================================================

Equations
//General comments: s is the set for samples (only one sample in use here), f is the forecast used (deterministic model, so
//only one forecast f00), t is the time stamp
//node is aliased with node_ to indicate the relation to another related node
// Equation numbers correspond to numbers in the manuscript in Overleaf

//Switching function between locally valid linearisation parameters in order to obtain a globally valid wastewater treatment plant model
//The linearisation parameters change according to the level of water inflow into the plant
//Eq. 45 and 47
q_ww_lowerLimit(grid, node, node_, ww_flowType, ww_range, s, f, t)  "Activates v_flagTransfer if flow is bigger than the lower limit of the flow range"
//Eq. 46 and 48
q_ww_upperLimit(grid, node, node_, ww_flowType, ww_range, s, f, t)  "Activates v_flagTransfer if flow is smaller than the upper limit of the flow range"
//Eq. 35,36
q_ww_flowSum(ww_flowType, s , f, t)                                 "Exactly one of the binary variables for each flow range has to equal one"

//Specific balance equation for the wastewater treatment reaction nodes
//Eq. 25 (eq. 30)
q_ww_balance(grid, node, mType, s, f, t)                          "Reaction within the nodes of the wastewater reaction tank"

//Helper equations to limit the product of a binary and a continuous variable
//Eq. 37
q_ww_flagTransfer1(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
//Eq. 38
q_ww_flagTransfer2(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
//Eq. 39
q_ww_flagTransfer3(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"

//Eq. 37
q_ww_flagState1(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
//Eq. 38
q_ww_flagState2(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
//Eq. 39
q_ww_flagState3(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"

//Potential additional constraint that bound the transfer shares, the transfer to waterbody and the decay of X to its state variable
//q_ww_transferShareInfluent(grid, node_, node, s, f, t)            "The transfer of one node pair equals the transfer share depending on the transfer of another node pair"
//q_ww_transferShareEffluent(grid, node, node_, s, f, t)            "The transfer of one node pair equals the transfer share depending on the transfer of another node pair"
//q_ww_spillstate(grid, node, s, f , t)                             "Ensures that v_spill equals v_state for the node X_reaction"
//q_ww_transferstate(grid, node, s, f, t)                           "Ensures that v_transfer equals v_state for the reaction nodes"
;

* ===============================================================================
* --- constraints - Formulation of additional equations
* ===============================================================================

*------Switching function for linearisation parameters--------------------------

*------ Limits for switching function ------------------------------------------
//Equations 45-48 in the manuscript
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
//Equation 35(36) in manuscript
q_ww_flowSum(ww_flowType, sft(s , f, t))    //Ensures that v_flowFlag is one ONLY for one element in ww_range
..
         sum(ww_range, v_flowFlag(ww_flowType, ww_range, s, f, t)) =E= 1

;

*------New balance equation for wastewater reaction nodes-----------------------
//This corresponds to eq. 25 and eq. 30

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
            // Self discharge out of the model boundaries
            - p_gn(grid, node, 'selfDischargeLoss')${ gn_state(grid, node) }
                * v_state(grid, node, s, f+df_central(f,t), t) // The current state of the node

            // Energy diffusion from this node to neighbouring nodes
            // in the WWTP model, this is the influence of this node's concentration on the other node's concentration
            - sum(gnn_state(grid, node, to_node),
                + [p_gnn(grid, node, to_node, 'diffCoeff_out')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, node, to_node, 'diff_out')
                             * v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)
                          )
                       )//END sum(ww_flowType)
                  ]
                ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            // in the WWTP model, this is the influence of the other node's concentration on the node's concentration
            + sum(gnn_state(grid, from_node, node),
                + [p_gnn(grid, from_node, node, 'diffCoeff_in')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, from_node, node, 'diff_in')
                             * v_flagState(grid, from_node, ww_flowType, ww_range, s, f+df_central(f,t), t)
                          )
                       )//END sum(ww_flowType)
                  ]
                ) // END sum(from_node)


            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(gn2n_directional(grid, node, node_),
                  sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_dilution(ww_flowType, ww_range, node, node_)
                             * v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)
                         )
                  )
              ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(gn2n_directional(grid, node_, node),
                  sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_dilution(ww_flowType, ww_range, node_, node)
                             * v_flagTransfer(grid, node_, node, ww_flowType, ww_range, s, f, t)
                         )
                  )
              ) // END sum(node_)

            // Decay (if represented by spill - can also be represented as self discharge)
            - ( p_gn(grid, node, 'decay')
                * v_spill(grid, node, s, f, t)${node_spill(node)}
                )

            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            - vq_gen('decrease', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
;
*------- Helper Constraints for the products of continuous variables and the binary v_flowFlag ---------

*------------- Constraints for binding the product of v_transfer and v_flowFlag ------------------------
//Eq. 37
q_ww_flagTransfer1(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         BIG_M * v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

;
//Eq. 38
q_ww_flagTransfer2(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         v_transferRightward(grid, node, node_, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)
;
//Eq. 39
//(Eq. 40 being implied by v_flagTransfer defined as a positive variable)
q_ww_flagTransfer3(gn2nFlowType(grid, node, node_, ww_flowType), ww_range, sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

         =G=

         v_transferRightward(grid, node, node_, s, f, t) - ((1- v_flowFlag(ww_flowType, ww_range, s, f, t))* BIG_M)
;

*------------ Constraints for binding the product of v_state and v_flowFlag ---------
//Eq. 37
q_ww_flagState1(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flowFlag(ww_flowType, ww_range, s, f, t) * BIG_M

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)
;
//Eq. 38
q_ww_flagState2(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_state(grid, node, s, f+df_central(f,t), t)

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)

;
//Eq. 39
//(Eq. 40 being implied by v_flagState defined as a positive variable)
q_ww_flagState3(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)

         =G=

         v_state(grid, node, s, f+df_central(f,t), t) - [(1-v_flowFlag(ww_flowType, ww_range, s, f, t)) * BIG_M]
;

$ontext
*------------ Potential additional constraints to ensure proper behaviour of the wastewater treatment model ----------------
q_ww_transferShareInfluent(gn2n_directional(grid, node, node_), sft(s, f, t))
         ${ gn2nGroup(grid, node, node_,'ww_influent')}
..
         v_transfer(grid, node, node_, s, f, t)

         =G=

         p_gnn(grid, node, node_, 'transferCoeff') * v_transfer('wastewater', 'Inlet_Q', 'Q_reaction', s, f, t)
//Can be used to ensure that concentration is not passed on from storage tank to the reaction tank without a wastewater flow.
//Not required if storage tank has zero storage capabilities, but might be required later, if wastewater can be withhold from treatment.
;

q_ww_transferShareEffluent(gn2n_directional(grid, node, node_), sft(s, f, t))
         ${ gn2nGroup(grid, node, node_,'ww_effluent')}
..
         v_transfer(grid, node, node_, s, f, t)

         =G=

         p_gnn(grid, node, node_, 'transferCoeff') * v_transfer('wastewater', 'Q_reaction', 'waterbody', s, f, t)
//Can be used to ensure that concentration is not passed on from the reaction tank to the waterbody without a wastewater flow.
//Not sure whether this will be required, since the reaction tank does not have storage capabilities.
;

q_ww_spillstate(gn(grid, node), sft(s, f , t))
..
         v_spill(grid, node, s, f, t)${node_spill(node)}  =E= v_state(grid, node, s, f+df_central(f,t), t)${node_spill(node)}
//A fixed share of microorganisms X decays in every time step. This could be represented in Backbone as self discharge or spill. If the decay is spilled,
//v_spill should be bound to the state variable v_state, because the spilled concentration cannot vary from the concentration within the tank.
;

q_ww_transferstate(gn(grid, node), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_reactionGroup')}
..
         sum(gn2n_directional('wastewater', node, 'waterbody'), v_transfer('wastewater', node, 'waterbody', s, f, t))

         =E=

         v_state(grid, node, s, f+df_central(f,t), t)
//In the biological model, the effluent concentration should equal the concentration in the tank. In Backbone, this would mean that transfer equals state
//for the reaction nodes.
;
$offtext