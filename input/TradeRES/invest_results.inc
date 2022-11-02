* Update the number of subunits in the subsequent models
p_unit('ES Wind Onshore                         ', 'unitCount') = p_unit('ES Wind Onshore                         ', 'unitCount') +     31929.00;
p_unit('PT Wind Onshore                         ', 'unitCount') = p_unit('PT Wind Onshore                         ', 'unitCount') +      4183.00;
p_unit('PT electrolyser                         ', 'unitCount') = p_unit('PT electrolyser                         ', 'unitCount') +       492.00;
p_unit('ES electrolyser                         ', 'unitCount') = p_unit('ES electrolyser                         ', 'unitCount') +      2442.00;

* Update unit capacities in the subsequent models
* Set 'becomeUnavailable' if no existing capacity and no investments
utAvailabilityLimits('PT Solar PV large                       ', t, 'becomeAvailable') = no;
utAvailabilityLimits('PT Solar PV large                       ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('PT Solar PV large                       ', 't000001', 'becomeUnavailable') = yes;
utAvailabilityLimits('PT Wind Offshore                        ', t, 'becomeAvailable') = no;
utAvailabilityLimits('PT Wind Offshore                        ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('PT Wind Offshore                        ', 't000001', 'becomeUnavailable') = yes;
p_gnu_io('elec                                    ', 'PT elec                                 ', 'PT Wind Onshore                         ', 'output', 'capacity')
    = p_gnu_io('elec                                    ', 'PT elec                                 ', 'PT Wind Onshore                         ', 'output', 'capacity') +      4183.00;
p_gnu_io('elec                                    ', 'PT elec                                 ', 'PT electrolyser                         ', 'input', 'capacity')
    = p_gnu_io('elec                                    ', 'PT elec                                 ', 'PT electrolyser                         ', 'input', 'capacity') +       492.00;
utAvailabilityLimits('PT H2 turbine                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('PT H2 turbine                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('PT H2 turbine                           ', 't000001', 'becomeUnavailable') = yes;
utAvailabilityLimits('ES Solar PV large                       ', t, 'becomeAvailable') = no;
utAvailabilityLimits('ES Solar PV large                       ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('ES Solar PV large                       ', 't000001', 'becomeUnavailable') = yes;
p_gnu_io('elec                                    ', 'ES elec                                 ', 'ES Wind Onshore                         ', 'output', 'capacity')
    = p_gnu_io('elec                                    ', 'ES elec                                 ', 'ES Wind Onshore                         ', 'output', 'capacity') +     31929.00;
utAvailabilityLimits('ES Wind Offshore                        ', t, 'becomeAvailable') = no;
utAvailabilityLimits('ES Wind Offshore                        ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('ES Wind Offshore                        ', 't000001', 'becomeUnavailable') = yes;
p_gnu_io('elec                                    ', 'ES elec                                 ', 'ES electrolyser                         ', 'input', 'capacity')
    = p_gnu_io('elec                                    ', 'ES elec                                 ', 'ES electrolyser                         ', 'input', 'capacity') +      2442.00;
utAvailabilityLimits('ES H2 turbine                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('ES H2 turbine                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('ES H2 turbine                           ', 't000001', 'becomeUnavailable') = yes;
p_gnu_io('H2                                      ', 'ES H2 node                              ', 'ES electrolyser                         ', 'output', 'capacity')
    = p_gnu_io('H2                                      ', 'ES H2 node                              ', 'ES electrolyser                         ', 'output', 'capacity') +      2442.00;
utAvailabilityLimits('ES H2 storage                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('ES H2 storage                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('ES H2 storage                           ', 't000001', 'becomeUnavailable') = yes;
utAvailabilityLimits('ES H2 turbine                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('ES H2 turbine                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('ES H2 turbine                           ', 't000001', 'becomeUnavailable') = yes;
p_gnu_io('H2                                      ', 'PT H2 node                              ', 'PT electrolyser                         ', 'output', 'capacity')
    = p_gnu_io('H2                                      ', 'PT H2 node                              ', 'PT electrolyser                         ', 'output', 'capacity') +       492.00;
utAvailabilityLimits('PT H2 storage                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('PT H2 storage                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('PT H2 storage                           ', 't000001', 'becomeUnavailable') = yes;
utAvailabilityLimits('PT H2 turbine                           ', t, 'becomeAvailable') = no;
utAvailabilityLimits('PT H2 turbine                           ', t, 'becomeUnavailable') = no;
utAvailabilityLimits('PT H2 turbine                           ', 't000001', 'becomeUnavailable') = yes;

* Update storage investments in the subsequent models
* Update transfer capacities in the subsequent models

* Update online group constraints in the subsequent models

* Do not allow unit investments in the subsequent models
p_unit('IE ev                                   ', 'maxUnitCount') = 0;
p_unit('IE ev                                   ', 'minUnitCount') = 0;
p_unit('SE ev                                   ', 'maxUnitCount') = 0;
p_unit('SE ev                                   ', 'minUnitCount') = 0;
p_unit('FR ev                                   ', 'maxUnitCount') = 0;
p_unit('FR ev                                   ', 'minUnitCount') = 0;
p_unit('IT ev                                   ', 'maxUnitCount') = 0;
p_unit('IT ev                                   ', 'minUnitCount') = 0;
p_unit('CZ ev                                   ', 'maxUnitCount') = 0;
p_unit('CZ ev                                   ', 'minUnitCount') = 0;
p_unit('BT ev                                   ', 'maxUnitCount') = 0;
p_unit('BT ev                                   ', 'minUnitCount') = 0;
p_unit('CH ev                                   ', 'maxUnitCount') = 0;
p_unit('CH ev                                   ', 'minUnitCount') = 0;
p_unit('BK ev                                   ', 'maxUnitCount') = 0;
p_unit('BK ev                                   ', 'minUnitCount') = 0;
p_unit('DE ev                                   ', 'maxUnitCount') = 0;
p_unit('DE ev                                   ', 'minUnitCount') = 0;
p_unit('NL ev                                   ', 'maxUnitCount') = 0;
p_unit('NL ev                                   ', 'minUnitCount') = 0;
p_unit('NO ev                                   ', 'maxUnitCount') = 0;
p_unit('NO ev                                   ', 'minUnitCount') = 0;
p_unit('DK ev                                   ', 'maxUnitCount') = 0;
p_unit('DK ev                                   ', 'minUnitCount') = 0;
p_unit('ES ev                                   ', 'maxUnitCount') = 0;
p_unit('ES ev                                   ', 'minUnitCount') = 0;
p_unit('PL ev                                   ', 'maxUnitCount') = 0;
p_unit('PL ev                                   ', 'minUnitCount') = 0;
p_unit('AT ev                                   ', 'maxUnitCount') = 0;
p_unit('AT ev                                   ', 'minUnitCount') = 0;
p_unit('PT ev                                   ', 'maxUnitCount') = 0;
p_unit('PT ev                                   ', 'minUnitCount') = 0;
p_unit('BE ev                                   ', 'maxUnitCount') = 0;
p_unit('BE ev                                   ', 'minUnitCount') = 0;
p_unit('FI ev                                   ', 'maxUnitCount') = 0;
p_unit('FI ev                                   ', 'minUnitCount') = 0;
p_unit('GB ev                                   ', 'maxUnitCount') = 0;
p_unit('GB ev                                   ', 'minUnitCount') = 0;
p_unit('PT Pumped Hydro Closed Pump             ', 'maxUnitCount') = 0;
p_unit('PT Pumped Hydro Closed Pump             ', 'minUnitCount') = 0;
p_unit('ES Lignite                              ', 'maxUnitCount') = 0;
p_unit('ES Lignite                              ', 'minUnitCount') = 0;
p_unit('PT Others renewable                     ', 'maxUnitCount') = 0;
p_unit('PT Others renewable                     ', 'minUnitCount') = 0;
p_unit('ES Hydro ROR Turbine                    ', 'maxUnitCount') = 0;
p_unit('ES Hydro ROR Turbine                    ', 'minUnitCount') = 0;
p_unit('PT Solar PV large                       ', 'maxUnitCount') = 0;
p_unit('PT Solar PV large                       ', 'minUnitCount') = 0;
p_unit('PT Hydro Reservoir Turbine              ', 'maxUnitCount') = 0;
p_unit('PT Hydro Reservoir Turbine              ', 'minUnitCount') = 0;
p_unit('ES Biofuel                              ', 'maxUnitCount') = 0;
p_unit('ES Biofuel                              ', 'minUnitCount') = 0;
p_unit('PT Wind Offshore                        ', 'maxUnitCount') = 0;
p_unit('PT Wind Offshore                        ', 'minUnitCount') = 0;
p_unit('PT Pumped Hydro Closed Turbine          ', 'maxUnitCount') = 0;
p_unit('PT Pumped Hydro Closed Turbine          ', 'minUnitCount') = 0;
p_unit('PT Pumped Hydro Open Pump               ', 'maxUnitCount') = 0;
p_unit('PT Pumped Hydro Open Pump               ', 'minUnitCount') = 0;
p_unit('ES Solar PV large                       ', 'maxUnitCount') = 0;
p_unit('ES Solar PV large                       ', 'minUnitCount') = 0;
p_unit('ES Wind Onshore                         ', 'maxUnitCount') = 0;
p_unit('ES Wind Onshore                         ', 'minUnitCount') = 0;
p_unit('ES Gas                                  ', 'maxUnitCount') = 0;
p_unit('ES Gas                                  ', 'minUnitCount') = 0;
p_unit('ES Others non-renewable                 ', 'maxUnitCount') = 0;
p_unit('ES Others non-renewable                 ', 'minUnitCount') = 0;
p_unit('ES Nuclear                              ', 'maxUnitCount') = 0;
p_unit('ES Nuclear                              ', 'minUnitCount') = 0;
p_unit('PT Wind Onshore                         ', 'maxUnitCount') = 0;
p_unit('PT Wind Onshore                         ', 'minUnitCount') = 0;
p_unit('ES Pumped Hydro Closed Pump             ', 'maxUnitCount') = 0;
p_unit('ES Pumped Hydro Closed Pump             ', 'minUnitCount') = 0;
p_unit('PT Lignite                              ', 'maxUnitCount') = 0;
p_unit('PT Lignite                              ', 'minUnitCount') = 0;
p_unit('ES Others renewable                     ', 'maxUnitCount') = 0;
p_unit('ES Others renewable                     ', 'minUnitCount') = 0;
p_unit('PT Hydro ROR Turbine                    ', 'maxUnitCount') = 0;
p_unit('PT Hydro ROR Turbine                    ', 'minUnitCount') = 0;
p_unit('PT Biofuel                              ', 'maxUnitCount') = 0;
p_unit('PT Biofuel                              ', 'minUnitCount') = 0;
p_unit('ES Hard Coal                            ', 'maxUnitCount') = 0;
p_unit('ES Hard Coal                            ', 'minUnitCount') = 0;
p_unit('ES Wind Offshore                        ', 'maxUnitCount') = 0;
p_unit('ES Wind Offshore                        ', 'minUnitCount') = 0;
p_unit('PT Nuclear                              ', 'maxUnitCount') = 0;
p_unit('PT Nuclear                              ', 'minUnitCount') = 0;
p_unit('PT Oil                                  ', 'maxUnitCount') = 0;
p_unit('PT Oil                                  ', 'minUnitCount') = 0;
p_unit('ES Hydro Reservoir Turbine              ', 'maxUnitCount') = 0;
p_unit('ES Hydro Reservoir Turbine              ', 'minUnitCount') = 0;
p_unit('PT Hard Coal                            ', 'maxUnitCount') = 0;
p_unit('PT Hard Coal                            ', 'minUnitCount') = 0;
p_unit('ES Pumped Hydro Open Turbine            ', 'maxUnitCount') = 0;
p_unit('ES Pumped Hydro Open Turbine            ', 'minUnitCount') = 0;
p_unit('PT Pumped Hydro Open Turbine            ', 'maxUnitCount') = 0;
p_unit('PT Pumped Hydro Open Turbine            ', 'minUnitCount') = 0;
p_unit('ES Pumped Hydro Open Pump               ', 'maxUnitCount') = 0;
p_unit('ES Pumped Hydro Open Pump               ', 'minUnitCount') = 0;
p_unit('ES Solar CSP                            ', 'maxUnitCount') = 0;
p_unit('ES Solar CSP                            ', 'minUnitCount') = 0;
p_unit('PT Others non-renewable                 ', 'maxUnitCount') = 0;
p_unit('PT Others non-renewable                 ', 'minUnitCount') = 0;
p_unit('PT Batteries Charge                     ', 'maxUnitCount') = 0;
p_unit('PT Batteries Charge                     ', 'minUnitCount') = 0;
p_unit('ES Batteries Charge                     ', 'maxUnitCount') = 0;
p_unit('ES Batteries Charge                     ', 'minUnitCount') = 0;
p_unit('ES Oil                                  ', 'maxUnitCount') = 0;
p_unit('ES Oil                                  ', 'minUnitCount') = 0;
p_unit('PT Solar CSP                            ', 'maxUnitCount') = 0;
p_unit('PT Solar CSP                            ', 'minUnitCount') = 0;
p_unit('PT Batteries Discharge                  ', 'maxUnitCount') = 0;
p_unit('PT Batteries Discharge                  ', 'minUnitCount') = 0;
p_unit('ES Batteries Discharge                  ', 'maxUnitCount') = 0;
p_unit('ES Batteries Discharge                  ', 'minUnitCount') = 0;
p_unit('ES Pumped Hydro Closed Turbine          ', 'maxUnitCount') = 0;
p_unit('ES Pumped Hydro Closed Turbine          ', 'minUnitCount') = 0;
p_unit('PT Gas                                  ', 'maxUnitCount') = 0;
p_unit('PT Gas                                  ', 'minUnitCount') = 0;
p_unit('PT electrolyser                         ', 'maxUnitCount') = 0;
p_unit('PT electrolyser                         ', 'minUnitCount') = 0;
p_unit('ES electrolyser                         ', 'maxUnitCount') = 0;
p_unit('ES electrolyser                         ', 'minUnitCount') = 0;
p_unit('ES H2 storage                           ', 'maxUnitCount') = 0;
p_unit('ES H2 storage                           ', 'minUnitCount') = 0;
p_unit('PT H2 storage                           ', 'maxUnitCount') = 0;
p_unit('PT H2 storage                           ', 'minUnitCount') = 0;
p_unit('PT H2 turbine                           ', 'maxUnitCount') = 0;
p_unit('PT H2 turbine                           ', 'minUnitCount') = 0;
p_unit('ES H2 turbine                           ', 'maxUnitCount') = 0;
p_unit('ES H2 turbine                           ', 'minUnitCount') = 0;

* Do not allow transfer link investments in the subsequent models
p_gnn('elec                                    ', 'PT elec                                 ', 'ES elec                                 ', 'transferCapInvLimit') = 0;
p_gnn('elec                                    ', 'ES elec                                 ', 'PT elec                                 ', 'transferCapInvLimit') = 0;

* Do not allow storage investments in the subsequent models
p_gnu_io('H2                                      ', 'ES H2 node                              ', 'ES H2 storage                           ',  'input', 'upperLimitCapacityRatio') = 0;
p_gnBoundaryPropertiesForStates('H2                                      ', 'ES H2 node                              ', 'upwardLimit', 'useConstant') = 1;
p_gnu_io('H2                                      ', 'PT H2 node                              ', 'PT H2 storage                           ',  'input', 'upperLimitCapacityRatio') = 0;
p_gnBoundaryPropertiesForStates('H2                                      ', 'PT H2 node                              ', 'upwardLimit', 'useConstant') = 1;
