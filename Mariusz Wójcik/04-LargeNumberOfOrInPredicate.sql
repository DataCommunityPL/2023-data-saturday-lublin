USE WideWorldImporters;

SELECT * 
FROM   Sales.Orders 
WHERE  CustomerPurchaseOrderNumber IN (10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030,10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,10058,10059,10060,10061,10062,10063,10064,10065,10066,10067,10068,10069,10070 ); 

















/*

od 65 pojawia się antipattern_type = LargeNumberOfOrInPredicate

SELECT STRING_AGG( CustomerPurchaseOrderNumber,',')
FROM ( SELECT DISTINCT TOP 70 CustomerPurchaseOrderNumber
       FROM Sales.Orders) Orders;
DBCC FREEPROCCACHE;
 */


 --jak wyeliminować antipattern_type = LargeNumberOfOrInPredicate

SELECT [OrderID]
	  ,[CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,[OrderDate]
      ,[ExpectedDeliveryDate]
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,[Comments]
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen] 
FROM   Sales.Orders 
WHERE  CustomerPurchaseOrderNumber IN ( 
		SELECT * FROM (VALUES (10001),(10002),(10003),(10004),(10005),(10006),(10007),(10008),(10009),(10010),(10011),(10012),(10013),(10014),(10015),(10016),(10017),(10018),(10019),(10020),(10021),(10022),(10023),(10024),(10025),(10026),(10027),(10028),(10029),(10030),(10031),(10032),(10033),(10034),(10035),(10036),(10037),(10038),(10039),(10040),(10041),(10042),(10043),(10044),(10045),(10046),(10047),(10048),(10049),(10050),(10051),(10052),(10053),(10054),(10055),(10056),(10057),(10058),(10059),(10060),(10061),(10062),(10063),(10064),(10065),(10066),(10067),(10068),(10069),(10070)) AS mylist (CustomerPurchaseOrderNumber) 
		);


--a tak pozbędziemy się dodatkowo antipattern_type = TypeConvertPreventingSeek

SELECT [OrderID]
      ,[CustomerID]
      ,[SalespersonPersonID]
      ,[PickedByPersonID]
      ,[ContactPersonID]
      ,[BackorderOrderID]
      ,[OrderDate]
      ,[ExpectedDeliveryDate]
      ,[CustomerPurchaseOrderNumber]
      ,[IsUndersupplyBackordered]
      ,[Comments]
      ,[DeliveryInstructions]
      ,[InternalComments]
      ,[PickingCompletedWhen]
      ,[LastEditedBy]
      ,[LastEditedWhen] 
FROM   Sales.Orders
WHERE EXISTS  ( 
SELECT 1 FROM (VALUES (10001),(10002),(10003),(10004),(10005),(10006),(10007),(10008),(10009),(10010),(10011),(10012),(10013),(10014),(10015),(10016),(10017),(10018),(10019),(10020),(10021),(10022),(10023),(10024),(10025),(10026),(10027),(10028),(10029),(10030),(10031),(10032),(10033),(10034),(10035),(10036),(10037),(10038),(10039),(10040),(10041),(10042),(10043),(10044),(10045),(10046),(10047),(10048),(10049),(10050),(10051),(10052),(10053),(10054),(10055),(10056),(10057),(10058),(10059),(10060),(10061),(10062),(10063),(10064),(10065),(10066),(10067),(10068),(10069),(10070)) AS mylist (CustomerPurchaseOrderNumber)
  WHERE CustomerPurchaseOrderNumber = mylist.CustomerPurchaseOrderNumber );
 
