-- the inventory in all the warehouses --
(select a.warehouseCode as WarehouseCode, format(total_quantity, '#,##') as Stock, 
 format(total_buyprice, '#,##.00') as BuyPrice
from
 (select  warehouseCode, sum(quantityInStock) as total_quantity, sum(buyPrice * quantityInStock) as total_buyprice
 from mintclassics.products
 group by 1
 order by 3 desc
 ) a 
)
union all
select 'Total' as WarehouseCode,  format(sum(quantityInStock), '#,##.00') as Stock, 
 format(sum(buyPrice * quantityInStock), '#,##.00') as BuyPrice
from mintclassics.products
;

-- the inventory of all product lines in all warehouses --
(select a.warehouseCode as WarehouseCode, a.productLine as ProductLine, 
 format(total_quantity, '#,##') as Stock, format(total_buyprice, '#,##') as BuyPrice
from
 (select  warehouseCode, productLine, sum(quantityInStock) as total_quantity, sum(buyPrice * quantityInStock) as total_buyprice
 from mintclassics.products
 group by 1,2
 order by 4 desc 
 ) a 
)
union all
select 'Total' as WarehouseCode, '-' as ProductLine, format(sum(quantityInStock), '#,##') as Stock, 
 format(sum(buyPrice * quantityInStock), '#,##') as BuyPrice
from mintclassics.products
;

-- the revenue of all warehouses --
(select s.warehouseCode as WarehouseCode, format(s.revenue, '#,##.00') as Revenue
from
 (select warehouseCode, sum(quantityOrdered * priceEach) as revenue
 from mintclassics.products p 
  join mintclassics.orderdetails d on d.productCode = p.productCode
  join mintclassics.orders o on o.orderNumber = d.orderNumber
  and o.status not like 'Cancelled'
  group by 1
  order by 2 desc
 ) s 
order by 2
)
union all
select 'Total' as warehouseCode, format(sum(revenue), '#,##.00') as Revenue
from 
 (select warehouseCode, sum(quantityOrdered * priceEach) as revenue
 from mintclassics.products p 
  join mintclassics.orderdetails d on d.productCode = p.productCode
  join mintclassics.orders o on o.orderNumber = d.orderNumber
  and o.status not like 'Cancelled'
  group by 1
 ) d ;


-- the revenue of each product line in all warehouses --
(select s.warehouseCode as WarehouseCode, s.productLine as ProductLine, format(s.revenue, '#,##.00') as Revenue
from
 (select warehouseCode, productLine, sum(quantityOrdered * priceEach) as revenue
 from mintclassics.products p 
  join mintclassics.orderdetails d on d.productCode = p.productCode
  join mintclassics.orders o on o.orderNumber = d.orderNumber
  and o.status not like 'Cancelled'
  group by 1,2
  order by 3 desc
  ) s
)
union all
select 'Total' as warehouseCode, '-' as ProductLine, format(sum(revenue), '#,##.00') as Revenue
from 
 (select warehouseCode, productLine, sum(quantityOrdered * priceEach) as revenue
 from mintclassics.products p 
  join mintclassics.orderdetails d on d.productCode = p.productCode
  join mintclassics.orders o on o.orderNumber = d.orderNumber
  and o.status not like 'Cancelled'
  group by 1,2
 ) d ;

-- the sales and the inventory-to-sales ratio for each product line --
(select a.warehouseCode as WarehouseCode, a.productLine as ProductLine, format(a.sales2005, '#,##') as Sales2005,
 format(a.sales2004, '#,##') as Sales2004, format(a.sales2003, '#,##') as Sales2003, format(a.quantity_store, '#,##') as Stock,
 round(a.quantity_store/sales2005,2) as StockSalesRatio05, 
 round(a.quantity_store/sales2004,2) as StockSalesRatio04, 
 round(a.quantity_store/sales2003,2) as StockSalesRatio03
from
 (select warehouseCode, productLine,
  sum(case when extract(year from orderDate) = 2005 then quantityOrdered else null end) as sales2005,
  sum(case when extract(year from orderDate) = 2004 then quantityOrdered else null end) as sales2004,
  sum(case when extract(year from orderDate) = 2003 then quantityOrdered else null end) as sales2003,
  sum(distinct quantityInStock) as quantity_store
 from mintclassics.products p
  left join mintclassics.orderdetails d on p.productCode = d.productCode 
  left join mintclassics.orders o on o.orderNumber = d.orderNumber
  and status not like 'Cancelled' 
  group by 1,2
  order by 6 desc
 ) a
)
union all
select 'Total' as WarehouseCode, '-' as ProductLine, 
 format(sum(b.Sales2005), '#,##') as Sales2005, format(sum(b.Sales2004), '#,##') as Sales2004, 
 format(sum(b.Sales2003), '#,##') as Sales2003, format(sum(b.Stock), '#,##') as Stock, 
 '-' as StockSalesRatio05, '-' as StockSalesRatio04, '-' as StockSalesRatio03
from
 (select a.warehouseCode as WarehouseCode, a.productLine as ProductLine, a.sales2005 as Sales2005,
  a.sales2004 as Sales2004, a.sales2003 as Sales2003, a.quantity_store as Stock,
  round(a.quantity_store/sales2005,2) as StockSalesRatio05, 
  round(a.quantity_store/sales2004,2) as StockSalesRatio04, round(a.quantity_store/sales2003,2) as StockSalesRatio03
 from
  (select warehouseCode, productLine,
   sum(case when extract(year from orderDate) = 2005 then quantityOrdered else null end) as sales2005,
   sum(case when extract(year from orderDate) = 2004 then quantityOrdered else null end) as sales2004,
   sum(case when extract(year from orderDate) = 2003 then quantityOrdered else null end) as sales2003,
   sum(distinct quantityInStock) as quantity_store
  from mintclassics.products p
   left join mintclassics.orderdetails d on p.productCode = d.productCode 
   left join mintclassics.orders o on o.orderNumber = d.orderNumber
   and status not like 'Cancelled' 
   group by 1,2
   order by 6 desc
  ) a
 ) b
;

-- top 15 items with the lowest inventory-to-sales ratios in the first five months of 2005 --
select row_number() over (order by round( stock/quantityOrdered,2)) as STT, 
 productCode as ProductCode, productLine as ProductLine, 
 warehouseCode as WarehouseCode , format(Stock, '#,##') as Stock, 
 quantityOrdered as Sales2005,
 round( stock/quantityOrdered,2) as StockSalesRatio
from
 (select p.productCode, productLine, warehouseCode, 
  sum(distinct quantityInStock) as Stock, 
  sum(case when extract(year from orderDate) = 2005 then quantityOrdered else null end) as quantityOrdered
 from mintclassics.products p 
  left join mintclassics.orderdetails d  on p.productCode = d.productCode
  left join mintclassics.orders o on o.orderNumber = d.orderNumber
  and status not like 'Cancelled'
  group by 1,2,3
  order by 5
 ) a
order by 7 
;


-- top 15 items with the highest inventory-to-sales ratios in the first five months of 2005 --
select row_number() over (order by round( stock/quantityOrdered,2) desc) as STT, 
 productCode as ProductCode, productLine as ProductLine, 
 warehouseCode as WarehouseCode , format(Stock, '#,##') as Stock, 
 quantityOrdered as Sales2005,
 round( stock/quantityOrdered,2) as StockSalesRatio
from
 (select p.productCode, productLine, warehouseCode, 
  sum(distinct quantityInStock) as Stock, 
  sum(case when extract(year from orderDate) = 2005 then quantityOrdered else null end) as quantityOrdered
 from mintclassics.products p 
  left join mintclassics.orderdetails d  on p.productCode = d.productCode
  left join mintclassics.orders o on o.orderNumber = d.orderNumber
  and status not like 'Cancelled'
  group by 1,2,3
  order by 5
 ) a
order by 7 desc
;

-- a product is not in any order through the years --
select p.warehouseCode as WarehouseCode, p.productLine as ProductLine, p.productCode as ProductCode, 
 format(quantityInStock, '#,##') as QuantityInStock 
from mintclassics.products p 
except 
 (select warehouseCode, productLine, d.productCode, format(quantityInStock, '#,##')
 from mintclassics.orderdetails d
  join mintclassics.orders o  on o.orderNumber = d.orderNumber
  join mintclassics.products p on p.productCode = d.productCode
  where status not like 'Cancelled'
  and extract( year from orderDate) = 2003
intersect
 select warehouseCode, productLine, d.productCode, format(quantityInStock, '#,##')
 from mintclassics.orderdetails d
  join mintclassics.orders o  on o.orderNumber = d.orderNumber
  join mintclassics.products p on p.productCode = d.productCode
  where status not like 'Cancelled'
  and extract( year from orderDate) = 2004
intersect
 select warehouseCode, productLine, d.productCode, format(quantityInStock, '#,##')
 from mintclassics.orderdetails d
  join mintclassics.orders o  on o.orderNumber = d.orderNumber
  join mintclassics.products p on p.productCode = d.productCode
  where status not like 'Cancelled'
  and extract( year from orderDate) = 2005
 )
;

-- the max, min and avg shipping time of the product lines --
select p.productLine as ProductLine, 
 max(datediff(shippedDate, orderDate)) as MaxShipTime, 
 min(datediff(shippedDate, orderDate)) as MinShipTime,
 round(avg(datediff(shippedDate, orderDate)),2) as AvgShipTime
from  mintclassics.products p
 join mintclassics.orderdetails d on p.productCode = d.productCode 
 join mintclassics.orders o on o.orderNumber = d.orderNumber
 where status not like 'Cancelled'
 and shippedDate is not null
 group by 1
 order by 1
;

-- delivery time and total orders of all successfully delivered orders --
select 
 case when shiptime = 1 then concat(shiptime, ' day') else concat(shiptime, ' days') end as ShippingTime, 
 count as ShippedOrder, concat(round((count/total)*100, 2), ' %') as Rate
from
 (select *, sum(count) over () as total
 from
  (select datediff( shippedDate, orderDate) as shiptime, count(datediff( shippedDate, orderDate)) as count
  from mintclassics.orders
   where status not like 'Cancelled'
   and shippedDate is not null
   group by 1
  )a 
 )b
order by 3 desc
;

-- the number of products sold in different countries --
select STT, Country, format(ClassicCars, '#,##') as ClassicCars,
 format(VintageCars, '#,##') as VintageCars, format(Motorcycles, '#,##') as Motorcycles, format(Planes, '#,##') as Planes,
 format(TrucksAndBuses, '#,##') as TrucksAndBuses, format(Ships, '#,##') as Ships, format(Trains, '#,##') as Trains,
 format(Total, '#,##') as Total
from
 (select row_number() over (order by sum(quantityOrdered) desc) as STT, country as Country, 
  sum(case when productLine = 'Classic Cars' then quantityOrdered else null end) as ClassicCars,
  sum(case when productLine = 'Vintage Cars' then quantityOrdered else null end) as VintageCars,
  sum(case when productLine = 'Motorcycles' then quantityOrdered else null end) as Motorcycles,
  sum(case when productLine = 'Planes' then quantityOrdered else null end) as Planes,
  sum(case when productLine = 'Trucks and Buses' then quantityOrdered else null end) as TrucksAndBuses,
  sum(case when productLine = 'Ships' then quantityOrdered else null end) as Ships,
  sum(case when productLine = 'Trains' then quantityOrdered else null end) as Trains,
  sum(quantityOrdered) as Total
 from mintclassics.customers c
  join mintclassics.orders o on c.customerNumber = o.customerNumber
  join mintclassics.orderdetails d on o.orderNumber = d.orderNumber
  join mintclassics.products p on p.productCode = d.productCode
  and status not like 'Cancelled'
  group by 2
  order by Total desc
 ) a 
union all
select '-' as STT, 'Total' as Country, 
 format(sum(ClassicCars), '#,##') as ClassicCars, format(sum(VintageCars), '#,##') as VintageCars,
 format(sum(Motorcycles), '#,##') as Motorcycles, format(sum(Planes), '#,##') as Planes, 
 format(sum(TrucksAndBuses), '#,##') as TrucksAndBuses, format(sum(Ships), '#,##') as Ships, 
 format(sum(Trains), '#,##') as Trains, format(sum(Total), '#,##') as Total
from
 (select row_number() over (order by sum(quantityOrdered) desc) as STT, country as Country, 
  sum(case when productLine = 'Classic Cars' then quantityOrdered else null end) as ClassicCars,
  sum(case when productLine = 'Vintage Cars' then quantityOrdered else null end) as VintageCars,
  sum(case when productLine = 'Motorcycles' then quantityOrdered else null end) as Motorcycles,
  sum(case when productLine = 'Planes' then quantityOrdered else null end) as Planes,
  sum(case when productLine = 'Trucks and Buses' then quantityOrdered else null end) as TrucksAndBuses,
  sum(case when productLine = 'Ships' then quantityOrdered else null end) as Ships,
  sum(case when productLine = 'Trains' then quantityOrdered else null end) as Trains,
  sum(quantityOrdered) as Total
 from mintclassics.customers c
  join mintclassics.orders o on c.customerNumber = o.customerNumber
  join mintclassics.orderdetails d on o.orderNumber = d.orderNumber
  join mintclassics.products p on p.productCode = d.productCode
  and status not like 'Cancelled'
  group by 2
  order by Total desc
 ) a
;
