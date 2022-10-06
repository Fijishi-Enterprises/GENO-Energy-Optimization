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
* --- Load Input Data ---------------------------------------------------------
* =============================================================================

* If input_file excel has been set in the command line arguments, then Gdxxrw will be run to convert the Excel into a GDX file
*   using the sheet defined by input_excel_index command line argument (default: 'INDEX').
$if set input_file_excel $call 'gdxxrw Input="%input_dir%/%input_file_excel%" Output="%input_dir%/%input_file_gdx%" Index=%input_excel_index%! %input_excel_checkdate%'
$ife %system.errorlevel%>0 $abort gdxxrw failed! Check that your input Excel is valid and that your file path and file name are correct.

* --input_file_gdx=nameOfInputFile.gdx for input_file_gdx in input_dir
$ifthen exist '%input_dir%/%input_file_gdx%'
    $$gdxin  '%input_dir%/%input_file_gdx%'
* --input_file_gdx=ABSOLUTE/PATH/nameOfInputFile.gdx for input_file_gdx not in input_dir
$elseif exist '%input_file_gdx%'
    $$gdxin  '%input_file_gdx%'
$else
    $$goto no_input_gdx
$endif

$loaddcm grid
$loaddc node
$loaddc flow
$loaddc unittype
$loaddc unit
$loaddc unitUnittype
$loaddc unit_fail
$loaddc unitUnitEffLevel
$loaddc effLevelGroupUnit
$loaddc group
$loaddc p_gn
$loaddc p_gnn
$loaddc ts_gnn
$loaddc p_gnu_io
$loaddc p_gnuBoundaryProperties
$loaddc p_unit
$loaddc ts_unit
$loaddc p_unitConstraint
$loaddc p_unitConstraintNode
$loaddc restype
$loaddc restypeDirection
$loaddc restypeReleasedForRealization
$loaddc restype_inertia
$loaddc p_groupReserves
$loaddc p_groupReserves3D
$loaddc p_groupReserves4D
$loaddc p_gnuReserves
$loaddc p_gnnReserves
$loaddc p_gnuRes2Res
$loaddc ts_reserveDemand
$loaddc p_gnBoundaryPropertiesForStates
$loaddc p_uStartupfuel
$loaddc flowUnit
$loaddc emission
$loaddc p_nEmission
$loaddc p_gnuEmission
$loaddc ts_cf
*$loaddc p_price // Disabled for convenience, see line 278-> ("Determine Fuel Price Representation")
$loaddc ts_priceChange
$loaddc ts_emissionPriceChange
$loaddc ts_influx
$loaddc ts_node
$loaddc p_s_discountFactor
$loaddc t_invest
$loaddc utAvailabilityLimits
$loaddc p_storageValue
$loaddc ts_storageValue
$loaddc uGroup
$loaddc gnuGroup
$loaddc gn2nGroup
$loaddc gnGroup
$loaddc sGroup
$loaddc p_groupPolicy
$loaddc p_groupPolicyUnit
$loaddc p_groupPolicyEmission
$loaddc gnss_bound
$loaddc uss_bound

$gdxin

$label no_input_gdx


* Read changes to inputdata through gdx files (e.g. node2.gdx, unit2.gdx, unit3.gdx) - allows scenarios through Sceleton Titan Excel files.
$include 'inc/1e_scenChanges.gms'

* Reads changes or additions to the inputdata through changes.inc file.
$ifthen exist '%input_dir%/changes.inc'
   $$include '%input_dir%/changes.inc'
$endif



$ontext
* --- sets with 'empty' to enable GDX imports in Sceleton Titan - currently removed when forming gnu (below) and uft (periodicLoop.gms) sets
* This list can be removed once this has been tested.
node
unit
gngnu_constrainedOutputRatio
restype
restypeReleasedForRealization
p_gnn
p_gnnReserves
p_gnuBoundaryProperties
ts_node
ts_reserveDemand
ts_unit
p_storageValue
group
gnuGroup
gnGroup
gn2nGroup
gnss_bound
$offtext


* =============================================================================
* --- Initialize Price Related Sets & Parameters Based on Input Data -------
* =============================================================================


emissionGroup(emission, group)${ sum(t, abs(ts_emissionPriceChange(emission, group, t)))
                                 or p_groupPolicyEmission(group, 'emissionCap', emission)
                                   }
    = yes;


// Use time series for node prices depending on 'ts_priceChange'
// Determine if node prices require a time series representation or not
loop(node$sum(grid, p_gn(grid, node, 'usePrice')),
    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_priceChange(node, t) } = yes;

    // If only up to a single value
    if(sum(tt, 1) <= 1,
        p_price(node, 'useConstant') = 1; // Use a constant for node prices
        p_price(node, 'price') = sum(tt, ts_priceChange(node, tt)) // Determine the price as the only value in the time series
    // If multiple values found, use time series
    else
        p_price(node, 'useTimeSeries') = 1;
        ); // END if(sum(tt))
); // END loop(node)

// Use time series for emission group prices depending on 'ts_emissionPriceChange'
// Determine if emission group prices require a time series representation or not
loop(emissionGroup(emission, group)$sum(t, abs(ts_emissionPriceChange(emission, group, t))),
    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_emissionPriceChange(emission, group, t) } = yes;

    // If only up to a single value
    if(sum(tt, 1) <= 1,
        p_emissionPrice(emission, group, 'useConstant') = 1; // Use a constant for node prices
        p_emissionPrice(emission, group, 'price') = sum(tt, ts_emissionPriceChange(emission, group, tt)) // Determine the price as the only value in the time series
    // If multiple values found, use time series
    else
        p_emissionPrice(emission, group, 'useTimeSeries') = 1;
        ); // END if(sum(tt))
); // END loop(group)


* =============================================================================
* --- Initialize Unit Related Sets & Parameters Based on Input Data -----------
* =============================================================================


* --- Generate Unit Related Sets ----------------------------------------------

p_gnu(grid, node, unit, param_gnu) = sum(input_output, p_gnu_io(grid, node, unit, input_output, param_gnu));

// Set of all existing gnu
gnu(grid, node, unit)${ not sameas(grid, 'empty')
                        and (   p_gnu(grid, node, unit, 'capacity')
                                or p_gnu(grid, node, unit, 'unitSize')
                                or p_gnu(grid, node, unit, 'conversionCoeff')
                                )
                      }
    = yes;
// Reduce the grid dimension
nu(node, unit) = sum(grid, gnu(grid, node, unit));
//p_gnu(grid, node, unit, 'capacity')$(p_gnu(grid, node, unit, 'capacity') = 0) = inf;

// Separation of gnu into inputs and outputs
gnu_output(gnu(grid, node, unit))${ p_gnu_io(grid, node, unit, 'output', 'capacity')
                                    or p_gnu_io(grid, node, unit, 'output', 'unitSize')
                                    or p_gnu_io(grid, node, unit, 'output', 'conversionCoeff')
                                    }
    = yes;
gnu_input(gnu(grid, node, unit))${  p_gnu_io(grid, node, unit, 'input', 'capacity')
                                    or p_gnu_io(grid, node, unit, 'input', 'unitSize')
                                    or p_gnu_io(grid, node, unit, 'input', 'conversionCoeff')
                                    }
    = yes;

// Units connecting gn-gn pairs
gn2gnu(grid, node_input, grid_, node_output, unit)${    gnu_input(grid, node_input, unit)
                                                        and gnu_output(grid_, node_output, unit)
                                                        }
    = yes;

// Units with minimum load requirements
unit_minload(unit)${    p_unit(unit, 'op00') > 0 // If the first defined operating point is between 0 and 1, then the unit is considered to have a min load limit
                        and p_unit(unit, 'op00') < 1
                        }
    = yes;

// Units with flows/commodities
unit_flow(unit)${ sum(flow, flowUnit(flow, unit)) }
    = yes;

// Units with investment variables
unit_investLP(unit)${  not p_unit(unit, 'investMIP')
                       and p_unit(unit, 'maxUnitCount')
                        }
    = yes;
unit_investMIP(unit)${  p_unit(unit, 'investMIP')
                        and p_unit(unit, 'maxUnitCount')
                        }
    = yes;

// Units with special startup properties
// All units can cold start (default start category)
unitStarttype(unit, 'cold') = yes;
// Units with parameters regarding hot/warm starts
unitStarttype(unit, starttypeConstrained)${ p_unit(unit, 'startWarmAfterXhours')
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startCostHot'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startFuelConsHot'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startCostWarm'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startFuelConsWarm'))
                                            or p_unit(unit, 'startColdAfterXhours')
                                            }
    = yes;
// Units consuming energy from particular nodes in start-up
nu_startup(node, unit)$p_uStartupfuel(unit, node, 'fixedFuelFraction') = yes;

// Units with time series data enabled
unit_timeseries(unit)${ p_unit(unit, 'useTimeseries') or p_unit(unit, 'useTimeseriesAvailability') }
    = yes;

* --- Unit Related Parameters -------------------------------------------------

// Assume values for critical unit related parameters, if not provided by input data
// If the unit does not have efficiency set, it is 1
p_unit(unit, 'eff00')${ not p_unit(unit, 'eff00') }
    = 1;

// In case number of units has not been defined it is 1 except for units with investments allowed.
p_unit(unit, 'unitCount')${ not p_unit(unit, 'unitCount')
                            and not unit_investMIP(unit)
                            and not unit_investLP(unit)
                            }
    = 1;

// By default add outputs in order to get the total capacity of the unit
p_unit(unit, 'outputCapacityTotal')${ not p_unit(unit, 'outputCapacityTotal') }
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'capacity'));
p_unit(unit, 'unitOutputCapacityTotal')
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSize'));

// Assume unit sizes based on given maximum capacity parameters and unit counts if able
p_gnu(gnu(grid, node, unit), 'unitSize')
    ${  not p_gnu(grid, node, unit, 'unitSize')
        and p_gnu(grid, node, unit, 'capacity')
        and p_unit(unit, 'unitCount')
        }
    = p_gnu(grid, node, unit, 'capacity') / p_unit(unit, 'unitCount'); // If capacity and unitCount are given, calculate unitSize based on them.

// Determine unit startup parameters based on data
// Hot startup parameters
p_uNonoperational(unitStarttype(unit, 'hot'), 'min')
    = p_unit(unit, 'minShutdownHours');
p_uNonoperational(unitStarttype(unit, 'hot'), 'max')
    = p_unit(unit, 'startWarmAfterXhours');
p_uStartup(unitStarttype(unit, 'hot'), 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostHot'));
p_uStartup(unitStarttype(unit, 'hot'), 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsHot'));

// Warm startup parameters
p_uNonoperational(unitStarttype(unit, 'warm'), 'min')
    = p_unit(unit, 'startWarmAfterXhours');
p_uNonoperational(unitStarttype(unit, 'warm'), 'max')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unitStarttype(unit, 'warm'), 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostWarm'));
p_uStartup(unitStarttype(unit, 'warm'), 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsWarm'));

// Cold startup parameters
p_uNonoperational(unitStarttype(unit, 'cold'), 'min')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unit, 'cold', 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostCold'));
p_uStartup(unit, 'cold', 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsCold'));

// Start-up fuel consumption per fuel
p_unStartup(unit, node, starttype)$p_uStartupfuel(unit, node, 'fixedFuelFraction')
    = p_uStartup(unit, starttype, 'consumption')
        * p_uStartupfuel(unit, node, 'fixedFuelFraction');

//shutdown cost parameters
p_uShutdown(unit, 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'shutdownCost'));

// Unit lifetime
loop(utAvailabilityLimits(unit, t, availabilityLimits),
    p_unit(unit, availabilityLimits) = ord(t)
); // END loop(ut)


* =============================================================================
* --- Generate Node Related Sets Based on Input Data --------------------------
* =============================================================================

* --- Node Connectivity -------------------------------------------------------

// Node pairs connected via transfer links
gn2n(grid, from_node, to_node)${    p_gnn(grid, from_node, to_node, 'transferCap')
                                    or p_gnn(grid, from_node, to_node, 'transferLoss')
                                    or p_gnn(grid, from_node, to_node, 'transferCapBidirectional')
                                    or p_gnn(grid, to_node, from_node, 'transferCapBidirectional')
                                    or p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
                                    or p_gnn(grid, from_node, to_node, 'portion_of_transfer_to_reserve')
                                    }
    = yes;

// Node pairs with relatively bound states
gnn_boundState(grid, node, node_)${ p_gnn(grid, node, node_, 'boundStateMaxDiff') }
    = yes;

// Node pairs connected via energy diffusion
gnn_state(grid, node, node_)${  p_gnn(grid, node, node_, 'diffCoeff')
                                or gnn_boundState(grid, node, node_)
                                }
    = yes;

// Generate the set for transfer links where the order of the first node must be smaller than the order of the second node
Option clear = gn2n_directional;
gn2n_directional(gn2n(grid, node, node_))${ ord(node) < ord(node_) }
    = yes;
gn2n_directional(gn2n(grid, node, node_))${ ord(node) > ord(node_)
                                            and not gn2n(grid, node_, node)
                                            }
    = yes;

// set for ramp constrained transfer links
gn2n_directional_rampConstrained(gn2n_directional(grid, node, node_)) $  {p_gnn(grid, node, node_, 'rampLimit')
                                                                          or p_gnn(grid, node_, node, 'rampLimit')
                                                                         }
    = yes;

// Set for transfer links with investment possibility
Option clear = gn2n_directional_investLP;
Option clear = gn2n_directional_investMIP;
gn2n_directional_investLP(gn2n_directional(grid, node, node_))${ [p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                     or p_gnn(grid, node_, node, 'transferCapInvLimit')]
                                                                 and [not p_gnn(grid, node, node_, 'investMIP')
                                                                     and not p_gnn(grid, node_, node, 'investMIP')]
                                                                 }
    = yes;
gn2n_directional_investMIP(gn2n_directional(grid, node, node_))${ [p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                     or p_gnn(grid, node_, node, 'transferCapInvLimit')]
                                                                 and [p_gnn(grid, node, node_, 'investMIP')
                                                                     or p_gnn(grid, node_, node, 'investMIP')]
                                                                 }
    = yes;

* --- Node States -------------------------------------------------------------

// States with slack variables
gn_stateSlack(grid, node)${ sum((slack, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, slack, useConstantOrTimeSeries)) }
    = yes;

// Nodes with states
gn_state(grid, node)${  gn_stateSlack(grid, node)
                        or p_gn(grid, node, 'energyStoredPerUnitOfState')
                        or sum((stateLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, stateLimits, useConstantOrTimeSeries))
                        or sum(useConstantOrTimeSeries, p_gnBoundaryPropertiesForStates(grid, node, 'reference', useConstantOrTimeSeries))
                        }
    = yes;

// Existing grid-node pairs
gn(grid, node)${    sum(unit, gnu(grid, node, unit))
                    or gn_state(grid, node)
                    or sum((f, t), ts_influx(grid, node, f, t))
                    or sum(node_, gn2n(grid, node, node_))
                    or sum(node_, gn2n(grid, node_, node))
                    or sum(node_, gnn_state(grid, node, node_))
                    or sum(node_, gnn_state(grid, node_, node))
                    }
    = yes;

// Nodes with spill permitted
node_spill(node)${ sum((grid, spillLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, spillLimits, useConstantOrTimeSeries)) }
    = yes;

// Assume values for critical node related parameters, if not provided by input data
// Boundary multiplier
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')${  not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')
                                                                                        and sum(param_gnBoundaryProperties, p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, param_gnBoundaryProperties))
    } = 1; // If multiplier has not been set, set it to 1 by default

* --- Other Node Properties ---------------------------------------------------

// Nodes with flows
flowNode(flow, node)${  sum((f, t), ts_cf(flow, node, f, t))
                        and sum(grid, gn(grid, node))
                        }
    = yes;

* --- Timeseries parameters for node-node connections -------------------------

// Transfer links with time series enabled for certain parameters
gn2n_timeseries(grid, node, node_, 'availability')${p_gnn(grid, node, node_, 'useTimeseriesAvailability')}
    = yes;
gn2n_timeseries(grid, node, node_, 'transferLoss')${p_gnn(grid, node, node_, 'useTimeseriesLoss')}
    = yes;

* =============================================================================
* --- Reserves Sets & Parameters ----------------------------------------------
* =============================================================================
// NOTE! Reserves can be disabled through the model settings file.
// The sets are disabled in "3a_periodicInit.gms" accordingly.

* --- Correct values for critical reserve related parameters - Part 1 ---------

// Reserve activation duration assumed to be 1 hour if not provided in data
p_groupReserves(group, restype, 'reserve_activation_duration')
    ${  not p_groupReserves(group, restype, 'reserve_activation_duration')
        and p_groupReserves(group, restype, 'reserve_length')
        }
    = 1;
// Reserve reactivation time assumed to be 1 hour if not provided in data
p_groupReserves(group, restype, 'reserve_reactivation_time')
    ${  not p_groupReserves(group, restype, 'reserve_reactivation_time')
        and p_groupReserves(group, restype, 'reserve_length')
        }
    = 1;

* --- Copy reserve data and create necessary sets -----------------------------

// Copy data from p_groupReserves to p_gnReserves
p_gnReserves(grid, node, restype, param_policy) =
    sum(gnGroup(grid, node, group)${sum(restype_, p_groupReserves(group, restype_, 'reserve_length'))},
        p_groupReserves(group, restype, param_policy)
    );

// Units with reserve provision capabilities
gnuRescapable(restypeDirection(restype, up_down), gnu(grid, node, unit))
    $ { p_gnuReserves(grid, node, unit, restype, up_down)
      }
  = yes;

// Units with offline reserve provision capabilities
gnuOfflineRescapable(restype, gnu(grid, node, unit))
    $ { p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability')
      }
  = yes;

// Restypes with offline reserve provision possibility
offlineRes(restype)
    $ {sum(gnu(grid, node, unit),  p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability'))
      }
  = yes;

// Units with offline reserve provision possibility
offlineResUnit(unit)
    $ {sum((gn(grid, node), restype),  p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability'))
      }
  = yes;

// Node-node connections with reserve transfer capabilities
restypeDirectionGridNodeNode(restypeDirection(restype, up_down), gn2n(grid, node, node_))
    $ { p_gnnReserves(grid, node, node_, restype, up_down)
      }
  = yes;

// Nodes with reserve requirements, units capable of providing reserves, or reserve capable connections
restypeDirectionGridNode(restypeDirection(restype, up_down), gn(grid, node))
    $ { p_gnReserves(grid, node, restype, up_down)
        or p_gnReserves(grid, node, restype, 'useTimeSeries')
        or sum(gnu(grid, node, unit), p_gnuReserves(grid, node, unit, restype, 'portion_of_infeed_to_reserve'))
        or sum(gnu(grid, node, unit), gnuRescapable(restype, up_down, grid, node, unit))
        or sum(gn2n(grid, node, to_node), restypeDirectionGridNodeNode(restype, up_down, grid, node, to_node))
      }
  = yes;

// Groups with reserve requirements
restypeDirectionGroup(restypeDirection(restype, up_down), group)
    $ { p_groupReserves(group, restype, 'reserve_length')
      }
  = yes;
restypeDirectionGridNodeGroup(restypeDirection(restype, up_down), gnGroup(grid, node, group))
    $ { p_groupReserves(group, restype, 'reserve_length')
      }
  = yes;

* --- Correct values for critical reserve related parameters - Part 2 ---------

// Reserve reliability assumed to be perfect if not provided in data
p_gnuReserves(gnu(grid, node, unit), restype, 'reserveReliability')
    ${  not p_gnuReserves(grid, node, unit, restype, 'reserveReliability')
        and sum(up_down, gnuRescapable(restype, up_down, grid, node, unit))
        }
    = 1;

// Reserve provision overlap decreases the capacity of the overlapping category
loop(restype,
p_gnuReserves(gnu(grid, node, unit), restype, up_down)
    ${ gnuRescapable(restype, up_down, grid, node, unit) }
    = p_gnuReserves(grid, node, unit, restype, up_down)
        - sum(restype_${ p_gnuRes2Res(grid, node, unit, restype_, up_down, restype) },
            + p_gnuReserves(grid, node, unit, restype_, up_down)
                * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
        ); // END sum(restype_)
);

* =============================================================================
* --- Data Integrity Checks ---------------------------------------------------
* =============================================================================

* --- Check that nodes aren't assigned to multiple grids ----------------------

loop(node,
    if(sum(gn(grid, node), 1) > 1,
        put log '!!! Error occurred on node ' node.tl:0 /;
        loop(gn(grid, node),
               put log '!!! Error occurred on grid ' grid.tl:0 /;
        );
        put log '!!! Abort: Nodes cannot be assigned to multiple grids!' /;
        abort "Nodes cannot be assigned to multiple grids!"
    ); // END if(sum(gn))
); // END loop(node)

* --- Check the integrity of node connection related data ---------------------

Option clear = count;
loop(gn2n(grid, node, node_),
    count = count + 1; // Count the gn2n indeces to make finding the errors easier.
    // Check if the bidirectional transfer parameter exists for this link.
    if(p_gnn(grid, node, node_, 'transferCapBidirectional'),
        // Check for conflicting bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') <> p_gnn(grid, node_, node, 'transferCapBidirectional'),
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: Conflicting transferCapBidirectional parameters!' /;
            abort "Conflicting 'transferCapBidirectional' parameters!"
        );
        // Check for conflicting one-directional and bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node, node_, 'transferCap') OR (p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node_, node, 'transferCap')),
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: Parameter transferCapBidirectional must be greater than or equal to defined one-directional transfer capacities!' /;
            abort "Parameter 'transferCapBidirectional' must be greater than or equal to defined one-directional transfer capacities!"
        );
    );
);

* --- Check the integrity of efficiency approximation related data ------------

Option clear = tmp;
// Find the largest effLevel used in the data
tmp = smax(effLevelGroupUnit(effLevel, effSelector, unit), ord(effLevel));

// Expand the effLevelGroupUnit when possible, abort if impossible
loop(effLevel${ord(effLevel)<=tmp},
    effLevelGroupUnit(effLevel, effSelector, unit)
        ${not sum(effLevelGroupUnit(effLevel, effSelector_, unit), 1)}
        = effLevelGroupUnit(effLevel - 1, effSelector, unit) // Expand previous (effLevel, effSelector) when applicable
    loop(unit${not unit_flow(unit) and not sameas(unit, 'empty')},
        If(not sum(effLevelGroupUnit(effLevel, effSelector, unit), 1),
            put log '!!! Error on unit ' unit.tl:0 /;
            put log '!!! Abort: Insufficient effLevelGroupUnit definitions!' /;
            abort "Insufficient effLevelGroupUnit definitions!"
        );
    );
);

loop( unit,
    // Check that 'op' is defined correctly
    Option clear = count; // Initialize the previous op to zero
    loop( op,
        if (p_unit(unit, op) + 1${not p_unit(unit, op)} < count,
            put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
            put log '!!! Abort: param_unit op must be defined as zero or positive and increasing!' /;
            abort "param_unit 'op's must be defined as zero or positive and increasing!";
        ); // END if(p_unit)
        count = p_unit(unit, op);
    ); // END loop(op)
    // Check that efficiency approximations have sufficient data
    loop( effLevelGroupUnit(effLevel, effSelector, unit),
        loop( op__${p_unit(unit, op__) = smax(op, p_unit(unit, op))}, // Loop over the 'op's to find the last defined data point.
            loop( op_${p_unit(unit, op_) = smin(op${p_unit(unit, op)}, p_unit(unit, op))}, // Loop over the 'op's to find the first nonzero 'op' data point.
                if(effDirectOn(effSelector) AND ord(op__) = ord(op_) AND not p_unit(unit, 'section') AND not p_unit(unit, 'opFirstCross'),
                    put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
                    put log '!!! Abort: directOn requires two efficiency data points with nonzero op or section or opFirstCross!' /;
                    abort "directOn requires two efficiency data points with nonzero 'op' or 'section' or 'opFirstCross'!";
                ); // END if(effDirectOn)
            ); // END loop(op_)
        ); // END loop(op__)
    ); // END loop(effLevelGroupUnit)
);

* --- Check startupfuel fraction related data ----------------------------------------

loop( unit${sum(starttype$p_uStartup(unit, starttype, 'consumption'), 1)},
    if(sum(node, p_uStartupfuel(unit, node, 'fixedFuelFraction')) <> 1,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: The sum of fixedFuelFraction over start-up fuels needs to be one for all units using start-up fuels!' /;
        abort "The sum of 'fixedFuelFraction' over start-up fuels needs to be one for all units using start-up fuels!"
    );
);

loop( unit${sum((constraint, node)$p_unitConstraintNode(unit, constraint, node), 1)},
    if(sum((constraint, node)$p_unitConstraintNode(unit, constraint, node), 1) < 2,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: constraint requires at least two inputs or outputs!' /;
        abort "a constraint has to have more tha one input or output!"
    );
);

* --- Check the shutdown time related data ------------------------------------

loop( unitStarttype(unit, starttypeConstrained),
    if(p_unit(unit, 'minShutdownHours') > p_unit(unit, 'startWarmAfterXhours')
        or p_unit(unit, 'startWarmAfterXhours') > p_unit(unit, 'startColdAfterXhours'),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Units should have p_unit(unit, minShutdownHours) <= p_unit(unit, startWarmAfterXhours) <= p_unit(unit, startColdAfterXhours)!' /;
        abort "Units should have p_unit(unit, 'minShutdownHours') <= p_unit(unit, 'startWarmAfterXhours') <= p_unit(unit, 'startColdAfterXhours')!"
    );
);

* --- Check reserve related data ----------------------------------------------

loop( restypeDirectionGroup(restype, up_down, group),
    // Check that reserve_length is long enough for proper commitment of reserves
    if(p_groupReserves(group, restype, 'reserve_length') < p_groupReserves(group, restype, 'update_frequency') + p_groupReserves(group, restype, 'gate_closure'),
        put log '!!! Error occurred on group ', group.tl:0 /;
        put log '!!! Abort: The reserve_length parameter should be longer than update_frequency + gate_closure to fix the reserves properly!' /;
        abort "The 'reserve_length' parameter should be longer than 'update_frequency' + 'gate_closure' to fix the reserves properly!"
    ); // END if
    // Check that the duration of reserve activation is less than the reserve reactivation time
    if(p_groupReserves(group, restype, 'reserve_reactivation_time') < p_groupReserves(group, restype, 'reserve_activation_duration'),
        put log '!!! Error occurred on group ', group.tl:0 /;
        put log '!!! Abort: The reserve_reactivation_time should be greater than or equal to the reserve_activation_duration!' /;
        abort "The reserve_reactivation_time should be greater than or equal to the reserve_activation_duration!"
    ); // END if
); // END loop(restypeDirectionGroup)

loop( restypeDirectionGridNode(restype, up_down, grid, node),
    // Check for each restype that a node does not belong to multiple groups
    if(sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group), 1) > 1,
        put log '!!! Error occurred on node ', node.tl:0 /;
        put log '!!! Abort: For each reserve type, a node can belong to at maximum one reserve node group!' /;
        abort "For each reserve type, a node can belong to at maximum one reserve node group!"
    ); // END if
    // Check if there are units/interconnections connected to a node that does not belong to any restypeDirectionGroup
    if(sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group), 1) < 1,
        put log '!!! Error occurred on node ', node.tl:0 /;
        put log '!!! Abort: A node with reserve provision/transfer capability has to belong to a reserve node group!' /;
        abort "A node with reserve provision/transfer capability has to belong to a reserve node group!"
    ); // END if
); // END loop(restypeDirectionGridNode)

// Check that reserve overlaps are possible
loop( (gnu(grid, node, unit), restypeDirection(restype, up_down)),
    if( p_gnuReserves(grid, node, unit, restype, up_down) < 0,
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Overlapping reserve capacities in p_gnuRes2Res can result in excess reserve production!' /;
        abort "Overlapping reserve capacities in p_gnuRes2Res can result in excess reserve production!"
    ); // END if(p_gnuReserves)
); // END loop((gnu,restypeDirection))

* --- Check investment related data -------------------------------------------

// Check that units with LP investment possibility have unitSize
loop( unit_investLP(unit),
    if(not sum(gnu(grid, node, unit), abs(p_gnu(grid, node, unit, 'unitSize'))),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Unit is listed as an investment option but it has no unitSize!' /;
        abort "All units with investment possibility should have 'unitSize' in p_gnu!"
    ); // END if
); // END loop(unit_investLP)
// Check that units with MIP investment possibility have unitSize
loop( unit_investMIP(unit),
    if(not sum(gnu(grid, node, unit), abs(p_gnu(grid, node, unit, 'unitSize'))),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Unit is listed as an investment option but it has no unitSize!' /;
        abort "All units with investment possibility should have 'unitSize' in p_gnu!"
    ); // END if
); // END loop(unit_investMIP)

* --- Check node balance and price related data -------------------------------

// Give a warning if both nodeBalance and usePrice are false
loop( node,
    if(not sum(grid, p_gn(grid, node, 'nodeBalance') or p_gn(grid, node, 'usePrice')),
        put log '!!! Warning: Node ', node.tl:0, ' does not have nodeBalance or usePrice activated in p_gn' /;
    ); // END if
); // END loop(node)
// Give a warning if usePrice is true but ts_priceChange has no data
loop( node,
    if(p_price(node, 'useConstant') and not p_price(node, 'price'),
        put log '!!! Warning: Node ', node.tl:0, ' has usePrice activated in p_gn but there is no ts_priceChange data' /;
    ); // END if
); // END loop(node)
// Give a warning if both nodeBalance and usePrice are true
loop( node,
    if(sum(grid, p_gn(grid, node, 'nodeBalance') and p_gn(grid, node, 'usePrice')),
        put log '!!! Warning: Node ', node.tl:0, ' has both nodeBalance or usePrice activated in p_gn' /;
    ); // END if
); // END loop(node)
loop(emissionGroup(emission, group),
    if(p_emissionPrice(emission, group, 'useConstant') and not p_emissionPrice(emission, group, 'price'),
        put log '!!! Warning: Emission group (', group.tl:0, ', ', emission.tl:0, ') has emission tax activated but no price data' /;
    ); // END if
); // END loop(emissionGroup)

* --- Check consistency of inputs for superposed node states -------------------

* no checking yet because node_superpos is not given in the gdx input


* =============================================================================
* --- Default values  ---------------------------------------------------------
* =============================================================================
loop(timeseries$(not sameas(timeseries, 'ts_cf')),
    p_tsMinValue(gn, timeseries) = -Inf;
    p_tsMaxValue(gn, timeseries) = Inf;
);
p_tsMinValue(flowNode, 'ts_cf') = 0;
p_tsMaxValue(flowNode, 'ts_cf') = 1;

* By default all nodes use forecasts for all timeseries
gn_forecasts(gn, timeseries) = yes;
gn_forecasts(flowNode, timeseries) = yes;
gn_forecasts(restype, node, 'ts_reserveDemand') = yes;

