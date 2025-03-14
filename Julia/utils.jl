export manual_groupby, group_periods_by_day

function group_periods_by_day(periods)
    result = Dict{Date, Vector{Int}}()
    for (i, period) in enumerate(periods)
        day = Date(period.start)
        push!(get!(result, day, Int[]), i)
    end
    return result
end

function manual_groupby(f, collection)
    result = Dict{Any, Vector{Any}}()
    for item in collection
        key = f(item)
        if !haskey(result, key)
            result[key] = []
        end
        push!(result[key], item)
    end
    return result
end