-- COMP3311 20T3 Assignment 2
--
-- check.sql ... checking functions
--
-- Written by: John Shepherd, September 2012
-- Updated by: John Shepherd, October 2021
--

--
-- Helper functions
--

create or replace function
	ass1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	ass1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	ass1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- ass1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	ass1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- ass1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	ass1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not ass1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not ass1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not ass1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return ass1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- ass1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	ass1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not ass1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array[
				'q1', 'q2', 'q3', 'q4', 'q5', 
				'q6', 'q7', 'q8', 'q9',
				'q10a', 'q10b', 'q10c', 'q10d', 'q10e',
				'q11a', 'q11b', 'q11c', 'q11d', 'q11e',
				'q12a', 'q12b', 'q12c', 'q12d', 'q12e'
				];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Test Cases
--

-- Q1 --

create or replace function check_q1() returns text
as $chk$
select ass1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

drop table if exists q1_expected;
create table q1_expected (
    brewery text
);

COPY q1_expected (brewery) FROM stdin;
Bayerische Staatsbrauerei Weihenstephan
\.

-- Q2 --

create or replace function check_q2() returns text
as $chk$
select ass1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

drop table if exists q2_expected;
create table q2_expected (
    beer text
);

COPY q2_expected (beer) FROM stdin;
Age of Aquarius
Aro Street
Bentshovel xBa
Brekkie Juice
Cosmic Omnibus
Covered in Puppies
Daughters of the Neptune
Dream Cake
Dry Haze
Easy As Is Pretty Sweet
Escape from LA
Escape is Fruitile
Galaxy Valley
High Expectations
Hop Zombie[R]
Major Mac
My Antonia
No Dreams Til Brooklyn
Philosophy and Velocity
Six Four Four
Sunrise Valley
Tempest
Vampyre Lovers
Wattleseed Brown Ale
Yakima Valley
\.


-- Q3 --

create or replace function check_q3() returns text
as $chk$
select ass1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

drop table if exists q3_expected;
create table q3_expected (
    worst text
);

COPY q3_expected (worst) FROM stdin;
0.0
Carlton Draught
Tooheys New
Victoria Bitter (VB)
XXXX Bitter
\.


-- Q4 --

create or replace function check_q4() returns text
as $chk$
select ass1_check('view','q4','q4_expected',
                   $$select * from q4$$)
$chk$ language sql;

drop table if exists q4_expected;
create table q4_expected (
    beer text,
	abv ABVvalue,
	style text,
	max_abv ABVvalue
);

COPY q4_expected (beer,abv,style,max_abv) FROM stdin;
Sink the Bismarck	41	Quintuple IPA	18.5
\.


-- Q5 --

create or replace function check_q5() returns text
as $chk$
select ass1_check('view','q5','q5_expected',
                   $$select * from q5$$)
$chk$ language sql;

drop table if exists q5_expected;
create table q5_expected (
    style text
);

COPY q5_expected (style) FROM stdin;
IPA
\.


-- Q6 --

create or replace function check_q6() returns text
as $chk$
select ass1_check('view','q6','q6_expected',
                   $$select * from q6$$)
$chk$ language sql;

drop table if exists q6_expected;
create table q6_expected (
    style1 text,
    style2 text
);

COPY q6_expected (style1,style2) FROM stdin;
DOuble IPA	Double IPA
\.


-- Q7 --

create or replace function check_q7() returns text
as $chk$
select ass1_check('view','q7','q7_expected',
                   $$select * from q7$$)
$chk$ language sql;

drop table if exists q7_expected;
create table q7_expected (
    brewery text
);

COPY q7_expected (brewery) FROM stdin;
Alpine Beer Company
Capital Brewing Co
\.


-- Q8 --

create or replace function check_q8() returns text
as $chk$
select ass1_check('view','q8','q8_expected',
                   $$select * from q8$$)
$chk$ language sql;

drop table if exists q8_expected;
create table q8_expected (
    city text,
    country text
);

COPY q8_expected (city, country) FROM stdin;
Sydney	Australia
\.


-- Q9 --

create or replace function check_q9() returns text
as $chk$
select ass1_check('view','q9','q9_expected',
                   $$select * from q9$$)
$chk$ language sql;

drop table if exists q9_expected;
create table q9_expected (
    brewery text,
    nstyles integer
);

COPY q9_expected (brewery, nstyles) FROM stdin;
Akasha Brewing Company	9
Bacchus Brewing Company	10
Batch Brewing Co	6
Bentspoke Brewing Co	11
Big Shed Brewing	6
Bracket Brewing	6
Brewdog	8
Bridge Road Brewers	6
Dainton Brewing	9
Deeds Brewing	9
Frenchies Bistro and Brewery	7
Garage Project	13
Hawkers Beer	9
Hope Brewery	10
Moon Dog Craft Brewery	11
Mountain Culture Beer Co	15
One Drop Brewing Co.	13
Sierra Nevada Brewing Company	12
Stockade Brew Co	6
Tallboy & Moose Make Beer Pty Ltd	10
\.


-- Q10 --

create or replace function check_q10a() returns text
as $chk$
select ass1_check('function','q10','q10a_expected',
                   $$select * from q10('No such type')$$)
$chk$ language sql;

drop table if exists q10a_expected;
create table q10a_expected (
    beer text,
	brewery text,
	style text,
	year YearValue,
	abv ABVvalue
);

COPY q10a_expected (beer,brewery,style,year,abv) FROM stdin;
\.

create or replace function check_q10b() returns text
as $chk$
select ass1_check('function','q10','q10b_expected',
                   $$select * from q10('Quintuple IPA')$$)
$chk$ language sql;

drop table if exists q10b_expected;
create table q10b_expected (
    beer text,
	brewery text,
	style text,
	year YearValue,
	abv ABVvalue
);

COPY q10b_expected (beer,brewery,style,year,abv) FROM stdin;
F/A-18% Rhino IIIIIPA	Hope Brewery	Quintuple IPA	2019	18
Sink the Bismarck	Brewdog	Quintuple IPA	2010	41
\.

create or replace function check_q10c() returns text
as $chk$
select ass1_check('function','q10','q10c_expected',
                   $$select * from q10('Saison')$$)
$chk$ language sql;

drop table if exists q10c_expected;
create table q10c_expected (
    beer text,
	brewery text,
	style text,
	year YearValue,
	abv ABVvalue
);

COPY q10c_expected (beer,brewery,style,year,abv) FROM stdin;
Edward	Van Dieman Brewing	Saison	2019	5.4
Oceanna	Frenchies Bistro and Brewery	Saison	2020	3.5
Saison	Exit Brewing	Saison	2019	6.2
Saison Dupont	Brasserie Dupont	Saison	2020	6.5
Saison Dupont Cuvee Dry Hopping	Brasserie Dupont	Saison	2020	6.5
Single Hop India Saison	New England Brewing Co	Saison	2021	7.2
\.


create or replace function check_q10d() returns text
as $chk$
select ass1_check('function','q10','q10d_expected',
                   $$select * from q10('Double IPA')$$)
$chk$ language sql;

drop table if exists q10d_expected;
create table q10d_expected (
    beer text,
	brewery text,
	style text,
	year YearValue,
	abv ABVvalue
);

COPY q10d_expected (beer,brewery,style,year,abv) FROM stdin;
Cabin Fever	Hargreaves Hill Brewing Co	Double IPA	2020	8
Citra Double IPA	Liberty Brewing Company	Double IPA	2020	9
DDH Hi-Res	Sixpoint Brewery	Double IPA	2019	11.1
Day Trip	Hawkers Beer	Double IPA	2020	9
Double Destructor	Woolshed Brewery	Double IPA	2019	8.3
Double Moonage	Cellarmaker Brewing Co	Double IPA	2018	8.2
Double West Coast IPA	Hawkers Beer	Double IPA	2020	9
Further thru the Haze	Bear Republic Brewing	Double IPA	2020	8
Gone Green IIPA	Colonial Brewing Company	Double IPA	2021	8.2
Headliner	Otherside Brewing Co	Double IPA	2020	8
Intergalatic Lovechild	Deeds Brewing	Double IPA	2020	8
Kook	Pizza Port Brewing Company	Double IPA	2021	8.5
Korben D	Akasha Brewing Company	Double IPA	2019	8.5
Lupulin Effect	Deep Creek Brewing	Double IPA	2019	8.5
Lupus The Wolf Man	Garage Project	Double IPA	2020	9
Mandarina Meine Liebe	Hawkers Beer	Double IPA	2020	9
Mega-Hop	Sauce Brewing Co	Double IPA	2019	8.3
Oaked Guava DIPA	Big Shed Brewing	Double IPA	2021	8
Peak Conditions	Stone Brewing	Double IPA	2019	8.2
Pernicious Weed	Garage Project	Double IPA	2020	8
Poolside	Modern Times Beer	Double IPA	2020	8.5
Racer X	Bear Republic Brewing	Double IPA	2019	8.3
Road Tripper	Little Bang Brewing Co	Double IPA	2020	8.1
Romeo and Juliet	Akasha Brewing Company	Double IPA	2021	8
Smalltowner	New England Brewing Co	Double IPA	2019	7.9
Sonic Boom	N.O.M.A.D Brewing	Double IPA	2020	7.8
Tesselation	Lone Pine Brewing	Double IPA	2020	8.1
The Dank	Batch Brewing Co	Double IPA	2018	9
The Toques of Hazzard	Parallel49 Brewing Company	Double IPA	2020	9.2
Wasabi Sumo	Stockade Brew Co	Double IPA	2021	9
\.


create or replace function check_q10e() returns text
as $chk$
select ass1_check('function','q10','q10e_expected',
                   $$select * from q10('West Coast IPA')$$)
$chk$ language sql;

drop table if exists q10e_expected;
create table q10e_expected (
    beer text,
	brewery text,
	style text,
	year YearValue,
	abv ABVvalue
);

COPY q10e_expected (beer,brewery,style,year,abv) FROM stdin;
Back to Cali	Mountain Culture Beer Co	West Coast IPA	2020	7.6
Big Sur	Grifter Brewing Co	West Coast IPA	2021	6.7
Demon Cleaner	Kaiju! Beer	West Coast IPA	2020	6.7
Grain Dead	Epic Brewing Company	West Coast IPA	2021	6.7
Lloyd	Mountain Culture Beer Co	West Coast IPA	2021	8.2
NEeD vol.2	Bridge Road Brewers	West Coast IPA	2020	6.9
Old School	Wayward Brewing Co	West Coast IPA	2021	6.8
On the Fence	Bracket Brewing	West Coast IPA	2021	7.2
PC	Mountain Culture Beer Co	West Coast IPA	2021	7.1
Player 1	Epic Brewing Company	West Coast IPA	2021	6.7
Weaponized	Epic Brewing Company	West Coast IPA	2020	7
West Coast	Hope Brewery	West Coast IPA	2021	7
West Coast IPA	Bracket Brewing	West Coast IPA	2021	6.2
West Coast IPA	Mr.Banks Brewing Co	West Coast IPA	2020	6.2
\.


-- Q11 --

create or replace function check_q11a() returns text
as $chk$
select ass1_check('function','q11','q11a_expected',
                   $$select * from q11('ooo')$$)
$chk$ language sql;

drop table if exists q11a_expected;
create table q11a_expected (
    q11 text
);

COPY q11a_expected (q11) FROM stdin;
\.

create or replace function check_q11b() returns text
as $chk$
select ass1_check('function','q11','q11b_expected',
                   $$select * from q11('ool')$$)
$chk$ language sql;

drop table if exists q11b_expected;
create table q11b_expected (
    q11 text
);

COPY q11b_expected (q11) FROM stdin;
"Old School", Wayward Brewing Co, West Coast IPA, 6.8% ABV
"Poolside", Modern Times Beer, Double IPA, 8.5% ABV
\.

create or replace function check_q11c() returns text
as $chk$
select ass1_check('function','q11','q11c_expected',
                   $$select * from q11('xy')$$)
$chk$ language sql;

drop table if exists q11c_expected;
create table q11c_expected (
    q11 text
);

COPY q11c_expected (q11) FROM stdin;
"Fractal VicSecret/Galaxy", Equilibrium Brewery, NEIPA, 6.8% ABV
"Galaxy Fart Blaster", West City Brewing, Kettle soured Double IPA, 8.5% ABV
"Galaxy Valley", Garage Project + Trillium Brewing Company, Hazy Double IPA, 8% ABV
\.

create or replace function check_q11d() returns text
as $chk$
select ass1_check('function','q11','q11d_expected',
                   $$select * from q11('good')$$)
$chk$ language sql;

drop table if exists q11d_expected;
create table q11d_expected (
    q11 text
);

COPY q11d_expected (q11) FROM stdin;
"Feels Good Man", Carbon Brews, Hopfenweisse, 4.9% ABV
"Good of the Public", Societe Brewing Company, IPA, 6.5% ABV
\.

create or replace function check_q11e() returns text
as $chk$
select ass1_check('function','q11','q11e_expected',
                   $$select * from q11('al')$$)
$chk$ language sql;

drop table if exists q11e_expected;
create table q11e_expected (
    q11 text
);

COPY q11e_expected (q11) FROM stdin;
"2021 Vintage Ale", Coopers Brewery, Strong Ale, 7.5% ABV
"Alexander", Rodenbach Brewery, Flanders Red Ale, 5.6% ABV
"All Together Now", Revision Brewing Company, Hazy IPA, 6.5% ABV
"Anniversary Ale 11", Murrays Brewing Co, Imperial Porter, 10% ABV
"Arrogant Bastard Ale", Stone Brewing, Red IPA, 7.2% ABV
"Australian Ale", Shark Island Brewing Company, Ale, 4.3% ABV
"Avalanche", Brick Lane Brewing, Hazy IPA, 6.7% ABV
"Back to Cali", Mountain Culture Beer Co, West Coast IPA, 7.6% ABV
"Ball's Falls", Bench Brewing Coompany, Session IPA, 4.5% ABV
"California IPA", Sierra Nevada Brewing Company, IPA, 4.2% ABV
"Colossal Claude", Rogue Ales and Spirits, Imperial IPA, 8.2% ABV
"Conductor's Special Reserve Porter", Deeds Brewing, Baltic Porter, 9.5% ABV
"DDH Imperial IPA", Frenchies Bistro and Brewery, Imperial IPA, 8.2% ABV
"Digital Bath", Belching Beaver Brewery, NEIPA, 6.5% ABV
"Floral IPA", Sierra Nevada Brewing Company, IPA, 5.9% ABV
"Fractal VicSecret/Galaxy", Equilibrium Brewery, NEIPA, 6.8% ABV
"Galactic Space Dragon", Odin Brewing Co, IPA, 7% ABV
"Galactica", Clown Shoes Beer, IPA, 8% ABV
"Galaxy Fart Blaster", West City Brewing, Kettle soured Double IPA, 8.5% ABV
"Galaxy Valley", Garage Project + Trillium Brewing Company, Hazy Double IPA, 8% ABV
"Genetically Green", Frau Gruber, IPA, 6.5% ABV
"Go Local Sports Team", Chur (Behemoth) Brewing, Hazy Double IPA, 8% ABV
"Gulden Draak Imperial Stout", Brouwerij Van Steenberge, Imperial Stout, 12% ABV
"Hazy Pale", Bracket Brewing, NEIPA, 5.6% ABV
"Hitachino Nest Red Rice Ale", Kiuchi Brewery (Hitachino), Ale, 7% ABV
"Imperial Grapefruit Sour", Hope Brewery, Sour, 7% ABV
"Imperial IPA", Hawkers Beer, Imperial IPA, 9% ABV
"Imperial Mango Sour", Hope Brewery, Sour, 7% ABV
"Imperial Pink Grapefruit Sour", Hope Brewery, Sour, 7% ABV
"Imperial Simco Slacker", Evil Twin Brewing, IPA, 7.5% ABV
"Imperial Stout", Mountain Goat Beer, Imperial Stout, 12.1% ABV
"Imperial Stout", Ekim Brewing Co, Imperial Stout, 8.5% ABV
"Imperial Tart Blueberry Sour", Hope Brewery, Sour, 7% ABV
"India Red Ale", Prancing Pony Brewery, Red Double IPA, 7.9% ABV
"India Red Ale", Prancing Pony Brewery, Double Red IPA, 7.9% ABV
"Intergalatic Lovechild", Deeds Brewing, Double IPA, 8% ABV
"Lark Barrel-aged Imperial JSP III", Wolf of the Willows Brewing Co, Imperial Porter, 12.8% ABV
"Magical Christmas Unicorn", Bridge Road Brewers, Vanilla Ice Cream Ale, 7% ABV
"Market Sour Blood Orange and Saltbush", Colonial Brewing Company, Sour, 4.5% ABV
"Monks' Reserve Ale", Spencer Brewery, Belgian Quadrupel, 10.2% ABV
"Moralitie", Brasserie Dieu du Ciel!, Strong Ale, 6.9% ABV
"Motalus", Bacchus Brewing Company, IPA, 8.1% ABV
"Mother of All Storms", Pelican Brewing, Barley Wine, 14% ABV
"Narwhal (BA)", Sierra Nevada Brewing Company, Imperial Stout, 11.5% ABV
"Nitro Magical Christmas Unicorn", Bridge Road Brewers, Vanilla Ice Cream Ale, 7.3% ABV
"Nut Brown Ale", Samuel Smiths Brewery, Brown Ale, 5% ABV
"Oat Cream India Pale Ale", Grassy Knoll Brewing, IPA, 6.7% ABV
"Oatmeal Stout", Ocean Reach Brewing, Oatmeal Stout, 7.9% ABV
"Oatmeal Stout", Sierra Nevada Brewing Company, Imperial Stout, 9% ABV
"Orval", Brasserie d'Orval, Belgian Ale, 6.2% ABV
"Pacific Red Ale", 3 Ravens Brewing Co, Red IPA, 5.8% ABV
"Pale Ale", Algorithm Brewing, Pale Ale, 5% ABV
"Pale Ale", Mountain Culture Beer Co, Pale Ale, 5% ABV
"Pale Ale", Prancing Pony Brewery, Pale Ale, 5.5% ABV
"Pale Ale", Sierra Nevada Brewing Company, Pale Ale, 5% ABV
"Pumpkin Spiced Latte Ale", Pirate Life Brewing, Strong Ale, 8% ABV
"Rainbows Are Real", Clown Shoes Beer, Hazy IPA, 6.8% ABV
"Refreshing Ale", Stockade Brew Co, Pale Ale, 4.2% ABV
"Royal Fang", Tallboy & Moose Make Beer Pty Ltd, Red IPA, 6.1% ABV
"Royal Fresh", Deschutes Brewers, Imperial IPA, 9% ABV
"Russian Imperial Stout", Bracket Brewing, Russian Imperial Stout, 10.1% ABV
"Salted Caramel Brown Ale", 3 Ravens Brewing Co, Brown Ale, 4.5% ABV
"Salted Caramel Hazy IIIPA", Hope Brewery, Hazy Triple IPA, 11.3% ABV
"Scotch Ale", Caledonian Brewery, Scotch Ale, 6.4% ABV
"Smalltowner", New England Brewing Co, Double IPA, 7.9% ABV
"Sour Brett Ale", Holgate Brewhouse, Sour Blonde Ale, 5.8% ABV
"Sunrise Valley", Garage Project + Trillium Brewing Company, Hazy IPA, 8% ABV
"Sunset Ale", Two Birds Brewing, Amber Ale, 4.6% ABV
"Tactical Nuclear Penguin", Brewdog, Eisbock, 32% ABV
"Talk to the Hand", Garage Project, IPA, 5.8% ABV
"Talus", Akasha Brewing Company, IPA, 6% ABV
"The Almighty", Bad Shepherd Brewing Co, Imperial IPA, 8.5% ABV
"The Kalash", Hop Nation Brewing Co, Russian Imperial Stout, 10.7% ABV
"This is Foggin Unreal", Humble Sea Brewing, Hazy IPA, 6.8% ABV
"Toasted Marshmallow and Salted Caramel Pecan Mudcake", One Drop Brewing Co., Imperial Pastry Stout, 10% ABV
"Total Eclipse of the Hop", Two Birds Brewing, XPA, 5.5% ABV
"Trail Ale", Detour Beer Co, Pale Ale, 3.5% ABV
"Trappist Ale", Spencer Brewery, Belgian Golden Ale, 6.2% ABV
"Tropical Brut IPA", Frenchies Bistro and Brewery, Brut IPA, 6.5% ABV
"Under the Topical Sun", Hawkers Beer, Kettle Sour, 4% ABV
"Water Buffalo", Akasha Brewing Company, Brown Ale, 6% ABV
"Wattleseed Brown Ale", N.O.M.A.D Brewing + Rogue Ales and Spirits, Brown Ale, 5% ABV
"Yakima Valley", Garage Project + Trillium Brewing Company, Hazy Double IPA, 8% ABV
\.


-- Q12 --

create or replace function check_q12a() returns text
as $chk$
select ass1_check('function','q12','q12a_expected',
                   $$select * from q12('xyzzy')$$)
$chk$ language sql;

drop table if exists q12a_expected;
create table q12a_expected (
    q12 text
);

COPY q12a_expected (q12) FROM stdin;
\.

create or replace function check_q12b() returns text
as $chk$
select ass1_check('function','q12','q12b_expected',
                   $$select * from q12('goat')$$)
$chk$ language sql;

drop table if exists q12b_expected;
create table q12b_expected (
    q12 text
);

COPY q12b_expected (q12) FROM stdin;
Mountain Goat Beer, founded 1997
located in Richmond, Victoria, Australia
  "Imperial Stout", Imperial Stout, 2015, 12.1% ABV
\.

create or replace function check_q12c() returns text
as $chk$
select ass1_check('function','q12','q12c_expected',
                   $$select * from q12('moon')$$)
$chk$ language sql;

drop table if exists q12c_expected;
create table q12c_expected (
    q12 text
);

COPY q12c_expected (q12) FROM stdin;
Moon Dog Craft Brewery, founded 2010
located in Preston, Victoria, Australia
  "Jumping the Shark 2013", Imperial Stout, 2013, 15.4% ABV
  "Jumping the Shark 2015", Imperial Rye Stout, 2015, 18.4% ABV
  "Love Tap", Lager, 2018, 5% ABV
  "Ember's IPA", Red IPA, 2019, 7% ABV
  "Jumping the Shark 2019", Imperial Stout, 2019, 12.1% ABV
  "The Future is Bright", IPA, 2019, 6.6% ABV
  "Timothy Tamothy Slamothy", Milk Stout, 2019, 6.5% ABV
  "Dream Cake", Imperial Dark Ale, 2020, 8.8% ABV
  "Major Mac", Milk Stout, 2020, 6% ABV
  "Ogden Nash's Pash Rash", Imperial Stout, 2020, 8.2% ABV
  "The Duke of Chifley", Barley Wine, 2020, 12.2% ABV
  "The Pav is Ours", Pale Ale, 2020, 5.5% ABV
  "Bless the Haze", Oat Cream IPA, 2021, 7.2% ABV
  "EyePA", IPA, 2021, 7% ABV
  "Groundhog Daze", Hazy IPA, 2021, 6.2% ABV
  "Jumping the Shark 2021", Imperial Stout, 2021, 12.6% ABV
Moonraker Brewing, founded 2016
located in Auburn, California, United States
  "Zamboni Haze", Imperial IPA, 2017, 8% ABV
\.

create or replace function check_q12d() returns text
as $chk$
select ass1_check('function','q12','q12d_expected',
                   $$select * from q12('ale')$$)
$chk$ language sql;

drop table if exists q12d_expected;
create table q12d_expected (
    q12 text
);

COPY q12d_expected (q12) FROM stdin;
AleSmith Brewing Co, founded 1995
located in San Diego, California, United States
  "Anvil of Hope", Hazy Double IPA, 2019, 7.5% ABV
  "Escape is Fruitile", IPA, 2019, 7% ABV
  "Juice Stand", Hazy IPA, 2019, 6.7% ABV
  "Luped In IPA", IPA, 2019, 6.5% ABV
  "Cosmic Omnibus", Hazy IPA, 2020, 6.8% ABV
  "IPA", IPA, 2020, 7.2% ABV
  "Philosophy and Velocity", Imperial Stout + Quadrupel blend, 2020, 11.5% ABV
Birra Peroni Industriale, founded 2000
located in Roma, Lazio, Italy
  "Gran Riserva Rossa", Amber Lager, 2014, 5.2% ABV
Caledonian Brewery, founded 1869
located in Ediburgh, Lothian, Scotland
  "Scotch Ale", Scotch Ale, 2016, 6.4% ABV
Rogue Ales and Spirits, founded 1998
located in Newport, Oregon, United States
  "XS", Imperial IPA, 2016, 9.5% ABV
  "Hazelnut Brown Nectar", Brown Ale, 2019, 5.6% ABV
  "Chocolate Stout Nitro", Stout, 2020, 5.8% ABV
  "Coast Haste", Imperial Hazy IPA, 2020, 8.6% ABV
  "Colossal Claude", Imperial IPA, 2020, 8.2% ABV
  "Combat Wombat", Sour Hazy IPA, 2020, 6.7% ABV
  "Wattleseed Brown Ale", Brown Ale, 2020, 5% ABV
\.

create or replace function check_q12e() returns text
as $chk$
select ass1_check('function','q12','q12e_expected',
                   $$select * from q12('oun')$$)
$chk$ language sql;

drop table if exists q12e_expected;
create table q12e_expected (
    q12 text
);

COPY q12e_expected (q12) FROM stdin;
Counter Culture Brewing, founded 2019
located in Denver, Colorado, United States
  "Tequila Queen", Margarita, 2020, 7% ABV
Figueroa Mountain Brewing Co, founded 2010
located in Buellton, California, United States
  "Lizard's Mouth", Imperial IPA, 2019, 9% ABV
Founders Brewing Company, founded 1997
located in Grand Rapids, Michigan, United States
  "Breakfast Stout", Oatmeal Stout, 2018, 8.3% ABV
Future Mountain Brewing and Blending, founded 2019
located in Reservoir, Victoria, Australia
  "A Million Stars", Dark Farmhouse Ale, 2021, 5.5% ABV
Harviestoun Brewery, founded 1983
located in Alva, Stirlingshire, Scotland
  "Ola Dubh", Strong Ale, 2016, 8% ABV
Mountain Culture Beer Co, founded 2019
located in Katoomba, New South Wales, Australia
  "Back to Cali", West Coast IPA, 2020, 7.6% ABV
  "Double Red IPA", Double Red IPA, 2020, 8% ABV
  "Hypehopopotamus", NEIPA, 2020, 7.1% ABV
  "MSG", Oat Cream IPA, 2020, 6.9% ABV
  "Status Quo", NEPA, 2020, 5.6% ABV
  "5G", Oat Cream IPA, 2021, 7.6% ABV
  "Be Kind, Rewind", NEIPA, 2021, 7.3% ABV
  "Betamax", Oat Cream IPA, 2021, 7.5% ABV
  "Confetti Cannon", Oat Cream IPA, 2021, 7.3% ABV
  "Deep Cover", NEIPA, 2021, 6.2% ABV
  "Dolly", Hazy IPA, 2021, 7% ABV
  "El Hefe", Imperial Hefeweizen, 2021, 7% ABV
  "Ershaffer", Lager, 2021, 4.2% ABV
  "Garden Snake", NEIPA, 2021, 6.9% ABV
  "Harry", IPA, 2021, 8.8% ABV
  "Hill People Milk", Oat Cream NEIPA, 2021, 6.8% ABV
  "Hot Wax", NEIPA, 2021, 8.2% ABV
  "Lager", Lager, 2021, 4.6% ABV
  "Lloyd", West Coast IPA, 2021, 8.2% ABV
  "Mars Attacks", Marzen, 2021, 5.3% ABV
  "Moon Dust Stout", Stout, 2021, 5.6% ABV
  "Nancy", Oat Cream IPA, 2021, 7% ABV
  "Num Num Juice", Hazy Double IPA, 2021, 7.8% ABV
  "PC", West Coast IPA, 2021, 7.1% ABV
  "Pale Ale", Pale Ale, 2021, 5% ABV
  "Six Four Four", IPA, 2021, 8.2% ABV
  "Sticky Icky", Hazy IPA, 2021, 7.8% ABV
  "Toast", Stout, 2021, 9% ABV
  "Tonya", Milshake IPA, 2021, 7% ABV
  "Wanderlust", NEIPA, 2021, 7% ABV
Mountain Goat Beer, founded 1997
located in Richmond, Victoria, Australia
  "Imperial Stout", Imperial Stout, 2015, 12.1% ABV
Young Master Hong Kong, founded 2013
located in Wong Chuk Hang, Hong Kong
  "Dad Bod", Pale Ale, 2020, 5% ABV
\.
