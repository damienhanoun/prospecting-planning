using JuMP
using HiGHS
using Dates
using Printf
using Plots
using Measures

include("types.jl")
include("model.jl")
include("schedule_generator.jl")
include("plotting.jl")
include("utils.jl")


function example()
    periods = generate_monthly_schedule(2025, 3)

    number_of_prospect_calls = 200
    average_time_per_call = 20 

    result = resolve(periods, number_of_prospect_calls, average_time_per_call)

    if result.success
        println("Solution found:")
        for (period, duration) in result.result
            @printf("Period starting at %s: %d minutes\n", period.start, duration)
        end

        p = plot_schedule_with_limits(periods, result.result, average_time_per_call)
        display(p)
    else
        println("Error: $(result.message)")
    end
end

example()

