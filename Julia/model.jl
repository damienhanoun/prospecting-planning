using JuMP
using HiGHS
using Dates
export create_model, create_variables, add_constraints!, set_objective!, extract_solution, resolve

function create_model()
    return Model(HiGHS.Optimizer)
end

function create_variables(model::Model, available_prospecting_periods, total_time_prospecting)
    vars = Dict()
    
    vars[:prospecting_times] = @variable(
        model, 
        [i=1:length(available_prospecting_periods)],
        base_name="prospecting_time",
        lower_bound=0,
        upper_bound=available_prospecting_periods[i].duration, 
        integer=true
    )
    
    vars[:daily_allocations] = Dict{Date, VariableRef}()
    unique_days = unique(Date.(p.start) for p in available_prospecting_periods)
    for (idx, day) in enumerate(unique_days)
        vars[:daily_allocations][day] = @variable(
            model, 
            base_name="daily_allocation_$idx",
            lower_bound=0,
            upper_bound=total_time_prospecting, 
            integer=true
        )
    end
    
    vars[:max_daily] = @variable(
        model, 
        base_name="max_daily_allocation",
        lower_bound=0,
        upper_bound=total_time_prospecting, 
        integer=true
    )
    vars[:min_daily] = @variable(
        model, 
        base_name="min_daily_allocation",
        lower_bound=0,
        upper_bound=total_time_prospecting, 
        integer=true
    )
    
    return vars
end

function add_constraints!(model::Model, vars, params)
    @constraint(model, sum(vars[:prospecting_times]) == params.total_time)
    
    for (i, time_var) in enumerate(vars[:prospecting_times])
        quotient = @variable(model, integer=true, base_name="quotient_$i")
        @constraint(model, time_var == params.avg_call_time * quotient)
    end
    
    periods_by_day = group_periods_by_day(params.periods)
    for (day, period_indices) in periods_by_day
        @constraint(model, 
            vars[:daily_allocations][day] == 
            sum(vars[:prospecting_times][i] for i in period_indices))
    end
    
    for daily_var in values(vars[:daily_allocations])
        @constraint(model, vars[:max_daily] >= daily_var)
        @constraint(model, vars[:min_daily] <= daily_var)
    end
end

function set_objective!(model::Model, vars, params)
    preference_weights = [PREFERENCE_WEIGHTS[period.timePreferenceKind] 
                         for period in params.periods]
    
    preference_objective = sum(w * t for (w, t) in zip(preference_weights, vars[:prospecting_times]))
    balance_objective = vars[:max_daily] - vars[:min_daily]
    
    @objective(model, Max, preference_objective - balance_objective)
end

function extract_solution(vars, periods, status)
    if status ∉ [MOI.OPTIMAL, MOI.FEASIBLE_POINT]
        return (success = false, message = "Not enough available time to schedule all calls.")
    end
    
    result = Dict{PeriodWithPreference, Int}()
    for (i, period) in enumerate(periods)
        minutes = value(vars[:prospecting_times][i])
        result[period] = Int(minutes)
    end
    
    return (success = true, result = result)
end

function resolve(
    available_prospecting_periods::Vector{PeriodWithPreference},
    number_of_prospects_calls::Int,
    average_time_to_get_a_prospect_on_the_phone_in_minutes::Int)
    
    params = (
        periods = available_prospecting_periods,
        total_time = number_of_prospects_calls * average_time_to_get_a_prospect_on_the_phone_in_minutes,
        avg_call_time = average_time_to_get_a_prospect_on_the_phone_in_minutes
    )
    
    model = create_model()
    vars = create_variables(model, params.periods, params.total_time)
    add_constraints!(model, vars, params)
    set_objective!(model, vars, params)
    
    optimize!(model)
    
    return extract_solution(vars, params.periods, termination_status(model))
end
