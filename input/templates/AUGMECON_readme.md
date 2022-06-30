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


## Details on equations

### Objectives

all objective equations contain
- quantity to be counted/measured +
- penalties (energy balance, reserve provision, capacity margin) +
- slack variable * small scalar


### Constraints

all constraint equations are formulated as equalities, not inequalities, and contain
- quantity to be counted/measured +
- slack variable

### Cost

- based on "normal" objective function
- just added the slack variable and small scalar

### Emission

- 

### Generation

- sums up generation from inputs or outputs of units in a uGroup
- sums up all uGroups for which the new parameter objectiveWeight is defined
- the generation of each uGroup is mulitplied with the objectiveWeight
- using these equations requires adding a new parameter objectiveWeight to param_groupPolicy (to be specified in p_groupPolicy sheet) 
