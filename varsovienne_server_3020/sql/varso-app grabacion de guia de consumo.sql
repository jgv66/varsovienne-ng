USE BVARSOVIENNE
go
-- exec ksp_graba_guia_consumo_1 5;
IF OBJECT_ID('ksp_graba_guia_consumo_1', 'P') IS NOT NULL  
    DROP PROCEDURE ksp_graba_guia_consumo_1;  
GO  
create procedure ksp_graba_guia_consumo_1 ( 
	@id_ktb	int,	
	@Error	nvarchar(250) OUTPUT, 
	@ErrMsg nvarchar(2048) OUTPUT )
AS
BEGIN
	--
	SET NOCOUNT ON;
	-- ex. from docs.microsoft.com
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  
	-- variable de error
	declare @error_vendedor	bit = 0,
			@xerr_desc		nvarchar(400) = '';
	-- kinetik
	DECLARE @folio			int,
			@FolioSoftland	decimal(18,0),
			@concepto		varchar(20),
			@CODALMACEN		varchar(10),
			@CODVENDEDOR	varchar(4),
			@electronica	bit = 0,
			@CODCLIENTE		varchar(10);
	--Softland
	DECLARE @NroInt		int,		--El numero del nuevo registro de la tabla en softland
			@aprocesar	int = 0,
			@procesados int = 0; 

	--deshabilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programacion Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen DISABLE TRIGGER IW_GSaEnVW_ITRIG

	-- guia sin traspasar
	select  @CODALMACEN	  = rtrim(ktb.bodega)
			,@CODVENDEDOR = rtrim(ktb.vendedor)
			,@folio       = ktb.folio
			,@electronica = ktb.electronico
			,@concepto    = rtrim(ktb.concepto)
	FROM ktb_guia_encabezado as ktb  with (nolock)
	WHERE ktb.id = @id_ktb
  	  and coalesce(ktb.traspasado,0) = 1
	  and coalesce(ktb.cerrado,0) = 0
	--

	UPDATE ktb_guia_encabezado SET traspasado = 0,ultimointento = GETDATE(), glosa_traspaso='' WHERE id = @id_ktb;
	--
	-- Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el consumo.
	begin try

		-- si es un movimiento de consumo con guia electronica
		if ( @electronica = 1 ) begin
			-- folio
			select @folio = folio FROM ktb_folio_x_bodega as f with (nolock) where f.bodega = @CODALMACEN; 
			-- el nuevo NroInt de Softland
			SELECT @NroInt = ISNULL(MAX(NroInt) + 1,1) FROM BVARSOVIENNE.softland.iw_gsaen with (nolock);
			--
			while exists ( select * from BVARSOVIENNE.softland.iw_gsaen with (nolock) WHERE Tipo = 'S' and Concepto = @concepto and CodBode = @CODALMACEN and Folio = @folio and NroInt = @NroInt ) begin
				set @NroInt += 1;
			end
			--
		end
		else begin
			--*********************
			-- folio y nro.interno
			select @NroInt = coalesce(max(f.NroInt),0) + 1 from ARE_FolDispGuiaxBod as f where f.Tipo = 'S' ;
			select @folio  = coalesce( f.Folio ,0) + 1     from ARE_FolDispGuiaxBod as f where f.Tipo = 'S' and f.Concepto = @concepto and f.CodBode = @CODALMACEN;
			--
			while exists ( select * from BVARSOVIENNE.softland.iw_gsaen with (nolock) WHERE Tipo = 'S' and Concepto = @concepto and CodBode = @CODALMACEN and Folio = @folio ) begin
				set @folio += 1;
			end
			while exists ( select * from BVARSOVIENNE.softland.iw_gsaen with (nolock) WHERE Tipo = 'S' and Concepto = @concepto 
			and CodBode = @CODALMACEN and Folio = @folio and NroInt = @NroInt ) begin
				set @NroInt += 1;
			end
			--
		end;
		--*********************
		SET ANSI_WARNINGS  OFF;
		--Inserto cabecera
		INSERT INTO	BVARSOVIENNE.softland.iw_gsaen
				( Tipo, NroInt,  SubTipoDocto, CodBode,     CodBod, Folio,  Concepto,          Estado, Fecha,                     Glosa,                     AuxTipo, CodiCC,   SubTipDocRef, CodVendedor,  CodMoneda, Usuario,                       CentrodeCosto, NetoAfecto, IVA,   Subtotal, Total,   Sistema, Proceso,                FecHoraCreacion,TipoServicioSII,TipDocRef, DTE_SiiTDoc,                                       FactorCostoImportacion, TipoTrans, FmaPago, EsImportacion, ContabenCW, TipoDespacho, TotalDescBoleta, PorcCredEmpConst, DescCredEmpConst, Orden, Factura, AuxGuiaNum, Equivalencia, NetoExento, PorcDesc01, Descto01, PorcDesc02, Descto02, PorcDesc03, Descto03, PorcDesc04, Descto04, PorcDesc05, Descto05, TotalDesc, Flete, Embalaje, StockActualizado, EnMantencion, ContabVenta, ContabCosto, ContDespPend, ContConsumo, ContVtaComp, nvnumero, ContabPago, NumGuiaTrasp, FueExportado, esDevolucion, MarcaWG, ListaMayorista, BoletaFiscal, ImpresaOK, ContabenPW, DescLisPreenMov, MotivoNCND, CorrelativoAprobacion )
		SELECT    'S',  @NroInt, 'A',          @CODALMACEN, null,   @folio, rtrim(a.concepto), 'V',    cast( a.fecha as datetime),'guia interna de consumo', 'C',     a.ccosto, 'A',	      @CODVENDEDOR, '01',      cast(a.usuario as varchar(8)), a.ccosto,      a.neto,     a.iva, a.neto,   a.bruto, 'IW',    'guia consumo interno', getdate(),      3,              'A',       (CASE WHEN a.electronico = 1 THEN 52 ELSE 50 END), 1,                      1,         2,       0,             0,          0,            0,               0,                0,                0,     0,       0,          0,            0,          0,          0,        0,          0,        0,          0,        0,          0,        0,          0,        0,         0,     0,        0,                0,            0,           0,           0,            0,           0,           0,        0,          0,            0,            0,            0,       0,              0,            0,         0,          0,               0,          0   	
		FROM ktb_guia_encabezado AS a with (nolock)
		WHERE id = @id_ktb;
		-- print 222
		--
		-- select 1/0
		-- print 333
		--=¡
		SET ANSI_WARNINGS  OFF;
		--Ahora inserto el detalle
		INSERT INTO	BVARSOVIENNE.softland.iw_gmovi
			  ( Tipo, NroInt,  Linea,   CodProd,  CodBode,    Fecha,   CantIngresada, CantDespachada, CantFacturada,PreUniMB,      PreUniMVta,PreUniMOrig,PorcDescMov01,DescMov01,PorcDescMov02,DescMov02,PorcDescMov03,DescMov03, PorcDescMov04, DescMov04, PorcDescMov05, DescMov05,TotalDescMov,Equivalencia, Actualizado,TotLinea,  nvCorrela,TipoOrigen, TipoDestino, AuxTipo, CodAux, CodiCC,      Orden, ocCorrela, MarcaWG, ImpresaOk, CodUMed,     CantFactUVta, CantDespUVta, NumTrab, Recargo, TotalDescMovBoleta,PreUniBoleta, TotalBoleta,DetProd )
		SELECT  'S',  @NroInt, b.linea, b.codigo, @CODALMACEN,a.fecha, 0,             b.cantidad,     0,            b.netoUnitario,0,         0,          0,            0,        0,            0,        0,            0,         0,             0,         0,             0,        0,           0,            -1,         b.subTotal,0,        'D',        'N',         'C',     '',     @CODALMACEN, 0,     0,         0,       0,         b.unidadMed, 0,            b.cantidad,   0,       0,       0,                 0,            0,          b.descripcion
		FROM ktb_guia_detalle AS b with (nolock) 
		INNER JOIN ktb_guia_encabezado AS a with (nolock) ON b.id_padre = a.id
		WHERE id_padre = @id_ktb
		-- print 4444
		--
		-- consumo efectuado
		UPDATE ktb_guia_encabezado SET traspasado = 1,	glosa_traspaso = 'ok', folio = @folio, nrointerno = @NroInt WHERE id = @id_ktb
		--
		if ( @electronica = 1 ) begin
			if ( @folio = (	select top 1 folio FROM ktb_folio_x_bodega as f where f.bodega = @CODALMACEN ) ) begin
				update ktb_folio_x_bodega set folio = folio + 1 where bodega = @CODALMACEN; 
			end;
		end;
		--
	end try
	--
	begin catch
		--
		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();  
		-- traspaso con error
		UPDATE ktb_guia_encabezado SET traspasado = 0,	glosa_traspaso = left( @ErrorMessage, 200 ) WHERE id = @id_ktb;
		--
		-- Use RAISERROR inside the CATCH block to return error  
		-- information about the original error that caused  
		-- execution to jump to the CATCH block.  
		RAISERROR (@ErrorMessage, -- Message text.  
				   @ErrorSeverity, -- Severity.  
				   @ErrorState -- State.  
				   );  		
		-- THROW @ErrorSeverity, @ErrorMessage, 0 ;  
  		--		
	end catch;
	--
	-- Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG
	--
END
go
-- select * from ktb_guia_encabezado