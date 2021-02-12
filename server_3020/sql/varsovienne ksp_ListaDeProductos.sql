
-- select top 100 * from softland.iw_tprod
-- exec ksp_ListaDeProductos '100'
IF OBJECT_ID('ksp_ListaDeProductos', 'P') IS NOT NULL  
    DROP PROCEDURE ksp_ListaDeProductos;  
GO  
CREATE PROCEDURE ksp_ListaDeProductos ( 
		@buscando varchar(80) ) With Encryption
AS
BEGIN
	-- 
	declare @query NVARCHAR(3500) = '';
	--	 
    SET NOCOUNT ON
	--
	set @query += 'select top 50 so.CodProd, so.DesProd, cast(0 as bit) as abierto, '''' as stock, so.CodUMed as unidadMed, ROUND(costo.Costo,3) as netoUnitario, 0.0 as cantidad ';
	set @query += 'from softland.iw_tprod as so with (nolock) ';
	set @query += 'left join ARE_CostoProd as costo with (nolock) on costo.CodProd = so.CodProd ';
	set @query += 'where so.CodProd like '+char(39)+rtrim(@buscando)+'%'+char(39) ;
	set @query +=   ' or so.DesProd like '+char(39)+'%'+rtrim(@buscando)+'%'+char(39) ;
	set @query += ' order by so.CodProd ;' ;

	-- select @query

	EXECUTE sp_executesql @query;

END
go
