*=========================================================================================================
*---------- Deleted parts from the code ------------------------------------------------------------------

*         v_flagState(grid, node, ww_flowType, ww_range, s, f, t)                                "The product of v_state and the binary v_flowFlag"

* EQUATIONS
*q_ww_flagState1(grid, node, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
*q_ww_flagState2(grid, node, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
*q_ww_flagState3(grid, node, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"

*q_ww_flagGen1(grid, node, unit, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"
*q_ww_flagGen2(grid, node, unit, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"
*q_ww_flagGen3(grid, node, unit, ww_flowType, ww_range, s, f, t)                                "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"


* ENERGY BALANCE
            // Self discharge out of the model boundaries
            // in the WWTP model, this is influence of the node's concentration on its own concentration
$ontext
+ p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A2')
  * v_helperState(grid, 'S_reaction', ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)${not gn2n_directional(grid, from_node, 'S_reaction')}
+ p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A3')${not gn2n_directional(grid, from_node, 'X_reaction')}
  * v_helperState(grid, 'X_reaction', ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)

Selfdischarge doubles the v_gen of the compiler and should be excluded

            - p_gn(grid, node, 'selfDischargeLoss')${ gn_state(grid, node) }
                     * sum(ww_flowType,
                         sum(ww_range,
                             sum(ww_flowType_,
                                 sum(ww_range_,
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A1')$gn(grid, 'DO_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A2')$gn(grid, 'S_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A3')$gn(grid, 'X_reaction')
                               * v_helperState(grid, node, ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)
                                 )
                             )
                          )
                       ) //END sum(ww_flowType)

            //This is an addition of the WWTP model. It is the product of the dilution factor and
            //the state variable of the node.
            + sum(ww_flowType,
                sum(ww_range,
                    p_ww_dilution(ww_flowType, ww_range)
                      * v_flagState(grid, node, ww_flowType, ww_range, s, f, t)
                )
              )
$offtext

$ontext
I believe the energy diffusion should not appear twice in the WWTP balance equation.
Would that double the selfDischarge of the node?

            // Energy diffusion from this node to neighbouring nodes
            // in the WWTP model, this is influence of the other node's concentration on the node's concentration
            - sum(gnn_state(grid, node, to_node),
                + [p_gnn(grid, node, to_node, 'diffCoeff')
                     * sum(ww_flowType,
                         sum(ww_range,
                             sum(ww_flowType_,
                                 sum(ww_range_,
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A1')$gn2n_directional(grid, node, 'DO_reaction')
                                 * v_helperState(grid, 'DO_reaction', ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A2')$gn2n_directional(grid, node, 'S_reaction')
                                 * v_helperState(grid, 'S_reaction', ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A3')$gn2n_directional(grid, node, 'X_reaction')
                                 * v_helperState(grid, 'X_reaction', ww_flowType, ww_range, ww_flowType_, ww_range_, s, f+df_central(f,t), t)
                                 )
                             )
                          )
                       )
                  ]//END sum(ww_flowType)
                ) // END sum(from_node)

Direct energy transfer (not interlinked with flowFlag) is not part of the original equation, so it should be disabled.
Can the transfer from storage nodes still work only based on v_flagTransfer?

            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(gn2n_directional(grid, node, node_),
                + (1 - p_gnn(grid, node, node_, 'transferLoss')) // Reduce transfer losses
                    * v_transfer(grid, node, node_, s, f, t)
                + p_gnn(grid, node, node_, 'transferLoss') // Add transfer losses back if transfer is from this node to another node
                    * v_transferRightward(grid, node, node_, s, f, t)
                ) // END sum(node_)
$offtext

$ontext
Not necessary when only v_gen is considered as effluent concentration
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

*------------ Constraints for binding the product variable v_flagGen -----------

q_ww_flagGen1(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_reactionCompiler')}
..

         v_flowFlag(ww_flowType, ww_range, s, f, t) * BIG_M

         =G=

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)
;

q_ww_flagGen2(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_reactionCompiler')}
..

         v_gen(grid, node, unit, s, f, t)

         =G=

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

;

q_ww_flagGen3(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_reactionCompiler')}
..

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

         =G=

         v_gen(grid, node, unit, s, f, t) - [(1-v_flowFlag(ww_flowType, ww_range, s, f, t)) * BIG_M]
;

$offtext

*3b_periodicLoop
*Option clear = v_flagState; // part of the WWTP model
*Option clear = v_flagGen; // part of the WWTP model

$ontext
                  sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_dilution(ww_flowType, ww_range, node, node_)
                             * v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)
                         )
                  )
$offtext

$ontext
                  sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_dilution(ww_flowType, ww_range, node_, node)
                             * v_flagTransfer(grid, node_, node, ww_flowType, ww_range, s, f, t)
                         )
                  )
$offtext