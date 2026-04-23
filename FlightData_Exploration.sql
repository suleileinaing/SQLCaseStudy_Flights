SELECT * FROM Airlines
SELECT * FROM Airports
SELECT * FROM Flights
SELECT * FROM Passengers
SELECT * FROM Tickets;



-- Q1. Find the busiest airport by the number of flights take off

SELECT Top 1 a.Name, Count(*) as flightCount
FROM Flights f INNER JOIN Airports a on f.Origin = a.AirportID
GROUP BY a.Name
ORDER BY flightCount DESC;



-- Q2. Total number of tickets sold per airline

SELECT a.Name, COUNT(*) as Total_Tickets
FROM Tickets t 
INNER JOIN Flights f on t.FlightID = f.FlightID
INNER JOIN Airlines a on f.AirlineID = a. AirlineID
GROUP BY a.Name;



-- Q3. List all the flights operated by 'IndiGo' with airport names (origin and destination)

SELECT f.FlightID, ap1.Name, ap2.Name
FROM Flights f 
INNER JOIN Airlines a on f.AirlineID = a.AirlineID
INNER JOIN Airports ap1 on f.Origin= ap1.AirportID
INNER JOIN Airports ap2 on f.Destination = ap2.AirportID
WHERE a.Name = 'IndiGo';



-- Q4. For each airport, show the top airlines by the number of flights departing from there. 
WITH CTE_flightRank AS (
SELECT *, 
        RANK() OVER (PARTITION BY Origin ORDER BY FlightCount DESC) as rn
FROM (
        SELECT f.origin, f.AirlineID, COUNT(*) AS FlightCount
        FROM Flights f
        GROUP BY f.origin, f.AirlineID
    )t
    )

SELECT A.Name AS AirportName, AL.Name as AirlineName, r.FlightCount
FROM CTE_flightRank r
JOIN Airports A ON r.Origin = A.AirportID
JOIN Airlines AL on r.AirlineID = AL.AirlineID
WHERE rn = 1;



--Q5. For Each Flight, show time taken in hours and categorize it as short (<2h), Medium (2-5h), or long (>5hr)

SELECT FlightID, DepartureTime, ArrivalTime, DATEDIFF(MINUTE, DepartureTime, ArrivalTime)/60 as Duration,
    CASE 
        WHEN DATEDIFF(MINUTE, DepartureTime, ArrivalTime) < 120 THEN 'Short'
        WHEN DATEDIFF(MINUTE, DepartureTime, ArrivalTime) > 300 THEN 'Long'
        ELSE 'Medium'
    END as FlightCategory
FROM Flights;



--Q6. Show each passenger's first and last flight dates and number of flights. 

SELECT p.PassengerID, MAX(p.Name) as Name, MIN(f.DepartureTime) as FirstFlight, MAX(f.DepartureTime) as LastFlight, COUNT(*) as TotalFlight
FROM Passengers p 
JOIN Tickets t on p.PassengerID = t.PassengerID
JOIN Flights f on t.FlightID = f.FlightID
GROUP BY p.PassengerID;



--Q7. Find flights with the highest price ticket sold for each route (origin -> destination)

WITH CTE_routetickets AS 
    (
    SELECT t.TicketID, f.FlightID, t.Price, f.Origin, f.Destination,
        RANK() OVER (PARTITION BY f.origin, f.Destination ORDER BY t.Price DESC) as rank
    FROM Tickets t
    JOIN Flights f on t.FlightID = f.FlightID
    )

SELECT A1.Name as Origin, A2.Name as Destination, r.Price, r.TicketID
FROM CTE_routetickets r
JOIN Airports A1 on A1.AirportID = r.Origin
JOIN Airports A2 on A2.AirportID = r.Destination
WHERE r.rank = 1



--Q8. Find the higest spending passenger in each frequent flyer status group. 

WITH CTE_spending as 
    (
    SELECT p.PassengerID, p.Name, p.FrequentFlyerStatus as FlyerStatus, SUM(t.Price) as TotalSpending,
         RANK() OVER (PARTITION BY MAX(p.FrequentFlyerStatus) ORDER BY SUM(t.Price) DESC) as rnk
    FROM Tickets t
    JOIN Passengers p
    on t.PassengerID = p.PassengerID
    GROUP BY p.Name, p.PassengerID, p.FrequentFlyerStatus
    )

SELECT PassengerID, Name, FlyerStatus, TotalSpending
FROM CTE_spending 
WHERE rnk = 1;



--Q9. Find the total revenue and number of tickets sold for each airline, and rank the airlines on total revenue.

SELECT A.Name, COUNT(*) as NumberOfTicket, SUM(t.Price) as TotalRevenue,
    RANK() OVER (ORDER BY SUM(t.price) Desc) as 'Rank'
FROM Airlines A
JOIN Flights f on A.AirlineID = F.AirlineID
JOIN Tickets t on f.FlightID = t.FlightID
GROUP BY A.AirlineID, A.Name;



-- Q10. For each passenger, identify their most frequently used airlline. If a passenger 
--has multiple airlines with the same highest usage, show all such airlines. 

WITH CTE_rank as 
(SELECT p.Name, a.Name as Airline, count(*) as Usage,
    RANK() OVER (PARTITION BY p.name ORDER BY count(*) DESC) as rnk
FROM Passengers p
JOIN Tickets t on p.PassengerID = t.PassengerID
JOIN Flights f on t.FlightID=f.FlightID
JOIN Airlines a on a.AirlineID = f.AirlineID
GROUP BY p.name, a.Name)

SELECT Name, Airline, Usage
FROM CTE_rank 
WHERE rnk = 1;
