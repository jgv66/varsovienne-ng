
USE BVARSOVIENNE
go
-- exec ksp_graba_guia_recepcion 5;
IF OBJECT_ID('ksp_graba_guia_recepcion', 'P') IS NOT NULL  
    DROP PROCEDURE ksp_graba_guia_recepcion;  
GO  
create procedure ksp_graba_guia_recepcion ( 
	@id_ktb	int,	
	@Error	nvarchar(250) OUTPUT, 
	@ErrMsg nvarchar(2048) OUTPUT )
AS
BEGIN
	--
	SET NOCOUNT ON;
	-- variable de error
	declare @error_vendedor	bit = 0,
			@xerr_desc		nvarchar(400) = '';
	-- kinetik
	DECLARE @folio				int = 0,
			@FolioSoftland		decimal(18,0),
			@folioant			int,
			@id_origen			int,
			@concepto			varchar(20),
			@CODALMACEN			varchar(10),
			@bodorigen			varchar(10),
			@CODVENDEDOR		varchar(4),
			@electronica		bit = 0,
			@_glosa_trasp		varchar(50),
			@CODCLIENTE			varchar(10);
	--Softland
	DECLARE @NroInt int = 0,		--El numero del nuevo registro de la tabla en softland
			@aprocesar int = 0,
			@procesados int = 0; 

	--desHabilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen DISABLE TRIGGER IW_GSaEnVW_ITRIG
	--
	set @Error	= 0;
	set @ErrMsg = '';
	--
	select  @CODALMACEN	  = rtrim(ktb.bodega)
			,@CODVENDEDOR = rtrim(ktb.vendedor)
			,@folio       = ktb.folio
			,@NroInt	  = ktb.nrointerno
			,@electronica = ktb.electronico
			,@concepto    = rtrim(ktb.concepto)
			,@bodorigen   = (select bodega from ktb_guia_encabezado as x where x.id = ktb.id_origen )
			,@folioant    = (select folio  from ktb_guia_encabezado as x where x.id = ktb.id_origen )
			,@_glosa_trasp= ktb.glosa_traspaso
			,@id_origen   = ktb.id_origen
	FROM ktb_guia_encabezado as ktb
	WHERE ktb.id = @id_ktb
	  and coalesce(ktb.cerrado,0) = 0
  	  -- and coalesce(ktb.traspasado,0)=1
	--
	--
	UPDATE ktb_guia_encabezado SET traspasado = 0,ultimointento = GETDATE(), glosa_traspaso='' WHERE id = @id_ktb;
	--
	begin try
		--*********************
		-- folio y nro.interno
		select @NroInt = coalesce(max(f.NroInt),0) + 1 from ARE_FolDispGuiaxBod as f where f.Tipo = 'E' ;
		select @folio  = coalesce( f.Folio ,0) + 1     from ARE_FolDispGuiaxBod as f where f.Tipo = 'E' and f.Concepto = @concepto and f.CodBode = @CODALMACEN;
		--
		while exists ( select * from BVARSOVIENNE.softland.iw_gsaen WHERE Tipo = 'E' and CodBode = @CODALMACEN and Folio = @folio and SubTipoDocto='A' ) begin
			set @folio += 1;
		end
		while exists ( select * from BVARSOVIENNE.softland.iw_gsaen WHERE Tipo = 'E' and Concepto = @concepto and CodBode = @CODALMACEN and Folio = @folio ) begin
			set @folio += 1;
		end
		--  and Concepto = @concepto and CodBode = @CODALMACEN and Folio = @folio  cambio realizado el 27/08/2020
		while exists ( select * from BVARSOVIENNE.softland.iw_gsaen WHERE Tipo = 'E' and NroInt = @NroInt ) begin
			set @NroInt += 1;
		end
		--
		--*********************
		--
--print 1
		SET ANSI_WARNINGS  OFF;
		--Inserto cabecera
		INSERT INTO	BVARSOVIENNE.softland.iw_gsaen
			    ( Tipo, NroInt, SubTipoDocto, CodBode,     CodBod,	  Folio,  Concepto,         CodAux, Estado, Fecha,                     Glosa,         AuxTipo, CodiCC,  SubTipDocRef, CodMoneda, Usuario, CentrodeCosto, NetoAfecto, IVA,   Subtotal, Total,   Sistema, Proceso,                 FecHoraCreacion,TipoServicioSII,TipDocRef, DTE_SiiTDoc, FactorCostoImportacion, TipoTrans, FmaPago, EsImportacion, ContabenCW, TipoDespacho, TotalDescBoleta, PorcCredEmpConst, DescCredEmpConst, Orden, Factura, AuxGuiaNum, Equivalencia, NetoExento,	PorcDesc01, Descto01, PorcDesc02, Descto02, PorcDesc03, Descto03, PorcDesc04, Descto04, PorcDesc05, Descto05, TotalDesc, Flete, Embalaje, StockActualizado, EnMantencion, ContabVenta, ContabCosto, ContDespPend, ContConsumo, ContVtaComp, nvnumero, ContabPago, NumGuiaTrasp, FueExportado, esDevolucion, MarcaWG, ListaMayorista, BoletaFiscal, ImpresaOK, ContabenPW, DescLisPreenMov, MotivoNCND, CorrelativoAprobacion )
		SELECT    'E',  @NroInt,'A',          @CODALMACEN, @bodorigen,@folio, rtrim(a.concepto),null,   'V',    cast( a.fecha as datetime),@_glosa_trasp, 'B',     a.ccosto,'A', 		 '01',       'web',   a.ccosto,      a.neto,     a.iva, a.neto,   a.bruto, 'IW',    'guia recepcion interna',null,           3,             null,      0,           1,				         1,         2,       0,             0,          0,            0,               0,                0,                0,     0,       0,          0,            0,            0,          0,        0,          0,        0,          0,        0,          0,        0,          0,        0,         0,     0,        -1,               0,            0,           0,           0,            0,           0,           0,        0,          @folioant,    0,            0,            0,       0,              0,            0,         0,          0,               0,          0   		
		FROM ktb_guia_encabezado AS a with (nolock)
		WHERE id = @id_ktb;
		--
--print 2
		-- folio y nro.interno
		SET ANSI_WARNINGS  OFF;
		--Ahora inserto el detalle
		INSERT INTO	BVARSOVIENNE.softland.iw_gmovi
		       ( Tipo, NroInt,  Linea,   CodProd,  CodBode,    Fecha,   CantIngresada, CantDespachada, CantFacturada, PreUniMB,       PreUniMVta,PreUniMOrig,FechaCompra,               PorcDescMov01,DescMov01,PorcDescMov02, DescMov02,PorcDescMov03, DescMov03, PorcDescMov04, DescMov04, PorcDescMov05, DescMov05,TotalDescMov, Equivalencia, Actualizado,TotLinea,   nvCorrela, TipoOrigen, TipoDestino, AuxTipo, CodAux, CodiCC,      Orden,ocCorrela, MarcaWG, ImpresaOk, CodUMed,     CantFactUVta, CantDespUVta, NumTrab, Recargo, TotalDescMovBoleta, PreUniBoleta, TotalBoleta,DetProd )
		SELECT   'E',  @NroInt, b.linea, b.codigo, @CODALMACEN,a.fecha, b.cantidad,    0,              0,             b.netoUnitario, 0,         0,          cast( a.fecha as datetime),0,            0,        0,             0,        0,             0,         0,             0,         0,             0,        0,            0,            -1,         b.subTotal, 0,         'N',        'D',         'B',     null,   @CODALMACEN, 0,    0,         0,       0,         b.unidadMed, 0,            b.cantidad,   0,       0,       0,                  0,            0,          b.descripcion
		FROM ktb_guia_detalle AS b with (nolock) 
		INNER JOIN ktb_guia_encabezado AS a with (nolock) ON b.id_padre = a.id
		WHERE id_padre = @id_ktb;
		--
--print 3
		-- actualizar la guia de traspaso
		UPDATE ktb_guia_encabezado SET cerrado = 1 WHERE id = @id_origen;
		--
		-- actualizar la recepcion
		UPDATE ktb_guia_encabezado SET cerrado = 1, traspasado = 1,glosa_traspaso = 'ok', folio = @folio, nrointerno = @NroInt WHERE id = @id_ktb;
		--
	end try
	--
	begin catch
		set @Error = @@ERROR;
		set @ErrMsg = ERROR_MESSAGE();
--print 66
--print @Error
--print @ErrMsg
		-- traspaso con error
		UPDATE ktb_guia_encabezado
		SET traspasado = 0,	glosa_traspaso = left( @ErrMsg, 200 )
		WHERE id = @id_ktb;
		-- Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
		ALTER TABLE BVARSOVIENNE.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG;
		--	
	end catch;
	--
	-- Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG
	--
END;
go