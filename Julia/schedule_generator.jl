using Dates
export generate_monthly_schedule

# update this function to change preferences
function generate_monthly_schedule(year, month)
    periods = PeriodWithPreference[]

    morning_block = (start_time=Time(9, 30), end_time=Time(12, 0))
    lunch_block = (start_time=Time(12, 0), end_time=Time(14, 0))
    afternoon_block = (start_time=Time(14, 0), end_time=Time(18, 30))

    monday_preferred = (start_time=Time(14, 0), end_time=Time(16, 0))
    thursday_preferred = (start_time=Time(10, 30), end_time=Time(12, 0))

    first_day = Date(year, month, 1)
    last_day = Date(year, month, day(lastdayofmonth(first_day)))
    
    for day in first_day:last_day
        if dayofweek(day) in [6, 7]  # Saturday and Sunday
            continue
        end

        if dayofweek(day) == 4  # Thursday
            # Before preferred time
            if morning_block.start_time < thursday_preferred.start_time
                duration_minutes = Int(Dates.value(thursday_preferred.start_time - morning_block.start_time) ÷ 60_000_000_000)
                if duration_minutes > 0
                    push!(periods, PeriodWithPreference(
                        DateTime(day, morning_block.start_time),
                        duration_minutes,
                        Neutral
                    ))
                end
            end

            # Preferred time
            duration_minutes = Int(Dates.value(thursday_preferred.end_time - thursday_preferred.start_time) ÷ 60_000_000_000)
            push!(periods, PeriodWithPreference(
                DateTime(day, thursday_preferred.start_time),
                duration_minutes,
                Preferred
            ))
        else
            # Regular morning block
            duration_minutes = Int(Dates.value(morning_block.end_time - morning_block.start_time) ÷ 60_000_000_000)
            push!(periods, PeriodWithPreference(
                DateTime(day, morning_block.start_time),
                duration_minutes,
                Neutral
            ))
        end

        # Lunch block (unpreferred)
        duration_minutes = Int(Dates.value(lunch_block.end_time - lunch_block.start_time) ÷ 60_000_000_000)
        push!(periods, PeriodWithPreference(
            DateTime(day, lunch_block.start_time),
            duration_minutes,
            Unpreferred
        ))

        # Afternoon block
        if dayofweek(day) == 1  # Monday
            # Before preferred time
            if afternoon_block.start_time < monday_preferred.start_time
                duration_minutes = Int(Dates.value(monday_preferred.start_time - afternoon_block.start_time) ÷ 60_000_000_000)
                if duration_minutes > 0
                    push!(periods, PeriodWithPreference(
                        DateTime(day, afternoon_block.start_time),
                        duration_minutes,
                        Neutral
                    ))
                end
            end

            # Preferred time
            duration_minutes = Int(Dates.value(monday_preferred.end_time - monday_preferred.start_time) ÷ 60_000_000_000)
            push!(periods, PeriodWithPreference(
                DateTime(day, monday_preferred.start_time),
                duration_minutes,
                Preferred
            ))

            # After preferred time
            if monday_preferred.end_time < afternoon_block.end_time
                duration_minutes = Int(Dates.value(afternoon_block.end_time - monday_preferred.end_time) ÷ 60_000_000_000)
                if duration_minutes > 0
                    push!(periods, PeriodWithPreference(
                        DateTime(day, monday_preferred.end_time),
                        duration_minutes,
                        Neutral
                    ))
                end
            end
        else
            # Regular afternoon block
            duration_minutes = Int(Dates.value(afternoon_block.end_time - afternoon_block.start_time) ÷ 60_000_000_000)
            push!(periods, PeriodWithPreference(
                DateTime(day, afternoon_block.start_time),
                duration_minutes,
                Neutral
            ))
        end
    end

    return periods
end