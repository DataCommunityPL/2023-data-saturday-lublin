USE [WideWorldImporters]
GO
 
CREATE NONCLUSTERED INDEX [MW_index_PurchaseOrder]
  ON [Sales].[Orders] ( [CustomerPurchaseOrderNumber] ASC )
GO