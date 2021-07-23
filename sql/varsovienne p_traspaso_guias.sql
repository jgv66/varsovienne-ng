USE [GESTIONVARSO]
GO
-- exec [Traspaso].[p_traspaso_guias]
-- =================================================
-- Author:	kinetik.cl
-- Create date: 201912013
-- Description:	incorporar guias de entrada al local 
-- =================================================
ALTER PROCEDURE [Traspaso].[p_traspaso_guias]
AS
BEGIN
	--
	SET NOCOUNT ON;
	--
	insert into GESTIONVARSO.dbo.ktb_procesos ( fechahora, accion, cantidad ) values ( getdate(), 'inicio de proceso', 0) ;
	--
	if object_id('ktb_paso')>0 drop table ktb_paso;
	-- los no traspasados
	SELECT DISTINCT
		a.CodBod as CodBode, a.Tipo, a.SubTipoDocto,  /* ojo bodega de destino sera usada !!! */
		a.Folio as folio_guia, e.RutAux,
		cast('' as varchar(20)) as NUMSERIE, 
		cast(0 as bit) as NUMALBARANcalculado, a.Folio, 'B' as N, cast(0 as bit) as FACTURADO,
		cast('' as varchar(20)) as NUMSERIEFAC, 1 as ConNUMFAC, a.Folio as NUMFAC,
		22 as TIPODOC,
		'ALBCOMPRACAB' as Tabla, 
		1 as MultiploCantIngresada, 0 as MultiploCantDespachada, 0 asMultiploCantFacturada
	-- into GESTIONVARSO.dbo.ktb_paso
	FROM
		BVARSOVIENNE.softland.iw_gsaen             AS a
		INNER JOIN BVARSOVIENNE.softland.iw_gmovi  AS b ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
		LEFT  JOIN BVARSOVIENNE.softland.cwtauxi   AS e ON e.CodAux = a.CodAux
		/*LEFT  JOIN GESTIONVARSO.Traspaso.Documento AS d ON	d.CodBode COLLATE database_default = a.CodBode 
														AND d.Tipo COLLATE database_default = 'E' 
														AND d.SubTipoDocto COLLATE database_default = a.SubTipoDocto 
														AND d.Folio = a.Folio  --Que no estuvieran traspasados*/
	WHERE a.Estado = 'V'
	  and a.CodBode = '11'
	  and a.CodBod = 'B'
	  AND a.Fecha > '20190930'
	  AND b.CantDespachada > 0 
	  --AND d.CodBode IS NULL -- no traspasado aun
	  and not exists ( select * 
					   from GESTIONVARSO.Traspaso.Documento AS d 
					   where rtrim(d.CodBode) COLLATE database_default = rtrim(a.CodBode)
						 AND rtrim(d.Tipo) COLLATE database_default = 'S' 
						 AND rtrim(d.SubTipoDocto) COLLATE database_default = rtrim(a.SubTipoDocto) 
						 AND d.Folio = a.Folio )
	-- 
	declare @serie char(4) = '',
			@n		char(1) = '',
			@maxnum  varchar(12) = '',
			@proxnum int = 0,
			@registros int = 0;
	--
	SELECT @serie = left([SERIETRASPASOS],3)+'M', @n = N FROM [BDMANVARSO].[dbo].[ALMACEN] where CODALMACEN='12'
	--
	update ktb_paso set NUMSERIE=@serie, Tipo = 'E'
	select @registros = count(*) from ktb_paso;
	--
	insert into GESTIONVARSO.dbo.ktb_procesos ( fechahora, accion, cantidad ) values ( getdate(), 'registros a procesar', @registros );
	select * from ktb_paso

	-- select * from GESTIONVARSO.Traspaso.Documento where tipodoc=22 and codbode='B' and numserie='121M'
	INSERT INTO GESTIONVARSO.Traspaso.Documento
	(	CodBode, Tipo, SubTipoDocto,Folio, RutAux,
		NUMSERIE, NUMALBARANcalculado, NUMALBARAN, N, FACTURADO,
		NUMSERIEFAC, ConNUMFAC, NUMFAC,
		TIPODOC,Tabla,MultiploCantIngresada, MultiploCantDespachada, MultiploCantFacturada	)
	SELECT top 1 * 
	from ktb_paso
	--
	drop table ktb_paso;
	--
	
	--Llevo todos los registros de Traspasados False a NULL, pues los True y False no se procesan
	UPDATE GESTIONVARSO.Traspaso.Documento
	   SET SeTraspasoICG = NULL, errorTraspasoICG = NULL
	 WHERE SeTraspasoICG = 0

	-- tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorAlmacen
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorCliente

	/************* procesando los no traspasados hacia ICG ********************/
	
	--Creo variables para recorrer
	DECLARE @CodBode varchar(10), @Tipo varchar(1), @SubTipoDocto varchar(1), @Folio decimal(18,0), @RutAux varchar(20)
	DECLARE @NUMSERIE nvarchar(4), @NUMALBARAN int, @FACTURADO nvarchar(1),
			@NUMSERIEFAC nvarchar(4), @NUMFAC int,
			@TIPODOC int,  @Tabla varchar(25), @CODCLIENTE int, @CODALMACEN nvarchar(3), 
			@MultiploCantIngresada int, @MultiploCantDespachada int, @MultiploCantFacturada int

    -- esto pudo ser un cursor... pero quizas es mejor asi... kinetik					-- probando solo sucursal agustinas  2019/10/13
	WHILE EXISTS (SELECT TOP 1 * FROM GESTIONVARSO.Traspaso.Documento WHERE SeTraspasoICG IS NULL and TIPODOC = 22 and NUMSERIE = '121M' )
	BEGIN
		--Selecciono
		SELECT TOP 1 
			@CodBode = CodBode,
			@Tipo = Tipo, @SubTipoDocto = SubTipoDocto, @Folio = Folio, @RutAux = RutAux,
			@NUMSERIE = NUMSERIE, @NUMALBARAN = NUMALBARAN, @N = N, @FACTURADO = FACTURADO,
			@NUMSERIEFAC = NUMSERIEFAC, @NUMFAC = NUMFAC,
			@TIPODOC = TIPODOC, @Tabla = Tabla, 
			@MultiploCantIngresada = MultiploCantIngresada, @MultiploCantDespachada = MultiploCantDespachada, @MultiploCantFacturada = MultiploCantFacturada
		FROM GESTIONVARSO.Traspaso.Documento
		WHERE SeTraspasoICG IS NULL
		  and TIPODOC = 22 
		  and NUMSERIE = '121M'

		--Marco como FALSE inicialmente
		UPDATE GESTIONVARSO.Traspaso.Documento
		   SET SeTraspasoICG = 0, FechaUltimoIntento = GETDATE()
		 WHERE CodBode = @CodBode 
           AND Tipo = @Tipo 
           AND SubTipoDocto = @SubTipoDocto 
           AND Folio = @Folio

		---------------------------
		--3.1° Compruebo articulos
		INSERT INTO Traspaso.Documento_ErrorArticulos (	CodBode, Tipo, SubTipoDocto, Folio, CodProd	)
		SELECT DISTINCT	a.CodBode, a.Tipo, a.SubTipoDocto, a.Folio, b.CodProd
		FROM BVARSOVIENNE.softland.iw_gsaen       AS a with (nolock)
		INNER JOIN BVARSOVIENNE.softland.iw_gmovi AS b with (nolock) ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt	
        LEFT  JOIN BDMANVARSO.dbo.ARTICULOSLIN    AS c with (nolock) ON c.CODBARRAS COLLATE database_default = b.CodProd
		WHERE a.CodBode = @CodBode 
          AND a.Tipo = @Tipo 
          AND a.SubTipoDocto = @SubTipoDocto 
          AND a.Folio = @Folio
		  AND c.CODBARRAS IS NULL
		
		--Marco error si corresponde, y salgo del bucle
		--(considerar que ya puse false al estado)
		IF EXISTS( SELECT * 
                   FROM Traspaso.Documento_ErrorArticulos AS a  with (nolock)
                   WHERE a.CodBode = @CodBode 
                     AND a.Tipo = @Tipo 
                     AND a.SubTipoDocto = @SubTipoDocto 
                     AND a.Folio = @Folio)
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.Documento
			   SET errorTraspasoICG = 'Error Falta asignar cód de Articulo ICG'
			 WHERE CodBode = @CodBode 
               AND Tipo = @Tipo 
               AND SubTipoDocto = @SubTipoDocto 
               AND Folio = @Folio
			--SALTO al while....
			CONTINUE
		END	
		-- fin		

		---------------------------
		--3.2° Compruebo Almacen
		IF NOT EXISTS( SELECT * 
					   FROM Traspaso.Rel_Bodega_Almacen  AS a with (nolock)
					   INNER JOIN BDMANVARSO.dbo.ALMACEN AS b with (nolock) ON b.CODALMACEN COLLATE database_default = a.CODALMACENICG
					   WHERE a.CodBodeSoftland = @CodBode ) --O sea, si no encuentra el Almacen
		BEGIN
			INSERT INTO Traspaso.Documento_ErrorAlmacen	(CodBode, Tipo, SubTipoDocto, Folio) VALUES (@CodBode, @Tipo, @SubTipoDocto, @Folio)
		
			--Marco error y salgo del bucle
			UPDATE GESTIONVARSO.Traspaso.Documento
			   SET errorTraspasoICG = ISNULL(errorTraspasoICG, '') + ' -Error Falta asignar Almacen ICG'
			 WHERE CodBode = @CodBode 
               AND tipo = @Tipo 
               AND SubTipoDocto = @SubTipoDocto 
               AND Folio = @Folio
			--SALGO while
			CONTINUE
		END	
		ELSE
		BEGIN
			SELECT TOP 1 @CODALMACEN = b.CODALMACEN
			FROM Traspaso.Rel_Bodega_Almacen  AS a with (nolock)
			INNER JOIN BDMANVARSO.dbo.ALMACEN AS b with (nolock) ON b.CODALMACEN COLLATE database_default = a.CODALMACENICG
			WHERE a.CodBodeSoftland = @CodBode
		END
		-- fin

		---------------------------
		--3.3° Compruebo Cliente
		IF ( @RutAux IS NOT NULL ) BEGIN
			IF NOT EXISTS( SELECT * 
						   FROM BDMANVARSO.dbo.CLIENTES  with (nolock)
						   WHERE NIF20 COLLATE DATABASE_DEFAULT = @RutAux )	BEGIN
				--Tomo nuevo ID
				SELECT @CODCLIENTE = ISNULL(MAX(CODCLIENTE) + 1,0) 
				FROM BDMANVARSO.dbo.CLIENTES with (nolock)

				--INSERTO nuevo cliente
				INSERT INTO BDMANVARSO.DBO.CLIENTES
				(
					CODCLIENTE, CODCONTABLE, NOMBRECLIENTE, NOMBRECOMERCIAL, 
					CIF, DIRECCION1, POBLACION, PROVINCIA, PAIS, 
					TELEFONO1, E_MAIL, CANTPORTESPAG, TIPOPORTES, NUMDIASENTREGA, RIESGOCONCEDIDO, TIPO,
					RECARGO, FACTURARSINIMPUESTOS, DTOCOMERCIAL, FECHAMODIFICADO, 
					REGIMFACT, CODMONEDA, NIF20,
					DESCATALOGADO, LOCAL_REMOTA, CODVISIBLE, CARGOSFIJOSA,
					MOBIL, NOCALCULARCARGO1ARTIC, NOCALCULARCARGO2ARTIC, ESCLIENTEDELGRUPO,
					CARGOSEXTRASA,RECC
				)
				SELECT TOP 1
					@CODCLIENTE, 4300000000 + @CODCLIENTE, a.NomAux, a.NomAux,
					a.RutAux, a.DirAux, b.ComDes AS POBLACION, c.Descripcion AS PROVINCIA, 'CHILE' AS PAIS,
					a.FonAux1 AS TELEFONO1, '', 0, 'D', 0, 0, 0,
					'F', 'F', 0, GETDATE(),
					'G', 1, a.RutAux, 
					'F', 'L', 0, 0,
					'', 0, 0, 0,
					2, 0
				FROM BVARSOVIENNE.softland.cwtauxi         AS a with (nolock)
				LEFT JOIN BVARSOVIENNE.softland.cwtcomu    AS b with (nolock) ON b.ComCod = a.ComAux
				LEFT JOIN BVARSOVIENNE.softland.cwtregion  AS c with (nolock) ON c.id_Region = b.id_Region
				WHERE a.RutAux = @RutAux 
				--
			END
		END
		-- fin
		
		-- se puede traspasar
		--Compruebo Número Albaran
		IF ( @NUMALBARAN IS NULL ) BEGIN
			--
			SELECT @NUMALBARAN = coalesce(MAX(NUMALBARAN) + 1,1) 
			FROM BDMANVARSO.dbo.ALBCOMPRACAB  with (nolock)
			WHERE NUMSERIE = @NUMSERIE
            --
			IF ( @NUMFAC IS NULL ) BEGIN
				SET @NUMFAC = @NUMALBARAN
			END
		END

		--Tomo CodCliente
		IF ( @RutAux IS NULL ) BEGIN 
			SET  @CODCLIENTE = 11042 --Varsovienne en ICG 
		END
		ELSE BEGIN
			SELECT @CODCLIENTE = CODCLIENTE 
			FROM BDMANVARSO.dbo.CLIENTES with (nolock) 
			WHERE NIF20 COLLATE DATABASE_DEFAULT= @RutAux
		END

		BEGIN TRANSACTION
			BEGIN TRY
				--Ahora inserto cabecera
				INSERT INTO BDMANVARSO.dbo.ALBCOMPRACAB
				(
				NUMSERIE, NUMALBARAN, N, FACTURADO, 
				NUMSERIEFAC, NUMFAC, NFAC, ESDEVOLUCION, CODCLIENTE, 
				FECHAALBARAN, HORA, ENVIOPOR, PORTESPAG,
				DTOCOMERCIAL, TOTDTOCOMERCIAL, DTOPP, TOTDTOPP, 
				TOTALBRUTO, TOTALIMPUESTOS, TOTALNETO, 
				SELECCIONADO, SUALBARAN, CODMONEDA, FACTORMONEDA, 
				IVAINCLUIDO, FECHAENTRADA, 
				TIPODOC, TIPODOCFAC, 
 				IDESTADO, FECHAMODIFICADO,
				NBULTOS, TRANSPORTE, 
				TOTALCARGOSDTOS, 
				NORECIBIDO, 
				FECHACREACION, NUMIMPRESIONES)
				SELECT
					@NUMSERIE, @NUMALBARAN, @N, 'F',
					@NUMSERIEFAC, @NUMFAC, @N, 'F', @CODCLIENTE,
					a.Fecha, GETDATE(), '', 'F',
					a.PorcDesc01, a.TotalDesc, 0, 0,
					a.NetoAfecto, a.IVA, a.Total,
					'F', '', 1, 1,
					'T', a.Fecha,
					@TIPODOC, CASE WHEN @NUMFAC = -1 THEN -1 ELSE @TIPODOC END,
					-1, GETDATE(),
					0, 0,
					0,
					'T',
					GETDATE(), 0
				FROM BVARSOVIENNE.softland.iw_gsaen AS a with (nolock)
				WHERE a.CodBode = @CodBode 
					AND a.Tipo = @Tipo 
					AND a.SubTipoDocto = @SubTipoDocto 
					AND a.Folio = @Folio

				-----Ahora inserto el detalle
				INSERT INTO	BDMANVARSO.dbo.ALBCOMPRALIN
				(
					NUMSERIE, NUMALBARAN, N, NUMLIN, 
					CODARTICULO, REFERENCIA, DESCRIPCION, COLOR, 
					TALLA, UNID1, 
					UNID2, UNID3, UNID4, 
					UNIDADESTOTAL, UNIDADESPAGADAS, PRECIO, 
					DTO, TOTAL, 
					TIPOIMPUESTO, IVA, REQ,
					CODALMACEN, LINEAOCULTA, NUMKG,
					SUPEDIDO,
					CODFORMATO, CODMACRO, UDSEXPANSION, EXPANDIDA, 
					TOTALEXPANSION,
					NUMKGEXPANSION, CARGO1, CARGO2, 
					UDSABONADAS, ABONODE_NUMSERIE, ABONODE_NUMALBARAN, 
					ABONODE_N, UDMEDIDA2, UDMEDIDA2EXPANSION, 
					PORCRETENCION,
					TIPORETENCION )
				SELECT
					@NUMSERIE, @NUMALBARAN, @N, b.Linea,
					c.CODARTICULO, d.REFPROVEEDOR, d.DESCRIPCION, '.',
					'.', b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada AS UNID1, 
					1,1,1, 
					b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada, 0, b.PreUniMB,
					b.PorcDescMov01, b.TotLinea, 
					1, 19, 0,
					@CODALMACEN, 'F', 0,
					'.' + @NUMSERIE + '-' + LEFT(CAST(@NUMFAC AS varchar(25)),8),
					0, 0, b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada AS UDSEXPANSION, 'F',
					b.TotLinea,
					0, 0, 0,
					0, '', -1,
					'', 0, 0,
					0,
					0
				FROM BVARSOVIENNE.softland.iw_gsaen       AS a with (nolock)
				INNER JOIN BVARSOVIENNE.softland.iw_gmovi AS b with (nolock) ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
				INNER JOIN BDMANVARSO.dbo.ARTICULOSLIN    AS c with (nolock) ON c.CODBARRAS COLLATE database_default = b.CodProd
				INNER JOIN BDMANVARSO.dbo.ARTICULOS       AS d with (nolock) ON d.CODARTICULO = c.CODARTICULO
				WHERE a.CodBode = @CodBode 
					AND a.Tipo = @Tipo 
					AND a.SubTipoDocto = @SubTipoDocto 
					AND a.Folio = @Folio

				-----Ahora inserto el TOT
				INSERT INTO	BDMANVARSO.dbo.ALBCOMPRATOT
				(
					SERIE, NUMERO, N, NUMLINEA, 
					BRUTO, DTOCOMERC, TOTDTOCOMERC, 
					DTOPP, TOTDTOPP, BASEIMPONIBLE, 
					IVA, TOTIVA, REQ, 
					TOTREQ, TOTAL, ESGASTO, 
					CODDTO, DESCRIPCION )
				SELECT
					@NUMSERIE, @NUMALBARAN, @N, 1,
					a.NetoAfecto, a.PorcDesc01, a.TotalDesc,
					0, 0, a.NetoAfecto,
					19, a.IVA, 0,
					0, a.Total, 'F',
					-1, ''
				FROM
					BVARSOVIENNE.softland.iw_gsaen a
				WHERE a.CodBode = @CodBode 
					AND a.Tipo = @Tipo 
					AND a.SubTipoDocto = @SubTipoDocto 
					AND a.Folio = @Folio 

				-- actualizar stock
				-- select top 100 * from [BDMANVARSO].[dbo].[STOCKS] where CODALMACEN='12' AND CODARTICULO='83' order by FECHAMODIFICADO desc,  CODARTICULO DESC
				update [BDMANVARSO].[dbo].[STOCKS] 
						set STOCKS.STOCK = coalesce( STOCKS.STOCK, 0 ) + ( b.CantIngresada * @MultiploCantIngresada +
																			b.CantDespachada * @MultiploCantDespachada + 
																			b.CantFacturada * @MultiploCantFacturada )
				FROM BVARSOVIENNE.softland.iw_gsaen       AS a with (nolock)
				INNER JOIN BVARSOVIENNE.softland.iw_gmovi AS b with (nolock) ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
				INNER JOIN BDMANVARSO.dbo.ARTICULOSLIN    AS c with (nolock) ON c.CODBARRAS COLLATE database_default = b.CodProd
				INNER JOIN BDMANVARSO.dbo.ARTICULOS       AS d with (nolock) ON d.CODARTICULO = c.CODARTICULO
				where STOCKS.CODALMACEN=@CODALMACEN
					AND STOCKS.CODARTICULO=d.CODARTICULO
					and a.CodBode = @CodBode 
					AND a.Tipo = @Tipo 
					AND a.SubTipoDocto = @SubTipoDocto 
					AND a.Folio = @Folio 
				--
				--Si llega hasta aquí quiere decir que no falló el traspaso
				UPDATE GESTIONVARSO.Traspaso.Documento
				SET NUMALBARAN = @NUMALBARAN,
					SeTraspasoICG = 1,
					errorTraspasoICG = NULL
				WHERE 
					CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio ;
				--
				insert into GESTIONVARSO.dbo.ktb_procesos ( fechahora, accion, cantidad ) values ( getdate(), 'fin del proceso', 0) ;
				--
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION
			END CATCH
		CONTINUE
	END
	--
END
go
