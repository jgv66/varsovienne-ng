
-- primera carga de SP

USE [GESTIONVARSO]
-- =============================================
-- Author:		Daniel Cornejo (dcornejocaro@gmail.com)
-- Create date: 01-10-2016
-- =============================================
ALTER PROCEDURE [Traspaso].[aut00_CargaAutomaticaICG] 
AS
BEGIN

	SET NOCOUNT ON;
	
	--ahora intento traspasar las boletas a softland
	EXEC [Traspaso].[aut01_IntentoTraspasoBoletasSoftland]

	--Ahora intento traspasar el Kardex a ICG (OJO EN ESTA ETAPA SOLO LAS TRANSF INTERBODEGA
	EXEC [Traspaso].[aut02_IntentoTraspasoKardexAICG] 

	--Ahora intento traspasar el Kardex a ICG (OTROS DOCUMENTOS)
	EXEC [Traspaso].[aut03_IntentoTraspasoDocumentoAICG] 
	
	
END ;


ALTER PROCEDURE [Traspaso].[aut01_IntentoTraspasoBoletasSoftland] 
AS
BEGIN
	SET NOCOUNT ON;
	
		BEGIN TRY				
			--Traspaso Boletas (Cabecera y detalle en un sp)
			EXEC [Traspaso].[p_Boletas_TraspasarSoftland]
			
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'Boletas', 'OK'
			)
		END TRY
		BEGIN CATCH
			--Consigno el error en la tabla de resultados
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'Boletas', LEFT(ERROR_MESSAGE(), 500)
			)
		END CATCH
END ;

ALTER PROCEDURE [Traspaso].[p_Boletas_TraspasarSoftland]
AS
BEGIN
	--COLLATE SQL_Latin1_General_CP1_CI_AI
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Deshabilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE VARSO.softland.iw_gsaen DISABLE TRIGGER IW_GSaEnVW_ITRIG

	------------------------------------------------------------
	--0° Antes de Todo, reviso y registro las Boletas Repetidas (Hasta ahora pasa con las Manuales) 21-12-2016 Daniel Cornejo

	--a) Limpio tabla completa
	DELETE FROM Traspaso.BoletasRepetidas

	--b) Inserto las repetidas encontradas, ojo, estas no han sido traspasadas a Softland
	INSERT INTO
		Traspaso.BoletasRepetidas
	(
	NUMSERIEFAC, NUMFAC, NFAC, TOTALNETO, 
	NUMSERIE, NUMALBARAN, N, CODALMACEN, CODVENDEDOR, FolioSoftland, BoletaFiscal
	)
	(
	SELECT
		x.NUMSERIEFAC, x.NUMFAC, x.NFAC, x.TOTALNETO, 
		x.NUMSERIE, x.NUMALBARAN, x.N, x.CODALMACEN, x.CODVENDEDOR, x.FolioSoftland, x.BoletaFiscal
	FROM
		(
			SELECT
				CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END AS NUMSERIEFAC,
				CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS NUMFAC,
				CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END AS NFAC,
				a.TOTALNETO, a.NUMSERIE, a.NUMALBARAN, a.N,
				LEFT(CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END, 2) AS CODALMACEN, 
				a.CODVENDEDOR,
				CAST(LEFT(CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3) + RIGHT('00000000' + CAST(CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS varchar(8)),8) AS Decimal(18,0)) AS FolioSoftland,
				CASE WHEN a.TIPODOC = 13 THEN -1 ELSE 0 END AS BoletaFiscal
			FROM
				BDVARSOVIENNE.dbo.ALBVENTACAB a
				LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES c
					ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
				LEFT OUTER JOIN GESTIONVARSO.Traspaso.Boletas b
					ON b.NUMSERIEFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END collate database_default
						AND b.NUMFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END
						AND b.NFAC = CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END collate database_default
			WHERE
				b.NUMFAC IS NULL --No se halla traspasado
				--AND a.NFAC = 'B' --Antiguo
				AND a.TIPODOC IN (13,18) --13 Boleta Fiscal, 18 Boleta Manual
				--AQUI VOY
				AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END > 0 --Que el folio sea >0
				AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
				AND a.IDESTADO = -1
				AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10
		) x
		INNER JOIN	(
								--Boletas NO traspasadas y Repetidas
					SELECT
						CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END AS NUMSERIEFAC,
						CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS NUMFAC,
						CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END AS NFAC,
						COUNT(*) AS Repetidas
					FROM
						BDVARSOVIENNE.dbo.ALBVENTACAB a
						LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES c
							ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
						LEFT OUTER JOIN GESTIONVARSO.Traspaso.Boletas b
							ON b.NUMSERIEFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END collate database_default
								AND b.NUMFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END
								AND b.NFAC = CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END collate database_default
		
					WHERE
						b.NUMFAC IS NULL --No se halla traspasado
						--AND a.NFAC = 'B' --Antiguo
						AND a.TIPODOC IN (13,18) --13 Boleta Fiscal, 18 Boleta Manual
						--AQUI VOY
						AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END > 0 --Que el folio sea >0
						AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
						AND a.IDESTADO = -1
						AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10
					GROUP BY
						CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,
						CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END,
						CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END
					HAVING 
						COUNT(*) > 1
					) AS y
		ON y.NUMSERIEFAC = x.NUMSERIEFAC AND y.NUMFAC = x.NUMFAC AND y.NFAC = x.NFAC
		)

	--FIN: 0° Antes de Todo, reviso y registro las Boletas Repetidas (Hasta ahora pasa con las Manuales) 21-12-2016 Daniel Cornejo
	---------------------------------------------------------------
	
	------------------------------------------------
	--1° consigno todas las boletas nuevas para ser procesadas
	--21-12-2016 OJO!! Ahora traspasara las boletas que NO  estan repetidas!!
	INSERT INTO
		GESTIONVARSO.Traspaso.Boletas
	(
	NUMSERIEFAC, NUMFAC, NFAC,
	TOTALNETO, NUMSERIE, NUMALBARAN, N,
	CODALMACEN,CODVENDEDOR,
	FolioSoftland, BoletaFiscal
	)
	(
	SELECT
		x.NUMSERIEFAC, x.NUMFAC, x.NFAC,
		x.TOTALNETO, x.NUMSERIE, x.NUMALBARAN, x.N,
		x.CODALMACEN,	x.CODVENDEDOR,
		x.FolioSoftland, x.BoletaFiscal
	FROM
		(
		SELECT
			CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END AS NUMSERIEFAC,
			CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS NUMFAC,
			CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END AS NFAC,
			a.TOTALNETO, a.NUMSERIE, a.NUMALBARAN, a.N,
			LEFT(CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END, 2) AS CODALMACEN, 
			a.CODVENDEDOR,
			CAST(LEFT(CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3) + RIGHT('00000000' + CAST(CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS varchar(8)),8) AS Decimal(18,0)) AS FolioSoftland,
			CASE WHEN a.TIPODOC = 13 THEN -1 ELSE 0 END AS BoletaFiscal
		FROM
			BDVARSOVIENNE.dbo.ALBVENTACAB a
			LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES c
				ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
			LEFT OUTER JOIN GESTIONVARSO.Traspaso.Boletas b
				ON b.NUMSERIEFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END collate database_default
					AND b.NUMFAC = CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END
					AND b.NFAC = CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END collate database_default
		WHERE
			b.NUMFAC IS NULL --No se halla traspasado
			--AND a.NFAC = 'B' --Antiguo
			AND a.TIPODOC IN (13,18) --13 Boleta Fiscal, 18 Boleta Manual
			--AQUI VOY
			AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END > 0 --Que el folio sea >0
			AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
			AND a.IDESTADO = -1
			AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10
			AND ISNUMERIC(LEFT(CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3)) = 1
		) AS x
		LEFT OUTER JOIN Traspaso.BoletasRepetidas y
			ON y.NUMSERIEFAC = x.NUMSERIEFAC COLLATE DATABASE_DEFAULT AND y.NUMFAC = x.NUMFAC AND y.NFAC = x.NFAC COLLATE DATABASE_DEFAULT
	WHERE
		y.NUMSERIEFAC IS NULL --No estén repetidas

	)
	--FIN: 1° consigno todas las boletas nuevas para ser procesadas
	------------------------------------------------
	
	
	------------------------------------------------
	--2° Reinicio para re-procesar
	
	--Llevo todos los registros de Traspasados False a NULL, pues los True y False no se procesan
	UPDATE
		GESTIONVARSO.Traspaso.Boletas
	SET
		SeTraspasoSoftland = NULL,
		errorTraspasoSoftland = NULL
	WHERE
		SeTraspasoSoftland = 0
	
	--LIMPIO tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorBodega
	DELETE FROM GESTIONVARSO.traspaso.Boletas_ErrorVendedor
	
	--FIN: 2° Reinicio para re-procesar
	------------------------------------------------
	
	
	-------------------------------------------------
	--3° Proceso recorriendo cada boleta
	
	--Creo variables para recorrer
	--Vars ICG
	DECLARE @NUMSERIEFAC nvarchar(4), @NUMFAC int, @NFAC char(1), @FolioSoftland decimal(18,0), @CODALMACEN nvarchar(3), @CODVENDEDOR int,
			@BoletaFiscal int
	
	--Vars Softland
	/*
	DECLARE 
			@Folio decimal(18,0), @CentrodeCosto varchar(8),
			@NetoAfecto float, @IVA float, @Total float,
			@IMP_TICK_N float, @IMP_TICK_P float, @PORC_BONIF float,
			@DESC_TALONARIO varchar(100),
			@TotalBrutoADesc float
	*/
	DECLARE @NroInt int --El numero del nuevo registro de la tabla en softland
		
	/*
	--variables para leer el detalle
	DECLARE
		@Linea int, @CodProd varchar(20), @CantFacturada float,
		@PRECIO_PAN float, --valor unit con iva
		@PORC_IVA float
	*/
	
	
	WHILE EXISTS (SELECT * FROM GESTIONVARSO.Traspaso.Boletas WHERE SeTraspasoSoftland = NULL)
	BEGIN
		--Selecciono
		SELECT TOP 1 @NUMSERIEFAC = NUMSERIEFAC, @NUMFAC = NUMFAC, @NFAC = NFAC, @FolioSoftland = FolioSoftland, @CODALMACEN = CODALMACEN, @CODVENDEDOR = CODVENDEDOR, @BoletaFiscal = BoletaFiscal
		FROM GESTIONVARSO.Traspaso.Boletas 
		WHERE SeTraspasoSoftland IS NULL
		--Marco como FALSE inicialmente
		UPDATE GESTIONVARSO.Traspaso.Boletas 
		SET SeTraspasoSoftland = 0, FechaUltimoIntento = GETDATE()
		WHERE @NUMSERIEFAC = NUMSERIEFAC AND @NUMFAC = NUMFAC AND @NFAC = NFAC
	
		---------------------------
		--3.1° Compruebo articulos
		INSERT INTO
			Traspaso.Boletas_ErrorArticulos
		(
		NUMSERIEFAC, NUMFAC, NFAC, CODARTICULO, CODBARRAS
		)
		(
		SELECT DISTINCT
			@NUMSERIEFAC, @NUMFAC, @NFAC, b.CODARTICULO, c.CODBARRAS
		FROM
			BDVARSOVIENNE.dbo.ALBVENTACAB a
			INNER JOIN BDVARSOVIENNE.dbo.ALBVENTALIN b
				ON b.NUMSERIE = a.NUMSERIE AND b.NUMALBARAN = a.NUMALBARAN AND b.N = a.N
			INNER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
				ON c.CODARTICULO = b.CODARTICULO
			LEFT OUTER JOIN VARSO.softland.iw_tprod d
				ON d.CodProd = c.CODBARRAS collate database_default
			LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES e
				ON e.NUMSERIE = a.NUMSERIE AND e.NUMALBARAN = a.NUMALBARAN AND e.N = a.N
		WHERE
			CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END = @NUMSERIEFAC 
			AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE e.NUMERO_BOLETA END = @NUMFAC 
			AND CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END = @NFAC
			AND d.CodProd IS NULL
		)
		
		--Marco error si corresponde, y salgo del bucle
		--(considerar que ya puse false al estado)
		IF EXISTS(SELECT * FROM Traspaso.Boletas_ErrorArticulos a WHERE a.NUMSERIEFAC = @NUMSERIEFAC AND a.NUMFAC = @NUMFAC AND a.NFAC = @NFAC)
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = 'Error Falta asignar cód de Articulo Softland'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.1° Compruebo articulos
		---------------------------
		
		---------------------------
		--3.2° Compruebo CodBodega
		IF NOT EXISTS(
					SELECT 
						* 
					FROM 
						Traspaso.Rel_Bodega_Almacen a
						INNER JOIN VARSO.softland.iw_tbode b
							ON b.CodBode = a.CodBodeSoftland COLLATE DATABASE_DEFAULT
						INNER JOIN VARSO.softland.cwtccos c
							ON c.CodiCC = a.CodiCCSoftland COLLATE DATABASE_DEFAULT
					WHERE
						a.CODALMACENICG =  LEFT(@NUMSERIEFAC, 2)
						) --O sea, si no encuentra bodega y  centro de costo asignado
		BEGIN
			INSERT INTO
				Traspaso.Boletas_ErrorBodega
			(
			NUMSERIEFAC, NUMFAC, NFAC, CODALMACEN
			)
			VALUES
			(
			@NUMSERIEFAC, @NUMFAC, @NFAC, LEFT(@NUMSERIEFAC, 2)
			)
		
			--Marco error y salgo del bucle
			--(considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error Falta asignar Bodega y Centro Costo'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
			
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.2° Compruebo CodBodega
		---------------------------
		
		---------------------------
		--3.21° Compruebo CODVENDEDOR
		IF NOT EXISTS(
					SELECT 
						* 
					FROM 
						Traspaso.Rel_Vendedor a
						INNER JOIN VARSO.softland.cwtvend b
							ON b.VenCod = a.VenCodSoftland COLLATE DATABASE_DEFAULT
					WHERE
						a.CODVENDEDOR =  @CODVENDEDOR
						) --O sea, si no encuentra VENDEDOR
		BEGIN
			INSERT INTO
				Traspaso.Boletas_ErrorVendedor
			(
			NUMSERIEFAC, NUMFAC, NFAC, CODVENDEDOR
			)
			VALUES
			(
			@NUMSERIEFAC, @NUMFAC, @NFAC, @CODVENDEDOR
			)
		
			--Marco error y salgo del bucle
			--(considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error CodVendedor'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
			
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.21° Compruebo CODVENDEDOR
		---------------------------
		
		---------------------------
		--3.3° Compruebo Folio existente en Softland
		IF EXISTS (
					SELECT 
						* 
					FROM 
						VARSO.softland.iw_gsaen a
						INNER JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen b
							ON b.CodBodeSoftland collate database_default = a.CodBode
					WHERE
						Tipo = 'B' AND Folio = @FolioSoftland
						AND b.CODALMACENICG = @CODALMACEN
					)
		BEGIN
		
			--Marco error y salgo del bucle
			--(considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error BOLETA YA EXISTE SOFTLAND'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
			
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.3° Compruebo Folio existente en Softland
		---------------------------
	
		----------------------------
		--3.4° Traspaso a Softland
		--Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el traspaso.
		
		--Obtengo el nuevo NroInt de Softland
		SELECT @NroInt = ISNULL(MAX(NroInt) + 1,1) 
		FROM VARSO.softland.iw_gsaen
		WHERE Tipo = 'B'
		
		--Inserto cabecera
		--Ahora inserto en cabecera
		INSERT INTO
			VARSO.softland.iw_gsaen
		(
			Tipo, NroInt, CodBode, Folio,
			Concepto,
			Estado, Fecha,
			Glosa,
			Orden, Factura, AuxTipo, AuxGuiaNum, CodVendedor, CodMoneda,
			Equivalencia, usuario,
			NetoAfecto, NetoExento, IVA, PorcDesc01, Descto01,
			PorcDesc02, Descto02, PorcDesc03, Descto03, PorcDesc04, Descto04,
			PorcDesc05, Descto05,
			TotalDesc, Flete, Embalaje, Total, StockActualizado,
			EnMantencion, CentrodeCosto, Subtotal,
			ContabVenta, ContabCosto, ContDespPend, ContConsumo, ContVtaComp,
			Sistema, Proceso,
			nvnumero, ContabPago, NumGuiaTrasp, FueExportado,
			esDevolucion,
			SubTipoDocto,
			MarcaWG,
			FecHoraCreacion, ListaMayorista, BoletaFiscal, ImpresaOK,
			ContabenPW, DescLisPreenMov, MotivoNCND, CorrelativoAprobacion,
			DTE_SiiTDoc, ContabenCW, FactorCostoImportacion, TipoDespacho,
			TotalDescBoleta, TipoServicioSII,
			PorcCredEmpConst, DescCredEmpConst,
			TipDocRef
		)
		(
			SELECT
				'B', @NroInt, b.CodBodeSoftland, @FolioSoftland,
				'02',
				'V', a.FECHA,
				'AutICG-' + LEFT(ISNULL(b.DesBode,''),15),
				0, 0, 'A', 0, d.VenCodSoftland COLLATE DATABASE_DEFAULT, '01',
				0, 'softland',
				a.TOTALBRUTO, 0, a.TOTALIMPUESTOS, 0, 0,
				0, 0, 0, 0, 0, 0,
				0, 0,
				0, 0, 0,  a.TOTALNETO, 0,
				0, b.CodiCCSoftland, a.TOTALNETO,
				0, 0, 0, 0, 0,
				'IW', 'CAPTURA DE DOCUMENTOS DE VENTA',
				0, 0, 0, 0,
				0,
				'A',
				0,
				a.FECHACREACION, 0, @BoletaFiscal, 0,
				0, 0, 0, 0,
				0, 0, 1, 0,
				0, 3,
				0, 0,
				'B'
			FROM
				BDVARSOVIENNE.dbo.ALBVENTACAB a
				INNER JOIN Traspaso.Rel_Bodega_Almacen b
					ON b.CODALMACENICG = LEFT(@NUMSERIEFAC, 2)
				LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES c
					ON c.NUMSERIE = a.NUMSERIE AND c.NUMALBARAN = a.NUMALBARAN AND c.N = a.N
				LEFT OUTER JOIN GESTIONVARSO.Traspaso.Rel_Vendedor d
					ON d.CODVENDEDOR = a.CODVENDEDOR
			WHERE
				CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END = @NUMSERIEFAC 
				AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE c.NUMERO_BOLETA END = @NUMFAC 
				AND CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END = @NFAC
		)

		--Ahora inserto el detalle
		INSERT INTO
			VARSO.softland.iw_gmovi
		(
			----
			Tipo, NroInt, Linea, CodProd, CodBode,
			Fecha, CantIngresada, CantDespachada, CantFacturada,
			PreUniMB,
			PreUniMVta,
			PreUniMOrig,
			----
			
			PorcDescMov01,
			DescMov01,
			PorcDescMov02, DescMov02,
			
			PorcDescMov03, DescMov03, PorcDescMov04, DescMov04,
			PorcDescMov05, DescMov05,
			TotalDescMov,
			Equivalencia, Actualizado,
			TotLinea,
			
			nvCorrela,
			TipoOrigen, TipoDestino, AuxTipo, CodAux, CodiCC, Orden,
			ocCorrela, MarcaWG, ImpresaOk, CodUMed, CantFactUVta,
			CantDespUVta, NumTrab, Recargo, TotalDescMovBoleta,
			PreUniBoleta, TotalBoleta,
			DetProd
		)
		(
		SELECT 
			'B', @NroInt, b.NUMLIN, c.CODBARRAS, e.CodBodeSoftland,
			a.FECHA, 0, b.UNID1, b.UNID1, 
			b.PRECIO,
			0,
			0,
			----
			
			b.DTO,
			
			b.UNID1 * b.PRECIO * (b.DTO / 100), --b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
			0, 0,
			
			0, 0, 0, 0,
			0, 0,
			b.UNID1 * b.PRECIO * (b.DTO / 100), --b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
			1, -1,
			--Total Linea
			b.UNID1 * b.PRECIO * ((100-b.DTO) / 100),
			
			0,
			'D', 'N', 'A', '', '', 0,
			0, 0, 0, d.CodUMed, b.UNID1,
			b.UNID1, 0, 0, b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
			b.PRECIOIVA, b.UNID1 * b.PRECIO * ((100-b.DTO) / 100)* ((100+b.IVA)/100),
			b.DESCRIPCION
		FROM
			BDVARSOVIENNE.dbo.ALBVENTACAB a
			INNER JOIN BDVARSOVIENNE.dbo.ALBVENTALIN b
				ON b.NUMSERIE = a.NUMSERIE AND b.NUMALBARAN = a.NUMALBARAN AND b.N = a.N
			INNER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
				ON c.CODARTICULO = b.CODARTICULO
			LEFT OUTER JOIN VARSO.softland.iw_tprod d
				ON d.CodProd = c.CODBARRAS collate database_default
			LEFT OUTER JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen e
				ON e.CODALMACENICG = LEFT(@NUMSERIEFAC, 2)
			LEFT OUTER JOIN BDVARSOVIENNE.dbo.ALBVENTACAMPOSLIBRES f
				ON f.NUMSERIE = a.NUMSERIE AND f.NUMALBARAN = a.NUMALBARAN AND f.N = a.N
		WHERE
			CASE WHEN a.TIPODOC = 13 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END = @NUMSERIEFAC 
			AND CASE WHEN a.TIPODOC = 13 THEN a.NUMFAC ELSE f.NUMERO_BOLETA END = @NUMFAC 
			AND CASE WHEN a.TIPODOC = 13 THEN a.NFAC ELSE a.N END = @NFAC
		)
		
		--Si llega hasta aquí quiere decir que no falló el traspaso
		UPDATE GESTIONVARSO.Traspaso.Boletas 
		SET SeTraspasoSoftland = 1,
			errorTraspasoSoftland = NULL
		WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
		
		--FIN:3.4° Traspaso a Softland
		----------------------------
		
		--	
		CONTINUE
	END
	
	--FIN: 3° Proceso recorriendo cada boleta
	-------------------------------------------------
	
	--Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE VARSO.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG
	
END ;

-- =============================================
-- Author:		Daniel Cornejo (dcornejocaro@gmail.com)
-- Create date: 05-10-2016
-- Description:	
-- =============================================
ALTER PROCEDURE [Traspaso].[aut02_IntentoTraspasoKardexAICG] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
		BEGIN TRY				
			--Traspaso Kardex (Cabecera y detalle en un sp)
			EXEC [Traspaso].[p_Kardex_TraspasarAICG]
			
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'KardexAICG', 'OK'
			)
		END TRY
		BEGIN CATCH
			--Consigno el error en la tabla de resultados
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'KardexAICG', LEFT(ERROR_MESSAGE(), 500)
			)
		END CATCH
END ;

ALTER PROCEDURE [Traspaso].[p_Kardex_TraspasarAICG]
AS
BEGIN
	--COLLATE SQL_Latin1_General_CP1_CI_AI
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	------------------------------------------------
	--1° consigno todos los documentos nuevos para ser procesados
	INSERT INTO
		GESTIONVARSO.Traspaso.KardexAICG_Docs
	(
	CodBode, Tipo, SubTipoDocto,
	Folio, TipoOrigen, TipoDestino
	)
	(
	SELECT DISTINCT
		a.CodBode, a.Tipo, a.SubTipoDocto,
		a.Folio, b.TipoOrigen, b.TipoDestino
	FROM
		VARSO.softland.iw_gsaen a
		INNER JOIN VARSO.softland.iw_gmovi b
			ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
		INNER JOIN GESTIONVARSO.Traspaso.KardexAICG_Traspasables c
			ON c.Tipo COLLATE database_default = a.Tipo AND c.Concepto COLLATE database_default = a.Concepto AND c.TipoOrigen COLLATE database_default = b.TipoOrigen AND c.TipoDestino COLLATE database_default = b.TipoDestino
		--Que no estuvieran traspasados
		LEFT OUTER JOIN GESTIONVARSO.Traspaso.KardexAICG_Docs d
			ON d.CodBode COLLATE database_default = a.CodBode AND d.Tipo COLLATE database_default = a.Tipo AND d.SubTipoDocto COLLATE database_default = a.SubTipoDocto AND d.Folio = a.Folio
		--Que no sea un traspaso automático desde ICG
		LEFT OUTER JOIN GESTIONVARSO.Traspaso.KardexASOFTLAND_Docs e
			ON e.CodBode COLLATE database_default = a.CodBode AND e.Tipo COLLATE database_default = a.Tipo AND e.SubTipoDocto COLLATE database_default = a.SubTipoDocto AND e.Folio = a.Folio
	WHERE
		a.Estado = 'V'
		AND YEAR(a.Fecha) >= 2017
		AND d.CodBode IS NULL --Que no estuvieran traspasados
		AND e.CodBode IS NULL --Que no sea un traspaso automático desde ICG
	)
	--FIN: 1° consigno todos los documentos nuevos para ser procesados
	------------------------------------------------
	
	------------------------------------------------
	--2° Reinicio para re-procesar
	
	--Llevo todos los registros de Traspasados False a NULL, pues los True y False no se procesan
	UPDATE
		GESTIONVARSO.Traspaso.KardexAICG_Docs
	SET
		SeTraspasoICG = NULL,
		errorTraspasoICG = NULL
	WHERE
		SeTraspasoICG = 0
	
	--LIMPIO tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.KardexAICG_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.KardexAICG_ErrorAlmacen
	
	--FIN: 2° Reinicio para re-procesar
	------------------------------------------------
	
	-------------------------------------------------
	--3° Proceso recorriendo cada Documento
	
	--Creo variables para recorrer
	DECLARE @CodBode varchar(10), @Tipo varchar(1), @SubTipoDocto varchar(1), @Folio decimal(18,0)

	--
	DECLARE @SERIE nvarchar(4), @NUMERO int, @CAJA nvarchar(3), @CODALMACEN varchar(3),
		@CODALMACENORIGEN varchar(3), @CODALMACENDESTINO varchar(3)

	WHILE EXISTS (SELECT TOP 1 * FROM GESTIONVARSO.Traspaso.KardexAICG_Docs WHERE SeTraspasoICG IS NULL)
	BEGIN
		--Selecciono
		SELECT TOP 1 @CodBode = CodBode, @Tipo = Tipo, @SubTipoDocto = SubTipoDocto, @Folio = Folio
		FROM GESTIONVARSO.Traspaso.KardexAICG_Docs
		WHERE SeTraspasoICG IS NULL

		--Marco como FALSE inicialmente
		UPDATE GESTIONVARSO.Traspaso.KardexAICG_Docs
		SET SeTraspasoICG = 0, FechaUltimoIntento = GETDATE()
		WHERE CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
	
		---------------------------
		--3.1° Compruebo articulos
		INSERT INTO
			Traspaso.KardexAICG_ErrorArticulos
		(
		CodBode, Tipo, SubTipoDocto, Folio, CodProd
		)
		(
		SELECT DISTINCT
			a.CodBode, a.Tipo, a.SubTipoDocto, a.Folio, b.CodProd
		FROM
			VARSO.softland.iw_gsaen a
			INNER JOIN VARSO.softland.iw_gmovi b
				ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
			LEFT OUTER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
				ON c.CODBARRAS COLLATE database_default = b.CodProd
		WHERE
			a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			AND c.CODBARRAS IS NULL
		)
		
		--Marco error si corresponde, y salgo del bucle
		--(considerar que ya puse false al estado)
		IF EXISTS(SELECT * FROM Traspaso.KardexAICG_ErrorArticulos a WHERE a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio)
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.KardexAICG_Docs
			SET errorTraspasoICG = 'Error Falta asignar cód de Articulo ICG'
			WHERE CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.1° Compruebo articulos
		---------------------------
		
		---------------------------
		--3.2° Compruebo Almacen
		IF NOT EXISTS(
					SELECT 
						* 
					FROM 
						Traspaso.Rel_Bodega_Almacen a
						INNER JOIN BDVARSOVIENNE.dbo.ALMACEN b
							ON b.CODALMACEN COLLATE database_default = a.CODALMACENICG
					WHERE
						a.CodBodeSoftland = @CodBode
						) --O sea, si no encuentra el Almacen
		BEGIN
			INSERT INTO
				Traspaso.KardexAICG_ErrorAlmacen
			(
			CodBode, Tipo, SubTipoDocto, Folio
			)
			VALUES
			(
			@CodBode, @Tipo, @SubTipoDocto, @Folio
			)
		
			--Marco error y salgo del bucle
			--(considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.KardexAICG_Docs
			SET errorTraspasoICG = ISNULL(errorTraspasoICG, '') + ' -Error Falta asignar Almacen'
			WHERE CodBode = @CodBode AND tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
			
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	

		--FIN: 3.2° Compruebo Almacen
		---------------------------
		
		----------------------------
		--3.4° Traspaso a ICG
		--Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el traspaso.
		
		--a° Primero creo la Cabecera
		--Tomo el numero de Serie
		SELECT @SERIE = a.SERIETRASPASOS, @CODALMACEN = a.CODALMACEN
		FROM
			BDVARSOVIENNE.dbo.ALMACEN a
			INNER JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen b
				ON b.CODALMACENICG COLLATE database_default = a.CODALMACEN
		WHERE
			b.CodBodeSoftland = @CodBode
		
		--Caja
		SET @CAJA = ''

		--Tomo Numero
		SELECT
			@NUMERO = ISNULL(MAX(NUMERO) + 1,1) 
		FROM BDVARSOVIENNE.dbo.TRASPASOSCAB
		WHERE SERIE = @SERIE AND CAJA = @CAJA

		--Veo Origen y Destino
		IF @Tipo = 'E'
		BEGIN
			SET @CODALMACENORIGEN = '96' --Procesos
			SET @CODALMACENDESTINO = @CODALMACEN
		END
		ELSE
		BEGIN
			SET @CODALMACENORIGEN = @CODALMACEN
			SET @CODALMACENDESTINO = '96' --Procesos
		END


		--OJO: Puede pasar que serie esté en NULL EN ICG
		IF(@SERIE IS NULL)
		BEGIN
			
			UPDATE GESTIONVARSO.Traspaso.KardexAICG_Docs
			SET errorTraspasoICG = ISNULL(errorTraspasoICG, '') + ' -Error Falta asignar SERIE al Almacen en ICG'
			WHERE CodBode = @CodBode AND tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio

			-- corto el bucle aqui
			CONTINUE

		END

		--Inserto
		INSERT INTO
			BDVARSOVIENNE.dbo.TRASPASOSCAB
		(
		SERIE, CAJA, NUMERO,
		FECHA, CODALMACENORIGEN, CODALMACENDESTINO,
		CONTABILIZADO, TOTAL, ANULADO, NUMEROANULADO, 
		RECIBIDO, FECHARECIBIDO,
		IDENTIFICADOR, RECIBIDOPORCODVENDEDOR, DESCARGADO,
		OBSERVACIONES,
		TOTALDMN, ESAUTOMATICO, ESRECUENTO, ESAJUSTE,
		IDCONCEPTOAJUSTE, ESCONTABILIZABLE,
		FECHACREACION, FECHATRANSPORTE,
		MODIFICABLE, IDMOTIVO, DESCMOTIVO, ESTRANSPORTE
		)
		(
		SELECT
			@SERIE, @CAJA, @NUMERO,
			a.Fecha, @CODALMACENORIGEN, @CODALMACENDESTINO,
			'F', 0, 'F', 0,
			'T', a.Fecha,
			'', -1, 'F',
			'AutICG- Traspaso Softland',
			0, 'F', 'F', 'F',
			-1, 'T',
			GETDATE(), a.Fecha,
			'F', -1, '', 'F'
		FROM
			VARSO.softland.iw_gsaen a
		WHERE
			a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
		)

		-----Ahora inserto el detalle
		INSERT INTO
			BDVARSOVIENNE.dbo.MOVIMENTS
		(
		CODALMACENORIGEN, CODALMACENDESTINO, CODARTICULO,
		TALLA, COLOR, PRECIO,
		FECHA, HORA, 
		TIPO, UNIDADES,
		SERIEDOC, NUMDOC, CAJA,
		STOCK, PVP, CODMONEDAPVP,
		CALCMOVPOST, UDMEDIDA2, PVPDMN,
		PRECIODMN, STOCK2
		)
		(
		SELECT
			@CODALMACENORIGEN, @CODALMACENDESTINO, c.CODARTICULO,
			'.', '.', 0,
			a.Fecha, GETDATE(),
			'ENV', b.CantIngresada + b.CantDespachada,
			@SERIE, @NUMERO, @CAJA,
			0, 0, 1,
			'F', 0, 0,
			0, 0
		FROM
			VARSO.softland.iw_gsaen a
			INNER JOIN VARSO.softland.iw_gmovi b
				ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
			INNER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
				ON c.CODBARRAS COLLATE database_default = b.CodProd
		WHERE
			a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
		)

		--Si llega hasta aquí quiere decir que no falló el traspaso
		UPDATE GESTIONVARSO.Traspaso.KardexAICG_Docs
		SET 
			SERIE = @SERIE, NUMERO = @NUMERO, CAJA = @CAJA,
			SeTraspasoICG = 1,
			errorTraspasoICG = NULL
		WHERE 
			CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio

		--FIN:3.4° Traspaso a ICG
		----------------------------

		--	
		CONTINUE
	END
	
	--FIN: 3° Proceso recorriendo cada Documento
	-------------------------------------------------
END;

ALTER PROCEDURE [Traspaso].[aut03_IntentoTraspasoDocumentoAICG] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
		BEGIN TRY				
			--Traspaso Kardex (Cabecera y detalle en un sp)
			EXEC [Traspaso].[p_Documento_TraspasarAICG]
			
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'DocumentoAICG', 'OK'
			)
		END TRY
		BEGIN CATCH
			--Consigno el error en la tabla de resultados
			--Marco como Correcto en la tabla de resultados
			INSERT INTO
				GESTIONVARSO.Traspaso.LogTraspasos
			(
			TipoTraspaso, Observacion
			)
			VALUES
			(
			'DocumentoAICG', LEFT(ERROR_MESSAGE(), 500)
			)
		END CATCH
END;

ALTER PROCEDURE [Traspaso].[p_Documento_TraspasarAICG]
AS
BEGIN
	--COLLATE SQL_Latin1_General_CP1_CI_AI
	SET NOCOUNT ON;
	
	------------------------------------------------
	--1° consigno todos los documentos nuevos para ser procesados
	INSERT INTO
		GESTIONVARSO.Traspaso.Documento
	(
	CodBode, Tipo, SubTipoDocto,
	Folio, RutAux,
	NUMSERIE, NUMALBARANcalculado, NUMALBARAN, N, FACTURADO,
	NUMSERIEFAC, ConNUMFAC, NUMFAC,
	TIPODOC,
	Tabla,
	MultiploCantIngresada, MultiploCantDespachada, MultiploCantFacturada
	)
	(
	SELECT DISTINCT
		a.CodBode, a.Tipo, a.SubTipoDocto,
		a.Folio, e.RutAux,
		c.NUMSERIE, c.NUMALBARANcalculado, CASE WHEN c.NUMALBARANcalculado = 0 THEN a.Folio ELSE NULL END, c.N, c.FACTURADO,
		c.NUMSERIEFAC, c.ConNUMFAC, CASE WHEN c.ConNUMFAC = 1 THEN CASE WHEN c.NUMALBARANcalculado = 0 THEN a.Folio ELSE NULL END ELSE -1 END AS NUMFAC,
		c.TIPODOC,
		c.Tabla, 
		c.MultiploCantIngresada, c.MultiploCantDespachada, c.MultiploCantFacturada
	FROM
		VARSO.softland.iw_gsaen a
		INNER JOIN VARSO.softland.iw_gmovi b
			ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
		INNER JOIN GESTIONVARSO.Traspaso.Documento_Traspasables c
			ON c.Tipo COLLATE database_default = a.Tipo AND c.Concepto COLLATE database_default = a.Concepto
		--Que no estuvieran traspasados
		LEFT OUTER JOIN GESTIONVARSO.Traspaso.Documento d
			ON d.CodBode COLLATE database_default = a.CodBode AND d.Tipo COLLATE database_default = a.Tipo AND d.SubTipoDocto COLLATE database_default = a.SubTipoDocto AND d.Folio = a.Folio
		LEFT OUTER JOIN VARSO.softland.cwtauxi e
			ON e.CodAux = a.CodAux
	WHERE
		c.Activo = 1
		AND a.Estado = 'V'
		AND a.Fecha >= '01-10-2017'
		AND (b.CantDespachada > 0 OR b.CantIngresada > 0 OR b.CantFacturada <> 0)
		AND d.CodBode IS NULL --Que no estuvieran traspasados
	)
	--FIN: 1° consigno todos los documentos nuevos para ser procesados
	------------------------------------------------
	
	
	------------------------------------------------
	--2° Reinicio para re-procesar
	
	--Llevo todos los registros de Traspasados False a NULL, pues los True y False no se procesan
	UPDATE
		GESTIONVARSO.Traspaso.Documento
	SET
		SeTraspasoICG = NULL,
		errorTraspasoICG = NULL
	WHERE
		SeTraspasoICG = 0

	/*
	UPDATE GESTIONVARSO.Traspaso.Documento
	SET SeTraspasoICG = 0, ErrorTraspasoICG = 'CONTROL3'
	WHERE
		SeTraspasoICG = NULL
		AND Tipo <> 'N'

	UPDATE GESTIONVARSO.Traspaso.Documento
	SET SeTraspasoICG = 0, ErrorTraspasoICG = 'CONTROL3'
	WHERE
		SeTraspasoICG = NULL
		AND Tipo = 'N'
		AND Folio <> 7798
	*/
	
	--LIMPIO tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorAlmacen
	DELETE FROM GESTIONVARSO.Traspaso.Documento_ErrorCliente
	
	--FIN: 2° Reinicio para re-procesar
	------------------------------------------------

	-------------------------------------------------
	--3° Proceso recorriendo cada Documento
	
	--Creo variables para recorrer
	DECLARE @CodBode varchar(10), @Tipo varchar(1), @SubTipoDocto varchar(1), @Folio decimal(18,0), @RutAux varchar(20)

	--
	DECLARE @NUMSERIE nvarchar(4), @NUMALBARAN int, @N char(1), @FACTURADO nvarchar(1),
			@NUMSERIEFAC nvarchar(4), @NUMFAC int,
			@TIPODOC int,  @Tabla varchar(25), @CODCLIENTE int, @CODALMACEN nvarchar(3), 
			@MultiploCantIngresada int, @MultiploCantDespachada int, @MultiploCantFacturada int

	WHILE EXISTS (SELECT TOP 1 * FROM GESTIONVARSO.Traspaso.Documento WHERE SeTraspasoICG IS NULL)
	BEGIN
		--Selecciono
		SELECT TOP 1 
			@CodBode = CodBode, @Tipo = Tipo, @SubTipoDocto = SubTipoDocto, @Folio = Folio, @RutAux = RutAux,
			@NUMSERIE = NUMSERIE, @NUMALBARAN = NUMALBARAN, @N = N, @FACTURADO = FACTURADO,
			@NUMSERIEFAC = NUMSERIEFAC, @NUMFAC = NUMFAC,
			@TIPODOC = TIPODOC, @Tabla = Tabla, 
			@MultiploCantIngresada = MultiploCantIngresada, @MultiploCantDespachada = MultiploCantDespachada, @MultiploCantFacturada = MultiploCantFacturada
		FROM GESTIONVARSO.Traspaso.Documento
		WHERE SeTraspasoICG IS NULL

		--Marco como FALSE inicialmente
		UPDATE GESTIONVARSO.Traspaso.Documento
		SET SeTraspasoICG = 0, FechaUltimoIntento = GETDATE()
		WHERE CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
	
		---------------------------
		--3.1° Compruebo articulos
		INSERT INTO
			Traspaso.Documento_ErrorArticulos
		(
		CodBode, Tipo, SubTipoDocto, Folio, CodProd
		)
		(
		SELECT DISTINCT
			a.CodBode, a.Tipo, a.SubTipoDocto, a.Folio, b.CodProd
		FROM
			VARSO.softland.iw_gsaen a
			INNER JOIN VARSO.softland.iw_gmovi b
				ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
			LEFT OUTER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
				ON c.CODBARRAS COLLATE database_default = b.CodProd
		WHERE
			a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			AND c.CODBARRAS IS NULL
		)
		
		--Marco error si corresponde, y salgo del bucle
		--(considerar que ya puse false al estado)
		IF EXISTS(SELECT * FROM Traspaso.Documento_ErrorArticulos a WHERE a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio)
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.Documento
			SET errorTraspasoICG = 'Error Falta asignar cód de Articulo ICG'
			WHERE CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		
		--FIN: 3.1° Compruebo articulos
		---------------------------
		
		---------------------------
		--3.2° Compruebo Almacen
		IF NOT EXISTS(
					SELECT 
						* 
					FROM 
						Traspaso.Rel_Bodega_Almacen a
						INNER JOIN BDVARSOVIENNE.dbo.ALMACEN b
							ON b.CODALMACEN COLLATE database_default = a.CODALMACENICG
					WHERE
						a.CodBodeSoftland = @CodBode
						) --O sea, si no encuentra el Almacen
		BEGIN
			INSERT INTO
				Traspaso.Documento_ErrorAlmacen
			(
			CodBode, Tipo, SubTipoDocto, Folio
			)
			VALUES
			(
			@CodBode, @Tipo, @SubTipoDocto, @Folio
			)
		
			--Marco error y salgo del bucle
			--(considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Documento
			SET errorTraspasoICG = ISNULL(errorTraspasoICG, '') + ' -Error Falta asignar Almacen'
			WHERE CodBode = @CodBode AND tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio
			
			--SALGO DEL BUCLE ANTES
			CONTINUE
		END	
		ELSE
		BEGIN
			SELECT TOP 1 @CODALMACEN = b.CODALMACEN
					
					FROM 
						Traspaso.Rel_Bodega_Almacen a
						INNER JOIN BDVARSOVIENNE.dbo.ALMACEN b
							ON b.CODALMACEN COLLATE database_default = a.CODALMACENICG
					WHERE
						a.CodBodeSoftland = @CodBode
		END

		--FIN: 3.2° Compruebo Almacen
		---------------------------


		---------------------------
		--3.3° Compruebo Cliente
		IF @RutAux IS NOT NULL
		BEGIN
			IF NOT EXISTS(
						SELECT 
							* 
						FROM 
							BDVARSOVIENNE.dbo.CLIENTES 
						WHERE
							NIF20 COLLATE DATABASE_DEFAULT = @RutAux
							) --O sea, si no encuentra el Cliente
			BEGIN
				--Tomo nuevo ID
				SELECT @CODCLIENTE = ISNULL(MAX(CODCLIENTE) + 1,0) FROM BDVARSOVIENNE.dbo.CLIENTES

				--INSERTO nuevo cliente
				INSERT INTO
					BDVARSOVIENNE.DBO.CLIENTES
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
				(
				SELECT TOP 1
					@CODCLIENTE, 4300000000 + @CODCLIENTE, a.NomAux, a.NomAux,
					a.RutAux, a.DirAux, b.ComDes AS POBLACION, c.Descripcion AS PROVINCIA, 'CHILE' AS PAIS,
					a.FonAux1 AS TELEFONO1, '', 0, 'D', 0, 0, 0,
					'F', 'F', 0, GETDATE(),
					'G', 1, a.RutAux, 
					'F', 'L', 0, 0,
					'', 0, 0, 0,
					2, 0
				FROM
				 VARSO.softland.cwtauxi a
				 LEFT OUTER JOIN varso.softland.cwtcomu b
					ON b.ComCod = a.ComAux
				LEFT OUTER JOIN VARSO.softland.cwtregion c
					ON c.id_Region = b.id_Region
				WHERE
					a.RutAux = @RutAux
				)
			END
		END

		--FIN: 3.3° Compruebo Cliente
		---------------------------
	
		----------------------------
		--3.4° Traspaso a ICG
		--Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el traspaso.
		
		--a° Primero creo la Cabecera
		IF @Tabla = 'ALBVENTACAB'
		BEGIN
			--Compruebo Número Albaran
			IF @NUMALBARAN IS NULL
			BEGIN
				SELECT
					@NUMALBARAN = ISNULL(MAX(NUMALBARAN) + 1,1) 
				FROM BDVARSOVIENNE.dbo.ALBVENTACAB
				WHERE NUMSERIE = @NUMSERIE

				IF @NUMFAC IS NULL
				BEGIN
					SET @NUMFAC = @NUMALBARAN
				END
			END

			--Tomo CodCliente
			IF @RutAux IS NULL 
			BEGIN 
				SET  @CODCLIENTE = 11042 --Varsovienne en ICG 
			END
			ELSE
			BEGIN
				SELECT @CODCLIENTE = CODCLIENTE FROM BDVARSOVIENNE.dbo.CLIENTES WHERE NIF20 COLLATE DATABASE_DEFAULT= @RutAux
			END

			--Ahora inserto cabecera
			INSERT INTO
				BDVARSOVIENNE.dbo.ALBVENTACAB
			(
			NUMSERIE, NUMALBARAN, N, FACTURADO, 
			NUMSERIEFAC, NUMFAC, NFAC, TIQUET, 
			ESUNPRESTAMO, ESDEVOLUCION, CODCLIENTE, CODVENDEDOR, 
            FECHA, HORA, ENVIOPOR, PORTESPAG,
			DTOCOMERCIAL, TOTDTOCOMERCIAL, DTOPP, TOTDTOPP, 
			TOTALBRUTO, TOTALIMPUESTOS, TOTALNETO, TOTALCOSTE, 
            SELECCIONADO, SUALBARAN, CODMONEDA, FACTORMONEDA, 
			IVAINCLUIDO, CODTARIFA, VIENEDEFO, FECHAENTRADA, 
			PORC, TOTPORC, TIPODOC, TIPODOCFAC, 
            SALA, MESA, HORAFIN, NUMCOMENSALES, 
			IMPRESIONES, FO, SERIE, Z, 
			IDESTADO, FECHAMODIFICADO, AUTOMATICO, CAJA, 
			TOTALCOSTEIVA, ESBARRA, NBULTOS, TRANSPORTE, 
			CODENVIO, PUNTOSACUM, IDTARJETA, TOTALCARGOSDTOS, 
			SERIEASUNTO, NUMEROASUNTO, NUMROLLO, NORECIBIDO, 
            PUNTOSCANJEADOS, TOTALPUNTOS, ENTRANSITO, TRASPASADO, 
			ENLACE_EMPRESA, ENLACE_EJERCICIO, ENLACE_ASIENTO, ENLACE_USUARIO, 
            FECHATRASPASO, TOTALCOSTE2, TOTALCOSTEIVA2, FECHARECEPCION, 
			DESCARGAR, FECHACREACION, IDMOTIVODTO, NUMIMPRESIONES, 
			HORATOTAL, HORACOCINA, FECHAINI, FECHAFIN, 
			ESTADODELIVERY, HORAELABORADO, HORAASIGNADO, HORAENTREGADO, 
			PUNTOSCANJEOPORDTOCOM, DTOCOMANTESCANJEOPUNTOS
			)
			(
			SELECT
				@NUMSERIE, @NUMALBARAN, @N, @FACTURADO,
				@NUMSERIEFAC, @NUMFAC, @N, 'F',
				'F', CASE WHEN RIGHT(@NUMSERIE, 1) = 'N' THEN 'T' ELSE 'F' END, @CODCLIENTE, 1,
				a.Fecha, GETDATE(), '', 'F',
				a.PorcDesc01, a.TotalDesc, 0, 0,
				a.NetoAfecto, a.IVA, a.Total, 0,
				'F', '', 1, 1,
				'T', 1, 'F', a.Fecha,
				0, 0, @TIPODOC, CASE WHEN @NUMFAC = -1 THEN -1 ELSE @TIPODOC END,
				-1, -1, GETDATE(), 0,
				0, 0, '', 0,
				-1, GETDATE(), 'F', '',
				0, 'F', 0, 0,
				0, 0, 0, 0,
				'', 0, 0, 'T',
				0, 0, '', 'F',
				0, 0, 0, '',
				GETDATE(), 0, 0, NULL,
				'F', GETDATE(), -1, 0,
				NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL,
				0, 0
			FROM
				VARSO.softland.iw_gsaen a
			WHERE
				a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			)

			-----Ahora inserto el detalle
			INSERT INTO
				BDVARSOVIENNE.dbo.ALBVENTALIN
			(
			 NUMSERIE, NUMALBARAN, N, NUMLIN, 
			 CODARTICULO, REFERENCIA, DESCRIPCION, COLOR, 
			 TALLA, UNID1, 
			 UNID2, UNID3, UNID4, 
			 UNIDADESTOTAL, UNIDADESPAGADAS, PRECIO, 
			 DTO, TOTAL, COSTE, PRECIODEFECTO, 
			 TIPOIMPUESTO, IVA, REQ, CODTARIFA, 
			 CODALMACEN, LINEAOCULTA, NUMKG, PRESTAMO, 
			 CODVENDEDOR, SUPEDIDO, CONTACTO, PRECIOIVA, 
			 CODFORMATO, CODMACRO, UDSEXPANSION, EXPANDIDA, 
			 TOTALEXPANSION, COSTEIVA, TIPO, FECHAENTREGA, 
			 COMISION, NUMKGEXPANSION, CARGO1, CARGO2, 
			 HORA, UDSABONADAS, ABONODE_NUMSERIE, ABONODE_NUMALBARAN, 
			 ABONODE_N, FECHACADUCIDAD, UDMEDIDA2, UDMEDIDA2EXPANSION, 
			 IDPROMOCION, IMPORTEANTESPROMOCION, IMPORTEANTESPROMOCIONIVA, IMPORTEPROMOCION, 
			 IMPORTEPROMOCIONIVA, PORCRETENCION, DTOANTESPROMOCION, STOCK, 
			 COSTE2, COSTEIVA2, IDMOTIVODTO, DETALLEMODIF, 
			 DETALLEDENUMLINEA, TIPODELIVERY, FAMILIAAENA, TIPORETENCION, 
			 ABONODELINEA, HORACOCINA, IDMOTIVOABONO, ISPRECIO2, 
			 TARIFAANTESPROMOCION
			)
			(
			SELECT
				@NUMSERIE, @NUMALBARAN, @N, b.Linea,
				c.CODARTICULO, d.REFPROVEEDOR, d.DESCRIPCION, '.',
				'.', b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada AS UNID1, 
				1,1,1, 
				b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada, 0, b.PreUniMB,
				b.PorcDescMov01, b.TotLinea, 0, b.PreUniMB,
				1, 19, 0, 1,
				@CODALMACEN, 'F', 0, 'F',
				1, '.' + @NUMSERIE + '-' + LEFT(CAST(@NUMFAC AS varchar(25)),8), -1, b.PreUniMB * 1.19,
				0, 0, b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada AS UDSEXPANSION, 'F',
				b.TotLinea, 0, 'V', a.Fecha,
				0, 0, 0, 0,
				NULL, 0, '', -1,
				'', GETDATE(), 0, 0,
				-1, 0, 0, 0,
				0, 0, 0, NULL,
				0, 0, -1, 0,
				0, NULL, 0, 0,
				-1, NULL, 0, 'F',
				0
			FROM
				VARSO.softland.iw_gsaen a
				INNER JOIN VARSO.softland.iw_gmovi b
					ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
				INNER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
					ON c.CODBARRAS COLLATE database_default = b.CodProd
				INNER JOIN BDVARSOVIENNE.dbo.ARTICULOS d
					ON d.CODARTICULO = c.CODARTICULO
			WHERE
				a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			)




			-----Ahora inserto el TOT
			INSERT INTO
				BDVARSOVIENNE.dbo.ALBVENTATOT
			(
			 SERIE, NUMERO, N, NUMLINEA, 
			 BRUTO, DTOCOMERC, TOTDTOCOMERC, 
			 DTOPP, TOTDTOPP, BASEIMPONIBLE, 
			 IVA, TOTIVA, REQ, 
			 TOTREQ, TOTAL, ESGASTO, 
			 CODDTO, DESCRIPCION
			)
			(
			SELECT
				@NUMSERIE, @NUMALBARAN, @N, 1,
				a.NetoAfecto, a.PorcDesc01, a.TotalDesc,
				0, 0, a.NetoAfecto,
				19, a.IVA, 0,
				0, a.Total, 'F',
				-1, ''
			FROM
				VARSO.softland.iw_gsaen a
			WHERE
				a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			)



			--Ahora a las tablas Facturas, que son iguales a las albventas, ojo, deben estar aqui para que sean visibles en el frontend.
			IF @NUMFAC <> -1
			BEGIN
				--CABECERA
				INSERT INTO
					BDVARSOVIENNE.dbo.FACTURASVENTA
				(
				NUMSERIE, NUMFACTURA, N, 
				CODCLIENTE, FECHA, HORA, 
				ENVIOPOR, PORTESPAG, DTOCOMERCIAL, 
				TOTDTOCOMERCIAL, DTOPP, TOTDTOPP, 
				TOTALBRUTO, TOTALIMPUESTOS, TOTALNETO, 
				TOTALCOSTE, CODMONEDA, FACTORMONEDA, 
				IVAINCLUIDO, TRASPASADA, FECHATRASPASO, 
				ENLACE_EJERCICIO, ENLACE_EMPRESA, ENLACE_USUARIO, 
				ENLACE_ASIENTO, CODVENDEDOR, VIENEDEFO, 
				FECHAENTRADA, TIPODOC, IDESTADO, 
				FECHAMODIFICADO, Z, CAJA, 
				TOTALCOSTEIVA, ENTREGADO, CAMBIO, 
				PROPINA, CODENVIO, TRANSPORTE, 
				TOTALCARGOSDTOS, NUMROLLO, VENDEDORMODIFICADO, 
				TOTALRETENCION, SUFACTURA, ESINVERSION, 
				FECHACREACION, IDMOTIVODTO, NUMIMPRESIONES, 
				CLEANCASHCONTROLCODE1, CLEANCASHCONTROLCODE2, AGRUPACION,
				ESENTREGAACUENTA, REGIMFACT
				)
				(
				SELECT
					@NUMSERIE, @NUMFAC, @N,
					@CODCLIENTE, a.Fecha, GETDATE(),
					'', 'F', a.PorcDesc01, 
					a.TotalDesc, 0, 0, 
					a.NetoAfecto, a.IVA, a.Total,
					0, 1, 1,
					'T', 'T', GETDATE(),
					2017, 1, '{G:FV:00}',
					6, 1, 'F',
					NULL, @TIPODOC, -1,
					GETDATE(), 0, '',
					0, 0, 0,
					0, 0, 0,
					0, 0, NULL,
					0, '', 0,
					GETDATE(), -1, 0,
					NULL, NULL, NULL,
					'F', 'G'
				FROM
					VARSO.softland.iw_gsaen a
				WHERE
					a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
				)


				-----Ahora inserto el TOT
				INSERT INTO
					BDVARSOVIENNE.dbo.FACTURASVENTATOT
				(
				 SERIE, NUMERO, N, NUMLINEA, 
				 BRUTO, DTOCOMERC, TOTDTOCOMERC, 
				 DTOPP, TOTDTOPP, BASEIMPONIBLE, 
				 IVA, TOTIVA, REQ, 
				 TOTREQ, TOTAL, ESGASTO, 
				 CODDTO, DESCRIPCION
				)
				(
				SELECT
					@NUMSERIE, @NUMALBARAN, @N, 1,
					a.NetoAfecto, a.PorcDesc01, a.TotalDesc,
					0, 0, a.NetoAfecto,
					19, a.IVA, 0,
					0, a.Total, 'F',
					-1, ''
				FROM
					VARSO.softland.iw_gsaen a
				WHERE
					a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
				)

			END

		END
		ELSE
		BEGIN
			--Compruebo Número Albaran
			IF @NUMALBARAN IS NULL
			BEGIN
				SELECT
					@NUMALBARAN = ISNULL(MAX(NUMALBARAN) + 1,1) 
				FROM BDVARSOVIENNE.dbo.ALBCOMPRACAB
				WHERE NUMSERIE = @NUMSERIE
			END

			IF @NUMFAC IS NULL
			BEGIN
				SET @NUMFAC = @NUMALBARAN
			END

			--Tomo CodCliente
			IF @RutAux IS NULL 
			BEGIN 
				SET  @CODCLIENTE = 0 
			END
			ELSE
			BEGIN
				SELECT @CODCLIENTE = CODCLIENTE FROM BDVARSOVIENNE.dbo.CLIENTES WHERE NIF20 = @RutAux
			END

			--Ahora inserto cabecera
			INSERT INTO
				BDVARSOVIENNE.dbo.ALBCOMPRACAB
			(
			NUMSERIE, NUMALBARAN, N, SUALBARAN, 
			FACTURADO, NUMSERIEFAC, NUMFAC, NFAC, 
			ESUNDEPOSITO, ESDEVOLUCION, CODPROVEEDOR, FECHAALBARAN, 
			ENVIOPOR, PORTESPAG, DTOCOMERCIAL, TOTDTOCOMERCIAL, 
			DTOPP, TOTDTOPP, TOTALBRUTO, TOTALIMPUESTOS, 
			TOTALNETO, SELECCIONADO, CODMONEDA, FACTORMONEDA, 
			IVAINCLUIDO, FECHAENTRADA, TIPODOC, TIPODOCFAC, 
			IDESTADO, FECHAMODIFICADO, HORA, TRANSPORTE, 
            NBULTOS, TOTALCARGOSDTOS, CODCLIENTE, CHEQUEADO, 
			NORECIBIDO, FECHAALBARANVENTA, FECHACREACION, NUMIMPRESIONES

			)
			(
			SELECT
				@NUMSERIE, @NUMALBARAN, @N, '',
				@FACTURADO, @NUMSERIEFAC, @NUMFAC, @N,
				'F', 'F', @CODCLIENTE, a.Fecha,
				'', 'F', 0, 0,
				0, 0, a.NetoAfecto, a.IVA, 
				a.Total, 'F', 1, 1,
				'F', NULL, @TIPODOC, CASE WHEN @NUMFAC = -1 THEN -1 ELSE @TIPODOC END,
				-1, a.Fecha, GETDATE(), 0,
				0, 0, CASE WHEN @CODCLIENTE = 0 THEN -1 ELSE @CODCLIENTE END, 'F',
				'T', GETDATE(), GETDATE(), NULL
			FROM
				VARSO.softland.iw_gsaen a
			WHERE
				a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			)

			-----Ahora inserto el detalle
			INSERT INTO
				BDVARSOVIENNE.dbo.ALBCOMPRALIN
			(
			NUMSERIE, NUMALBARAN, N, NUMLIN, 
			CODARTICULO, REFERENCIA, DESCRIPCION, COLOR, 
			TALLA, UNID1, UNID2, UNID3, 
			UNID4, UNIDADESTOTAL, UNIDADESPAGADAS, PRECIO, 
			DTO, TOTAL, TIPOIMPUESTO, IVA, 
			REQ, NUMKG, CODALMACEN, DEPOSITO, 
			PRECIOVENTA, USARCOLTALLAS, IMPORTEGASTOS, UDSEXPANSION, 
			EXPANDIDA, TOTALEXPANSION, SUPEDIDO, CODCLIENTE, 
			NUMKGEXPANSION, CARGO1, CARGO2, DTOTEXTO, 
			ESOFERTA, CODENVIO, UDMEDIDA2, UDMEDIDA2EXPANSION, 
			PORCRETENCION, TIPORETENCION, UDSABONADAS, ABONODE_NUMSERIE, 
			ABONODE_NUMALBARAN, ABONODE_N, IMPORTECARGO1, IMPORTECARGO2, 
			LINEAOCULTA, IDMOTIVO, CODFORMATO, CODMACRO
			)
			(
			SELECT
				@NUMSERIE, @NUMALBARAN, @N, b.Linea,
				c.CODARTICULO, d.REFPROVEEDOR, d.DESCRIPCION, '.',
				'.', b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada, 1, 1,
				1, b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada, 0, b.PreUniMB,
				b.PorcDescMov01, b.TotLinea, 1, 19, 
				0, 0, @CODALMACEN, 'F', 
				0, 'F', 0, b.CantIngresada * @MultiploCantIngresada + b.CantDespachada * @MultiploCantDespachada + b.CantFacturada * @MultiploCantFacturada,
				'F', b.TotLinea, '', -1 AS CodCliente,
				0, 0, 0, '0',
				'F', -1, 0, 0,
				0, 0, 0, '',
				-1, '', 0, 0, 
				'F', -1, 0, 0
			FROM
				VARSO.softland.iw_gsaen a
				INNER JOIN VARSO.softland.iw_gmovi b
					ON b.Tipo = a.Tipo AND b.NroInt = a.NroInt
				INNER JOIN BDVARSOVIENNE.dbo.ARTICULOSLIN c
					ON c.CODBARRAS COLLATE database_default = b.CodProd
				INNER JOIN BDVARSOVIENNE.dbo.ARTICULOS d
					ON d.CODARTICULO = c.CODARTICULO
			WHERE
				a.CodBode = @CodBode AND a.Tipo = @Tipo AND a.SubTipoDocto = @SubTipoDocto AND a.Folio = @Folio
			)

		END

		--Si llega hasta aquí quiere decir que no falló el traspaso
		UPDATE GESTIONVARSO.Traspaso.Documento
		SET 
			NUMALBARAN = @NUMALBARAN,
			SeTraspasoICG = 1,
			errorTraspasoICG = NULL
		WHERE 
			CodBode = @CodBode AND Tipo = @Tipo AND SubTipoDocto = @SubTipoDocto AND Folio = @Folio

		--FIN:3.4° Traspaso a ICG
		----------------------------

		--	
		CONTINUE
	END
	
	--FIN: 3° Proceso recorriendo cada Documento
	-------------------------------------------------
END;

