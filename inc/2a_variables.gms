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

Free variable v_obj "Total operating cost (monetary unit)";
Free variables
    v_gen(grid, node, unit, s, f, t) "Energy generation or consumption in an interval (MW)"
    v_state(grid, node, s, f, t) "State variable for nodes that maintain a state (MWh, unless modified by energyStoredPerUnitOfState and diffCoeff parameters)"
    v_genRamp(grid, node, unit, s, f, t) "Change in energy generation or consumption over an interval (MW/h)"
    v_transfer(grid, node, node, s, f, t) "Average electricity transmission level from node to node during an interval (MW)"
;
Integer variables
    v_startup_MIP(unit, starttype, s, f, t) "Sub-units started up after/during an interval (p.u.), (MIP variant)"
    v_shutdown_MIP(unit, s, f, t) "Sub-units shut down after/during an interval (p.u.) (MIP variant)"
    v_online_MIP(unit, s, f, t) "Number of sub-units online for units with unit commitment restrictions"
    v_invest_MIP(unit, t) "Number of invested sub-units"
    v_investTransfer_MIP(grid, node, node, t) "Number of invested transfer links"
;
Binary variables
    v_help_inc(grid, node, unit, hr, s, f, t) "Helper variable to ensure that the first heat rate segments are used first"
;
SOS2 variables
    v_sos2(unit, s, f, t, effSelector) "Intermediate lambda variable for SOS2 based piece-wise linear efficiency curve"
;
Positive variables
    v_startup_LP(unit, starttype, s, f, t) "Sub-units started up after/during an interval (p.u.), (LP variant)"
    v_shutdown_LP(unit, s, f, t) "Sub-units shut down after/during an interval (p.u.) (LP variant)"
    v_genRampUpDown(grid, node, unit, slack, s, f, t) "Change in energy generation or consumption over an interval, separated into different 'slacks' (MW/h)"
    v_spill(grid, node, s, f, t) "Spill of energy from storage node during an interval (MWh)"
    v_transferRightward(grid, node, node, s, f, t) "Average electricity transmission level from the first node to the second node during an interval (MW)"
    v_transferLeftward(grid, node, node, s, f, t) "Average electricity transmission level from the second node to the first node during an interval (MW)"
    v_resTransferRightward(restype, up_down, grid, node, node, s, f, t) "Electricity transmission capacity from the first node to the second node reserved for providing reserves (MW)"
    v_resTransferLeftward(restype, up_down, grid, node, node, s, f, t) "Electricity transmission capacity from the second node to the first node reserved for providing reserves (MW)"
    v_reserve(restype, up_down, grid, node, unit, s, f, t) "Unit capacity reserved for providing reserve of specific type (MW)"
    v_investTransfer_LP(grid, node, node, t) "Invested transfer capacity (MW)"
    v_online_LP(unit, s, f, t) "Number of sub-units online for 'units' with unit commitment restrictions (LP variant)"
    v_invest_LP(unit, t) "Number of invested 'sub-units' (LP variant)"
    v_gen_inc(grid, node, unit, hr, s, f, t) "Energy generation in hr block in an interval (MW)"
;

* --- Feasibility control -----------------------------------------------------
Positive variables
    v_stateSlack(grid, node, slack, s, f, t) "Slack variable for different v_state slack categories, permits e.g. costs for exceeding acceptable v_states (MWh, unless modified by energyCapacity parameter)"
    vq_gen(inc_dec, grid, node, s, f, t) "Dummy energy generation (increase) or consumption (generation decrease) to ensure equation feasibility (MW)"
    vq_resDemand(restype, up_down, group, s, f, t) "Dummy to decrease demand for a reserve (MW) before the reserve has been locked"
    vq_resMissing(restype, up_down, group, s, f, t) "Dummy to decrease demand for a reserve (MW) after the reserve has been locked"
    vq_capacity(grid, node, s, f, t) "Dummy variable to ensure capacity margin equation feasibility (MW)"
;

