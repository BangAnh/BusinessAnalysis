# BusinessAnalysis # Analyze-data-model-car #

-- the inventory in all the warehouses --
(select a.warehouseCode as WarehouseCode, format(total_quantity, '#,##') as Stock, format(total_buyprice, '#,##.00') as BuyPrice
from
 (select  warehouseCode, sum(quantityInStock) as total_quantity, sum(buyPrice * quantityInStock) as total_buyprice
 from mintclassics.products
 group by 1
 order by 3 desc
 ) a 
)
union all
select 'Total' as WarehouseCode,  format(sum(quantityInStock), '#,##.00') as Stock, format(sum(buyPrice * quantityInStock), '#,##.00') as BuyPrice
from mintclassics.products
;
