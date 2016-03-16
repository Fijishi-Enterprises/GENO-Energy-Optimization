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
