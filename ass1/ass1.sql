-- COMP3311 21T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file MUST load into a database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without errorunder these conditions


-- Q1: oldest brewery

create or replace view Q1(brewery)
as
    select name
    from breweries
    where founded = (select min(founded)
                     from breweries)
    order by name;
;

-- Q2: collaboration beers

create or replace view breweryEachBeer(beerId, breweryNum)
as
    select beer, count(*)
    from brewed_by
    group by beer;
;

create or replace view Q2(beer)
as
    select name
    from beers, breweryEachBeer
    where (beers.id = breweryEachBeer.beerId
           and breweryNum > 1)
    order by name;
;

-- Q3: worst beer

create or replace view Q3(worst)
as
    select name
    from beers
    where rating = (select min(rating)
                    from beers)
    order by name;
;

-- Q4: too strong beer

create or replace view Q4(beer,abv,style,max_abv)
as
    select beers.name, abv, styles.name, max_abv
    from beers, styles
    where (beers.style = styles.id
           and beers.abv > styles.max_abv)
    order by beers.name, abv, styles.name, max_abv;
;

-- Q5: most common style

create or replace view beersEachStyle(styleId, beerNum)
as
    select styles.id, count(*)
    from styles, beers
    where styles.id = beers.style
    group by styles.id;
;

create or replace view Q5(style)
as
    select name
    from styles, beerseachstyle
    where (styles.id = beersEachStyle.styleId
           and beersEachStyle.beerNum = (select max(beerNum)
                                         from beersEachStyle))
    order by name;
;

-- Q6: duplicated style names

create or replace view Q6(style1,style2)
as
    select s1.name, s2.name
    from styles as s1, styles as s2
    where (s1.name < s2.name
           and upper(s1.name) = upper(s2.name));
;

-- Q7: breweries that make no beers

create or replace view Q7(brewery)
as
    select name
    from breweries
    where id not in (select distinct brewery from brewed_by)
    order by name;
;

-- Q8: city with the most breweries

create or replace view breweriesEachCity(locationId, city, breweryNum)
as
    select locations.id, locations.metro, count(*)
    from locations, breweries
    where breweries.located_in = locations.id
    group by locations.id, locations.metro;
;

create or replace view Q8(city,country)
as
    select city, country
    from breweriesEachCity, locations
    where (locations.id = breweriesEachCity.locationId
           and breweryNum = (select max(breweryNum)
                             from breweriesEachCity))
    order by city, country;
;

-- Q9: breweries that make more than 5 styles

create or replace view breweryStyle(breweryId, styleId)
as
    select distinct breweries.id, beers.style
    from breweries, brewed_by, beers
    where breweries.id = brewed_by.brewery and brewed_by.beer = beers.id
;

create or replace view stylesEachBrewery(breweryId, styleNum)
as
    select breweryId, count(*)
    from breweryStyle
    group by breweryId;
;

create or replace view Q9(brewery,nstyles)
as
    select name, styleNum
    from breweries, stylesEachBrewery
    where (breweries.id = stylesEachBrewery.breweryId
           and stylesEachBrewery.styleNum > 5)
    order by name, styleNum;
;

-- Q10: beers of a certain style

create or replace view beerBrewery(beerId, breweryName)
as
    select beers.id, breweries.name
    from beers, brewed_by, breweries
    where beers.id = brewed_by.beer and brewed_by.brewery = breweries.id;
;

create type beerAllBreweries as (beerId integer, allBreweries text);

create or replace function
    beerBreweries() returns setof beerAllBreweries
as $$
declare beerTuple record; breweryTuple record;
        info beerAllBreweries;
        i integer;
begin
    for beerTuple in
        select * from breweryEachBeer
    loop
        info.beerId := beerTuple.beerId;
        info.allBreweries := '';
        i := 1;
        for breweryTuple in
            select breweryName
            from beerBrewery
            where beerBrewery.beerId = beerTuple.beerId
            order by breweryName
        loop
            info.allBreweries := info.allBreweries || breweryTuple.breweryName;
            if i < beerTuple.breweryNum then
                info.allBreweries := info.allBreweries || ' + ';
            end if;
            i := i + 1;
        end loop;
        return next info;
    end loop;
end;
$$
language plpgsql;

create or replace view BeerInfo(beer,brewery,style,year,abv)
as
    select beers.name, beerBreweries.allBreweries, styles.name, beers.brewed, beers.abv
    from beers, beerBreweries(),styles
    where beers.id = beerBreweries.beerid and beers.style = styles.id
    order by beers.name;
;

create or replace function
	q10(_style text) returns setof BeerInfo
as $$
begin
    if _style not in (select name from styles) then
        return ;
    end if;

    return query (select * from BeerInfo where style = _style);
end
$$
language plpgsql;

-- Q11: beers with names matching a pattern

create or replace function
	Q11(partial_name text) returns setof text
as $$
declare info text; tuple record; regex text;
begin
    regex := '%' || lower(partial_name) || '%';
    for tuple in
        select * from BeerInfo where lower(BeerInfo.beer) like regex
    loop
        info := '"' || tuple.beer || '"'
                || ', ' || tuple.brewery || ', '
                || tuple.style || ', ' || tuple.abv || '% ABV';
        return next info;
    end loop;
end;
$$
language plpgsql;

-- Q12: breweries and the beers they make

create or replace function
	Q12(partial_name text) returns setof text
as $$
begin

end;
$$
language plpgsql;
