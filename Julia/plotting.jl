using Plots
using Measures
using Printf
export plot_schedule_with_limits

function plot_schedule_with_limits(periods, allocations, avg_call_time)
    periods_by_day = manual_groupby(p -> Date(p.start), periods)

    daily_totals = Dict{Date, Float64}()
    for (period, duration) in allocations
        day = Date(period.start)
        daily_totals[day] = get(daily_totals, day, 0.0) + duration/60  # Convert to hours
    end

    max_period_duration = maximum(period.duration for period in periods) / 60

    x_indices = Int[]
    day_labels = String[]
    day_positions = Float64[]
    days_ordered = Date[] 
    current_index = 1
    period_labels = String[]
    
    for (day, day_periods) in sort(collect(periods_by_day))
        day_start = current_index
        push!(days_ordered, day) 
        
        sort!(day_periods, by = p -> p.start)
        
        for period in day_periods
            push!(x_indices, current_index)
            push!(period_labels, Dates.format(period.start, "HH:MM"))
            current_index += 1
        end

        day_middle = (day_start + (current_index - 2)) / 2
        push!(day_positions, day_middle)
        push!(day_labels, Dates.format(day, "dd-mm"))
        
        current_index += 1
    end

    p = plot(
        size=(1400, 700),
        title="Prospecting planning on one month",
        ylabel="Time (hours)",
        legend=:top,
        grid=true,
        bottom_margin=20mm,
        left_margin=10mm,
        right_margin=20mm,
        top_margin=10mm,
        ylims=(0, max_period_duration + 0.5)
    )

    colors = Dict(
        Preferred => :blue,
        Neutral => :green,
        Unpreferred => :orange
    )

    scatter!([], [], color=:blue, label="Preferred feasible allocation", markersize=6)
    scatter!([], [], color=:green, label="Neutral feasible allocation", markersize=6)
    scatter!([], [], color=:orange, label="Unpreferred feasible allocation", markersize=6)

    for (i, period) in enumerate(periods)
        step_size = avg_call_time / 60
        max_calls = period.duration ÷ avg_call_time
        feasible_allocations = [j * step_size for j in 0:max_calls]
        
        scatter!(
            [x_indices[i] for _ in feasible_allocations], feasible_allocations,
            color=colors[period.timePreferenceKind],
            label=nothing,
            markersize=4,
            alpha=0.8
        )

        allocated_time = allocations[period] / 60
        bar!(
            [x_indices[i]], [allocated_time],
            color=:gray,
            alpha=0.6,
            label=i == 1 ? "Allocated Time" : ""
        )

        max_allocatable = period.duration / 60
        plot!(
            [x_indices[i] - 0.4, x_indices[i] + 0.4], [max_allocatable, max_allocatable],
            color=:red,
            linewidth=2,
            label=i == 1 ? "Maximum allocatable time" : nothing
        )
    end

    plot!(xticks=(x_indices, period_labels), xrotation=50)
    
    for (day_pos, day_label) in zip(day_positions, day_labels)
        annotate!(day_pos, -0.8, text(day_label, :center, 10))
    end

    for (day_pos, day) in zip(day_positions, days_ordered)
        total_hours = get(daily_totals, day, 0.0)
        annotate!(day_pos, -1.6, text(@sprintf("%.1f h", total_hours), :center, 10))
    end

    return p
end
