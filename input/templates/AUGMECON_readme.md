## File structure

 - AUGMECON_XXX_2c_alternative_objective.gms
    - XXX = COST, EMISSION or GENERATION
    - contains
        - new equation for XXX to be used as objective function
        - definition of positive slack variable v_epsSlack
        - definition of smallScalar (default value 1e-6)

 - AUGMECON_XXX_2e_additional_constraints.gms
    - XXX = COST, EMISSION or GENERATION
    - contains
        - new equation for XXX to be used as constraint (almost the same as objective function equation)
        - new scalar for upper limit value of constraint

 - AUGMECON_XXX_additional_constraints.gms
    - XXX = invest or schedule
    - contains equation names of three new constraints (comment in/out dependin on which one you are using)


## How to use it

- to use an alternative objective, copy it in your input folder and name it "2c_alternative_objective.gms"
- to use additional constraints
    - copy one or multiple of them in a file "2e_additional_constraints.gms" in your input folder
    - include the corresponding equation names in a file "invest_additional_constraints.gms" in your input folder (or "schedule_additional_constraints.gms" if you are using a schedule model)
    - set the caps with new command line arguments/input data values as described below
- run Backbone as usual  

## Details on equations

### Cost objective

- based on "normal" objective function
- plus slack variable * small scalar

### Cost constraint

- equality constraint
- based on objective function plus slack variable
- cap can be set with new command line argument --maxTotalCost=XXX, default is inf

### Emission objective

- objective sums up all emissions of all units (all emission types, start up and shut down, all units)
- plus penalties, plus slack variable * small scalar
- this can e.g. be changed by hard-coding certain emission type in objective function

### Emission constraint

- just like "normal" emission constraint, but plus slack variable and thus equality constraint 
- can be used per gnGroup and per emission "as usual" using emissionCap parameter in param_groupPolicyEmission

### Generation objective

- sums up generation from inputs or outputs (changing inputs/outputs is hard-coded atm) of units in a uGroup
- sums up all uGroups for which the new parameter objectiveWeight is defined
- the generation of each uGroup is mulitplied with the objectiveWeight
- v_{obj} = sum_{uGroups} ( objectiveWeight_uGroup * sum_{units} (generation) )
- using the generation equations requires adding a new parameter objectiveWeight to param_groupPolicy (to be specified in p_groupPolicy sheet)

### Generation constraint 

- based on generation objective
- cap can be set with new command line argument maxTotalGeneration, default is inf
