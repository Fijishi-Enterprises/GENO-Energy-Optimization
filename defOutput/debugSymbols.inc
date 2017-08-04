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

* Parameters
p_stepLength
p_data
p_data2d
ts_cf
ts_inflow
ts_stoContent
ts_reserveDemand

* Variables
v_obj
v_stoCharge
v_gen
v_fuelUse
v_spill
v_stoContent
v_online
v_startup
v_transfer
v_resTransCapacity
v_reserve

* equations
q_obj
q_balance
q_resDemand
q_maxDownward
q_maxUpward
q_storageControl
q_storageDynamics
q_bindStorage
q_startup
q_bindOnline
q_fuelUse
q_conversion
q_outputRatioFixed
q_outputRatioConstrained
q_stoMinContent
q_stoMaxContent
q_maxHydropower
q_transferLimit

* Dummy variables
vq_gen
vq_resDemand
vq_stoCharge
