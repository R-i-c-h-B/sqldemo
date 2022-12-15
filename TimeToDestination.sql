

create or alter procedure timetodestination
    @distance int = 60,
    @from int = 10, 
    @to int = 100,
    @timeunits sysname = 'minute',
    @increment int = 10
as
/****************************************************************
Author: Rich Bennett 20221215
Source: https://github.com/R-i-c-h-B/sqldemo

Purpose:
        Generate an output dataset of speed against duration 
        for a given speed range to travel a specified distance.
        Increment between speeds to be configurable at call time
        Time units to be configurable at call time

        Feel free to play.
To Do:
        Alternative to specify bucketize instead of increment.

Usage:
    exec timetodestination 
    exec timetodestination @timeunits = 'bad'
    exec timetodestination @from '800'
    exec timetodestination @increment = 4
    exec timetodestination @to = 40000000
    
    exec timetodestination 
        @to = 40000000, 
        @timeunits = 'year', 
        @increment = 10000000

****************************************************************/

declare 
    @startdatetime datetime = getutcdate(),
    @steps int,
    @unitmodifier float

declare 
    @year           float = 31557600.0,  -- select 365.25 * 24.0 * 60.0 * 60.0 
    @week           float = 604800.0,   -- select 7.0 * 24.0 * 60.0 * 60.0
    @day            float = 86400.0,     -- select 24.0 * 60.0 * 60.0
    @hour           float = 3600.0,     -- select 60.0 * 60.0
    @minute         float = 60.0,
    @second         float = 1.0,
    @millisecond    float = 1.0e+3, 
    @microsecond    float = 1.0e+6,
    @nanosecond     float = 1.0e+9

set @steps = 1 + ((@to - @from) / @increment)

declare @units table (timeunit sysname, unitmodifier float)
insert @units
    values
        --
        ('year',    @year),
        ('yy',      @year),
        ('yyyy',    @year),
        --
        ('week',    @week),
        ('wk',      @week),
        ('ww',      @week),
        --
        ('day',     @day),
        ('dd',      @day),
        ('d',       @day),
         --
        ('hour',    @hour),
        ('hh',      @hour),
        --
        ('minute',  @minute),
        ('mi',      @minute),
        ('n',       @minute),
        --
        ('second',  @second),
        ('ss',      @second),
        ('s',       @second),
        --
        ('millisecond', @millisecond),
        ('ms',          @millisecond),
        --
        ('microsecond', @microsecond),
        ('mcs',         @microsecond),
        --
        ('nanosecond', @nanosecond),
        ('ns',          @nanosecond)


begin try
    select 
        @unitmodifier = unitmodifier
        from @units
        where timeunit = @timeunits

    if @unitmodifier is null    
        throw 50000, '@timeunits parameter not recognised', 15;

    if @steps <= 0
        throw 50000, '@from or @to parameters out of range', 15;   
    
    --1     select @unitmodifier
    --1     select @steps;

    ;
    with tally(n) as
        (
            select top(@steps) row_number() over (order by (select null))
                from sys.all_columns a cross join sys.all_columns b
        )
            select 
                (@from + (@increment * (n - 1))) as speed, 
                (@unitmodifier / (@from + (@increment * (n - 1)))) * @distance as duration    
                from tally
            union -- Add the upper bound speed if increment would exclude.
            select @to, (@unitmodifier / @to) * @distance;

end try
begin catch
    throw
end catch
