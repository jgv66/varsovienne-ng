USE [GESTIONVARSO]
GO
-- exec [Traspaso].[p_BF_Trasp_Softland_c5min]
-- =============================================
-- Author:		Daniel Cornejo (dcornejo@infocst.cl)
-- Modification date: 2019-10-15  JGV @Kinetik.cl 
-- Description:	proceso cada 5 minutos
-- exec [Traspaso].[p_Boletas_TraspasarSoftland]
-- =============================================
ALTER PROCEDURE [Traspaso].[p_BF_Trasp_Softland_c5min]
AS
BEGIN

	SET NOCOUNT ON;
	INSERT INTO GESTIONVARSO.Traspaso.LogTraspasos	(TipoTraspaso, Observacion)	VALUES	('automatico', 'init' )

	-- solo se traspasa lo del dia
	declare @hoy as date = cast( getdate() as date );

	--Deshabilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen DISABLE TRIGGER IW_GSaEnVW_ITRIG
		
	--a) Limpio tabla completa
	DELETE FROM Traspaso.BoletasRepetidas
	
	-----------------------------------------------
	--1° consigno todas las boletas nuevas para ser procesadas
	INSERT INTO GESTIONVARSO.Traspaso.Boletas (	NUMSERIEFAC, 	NUMFAC,    NFAC,   TOTALNETO, NUMSERIE,     NUMALBARAN,   N,   CODALMACEN,   CODVENDEDOR,	FolioSoftland,   BoletaFiscal, BoletaElectronica )
	SELECT	                                    x.NUMSERIEFAC, x.NUMFAC, x.NFAC, x.TOTALNETO, x.NUMSERIE, x.NUMALBARAN, x.N, x.CODALMACEN, x.CODVENDEDOR, x.FolioSoftland, x.BoletaFiscal, x.BoletaElectronica
	FROM
		(
		SELECT top 50
			CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE      END AS NUMSERIEFAC,
			CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC      ELSE c.NUMERO_BOLETA END AS NUMFAC,
			CASE WHEN a.TIPODOC in (13,23) THEN a.NFAC        ELSE a.N             END AS NFAC,
			a.TOTALNETO, a.NUMSERIE, a.NUMALBARAN, a.N,
			LEFT(CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END, 2) AS CODALMACEN, 
			a.CODVENDEDOR,
			CAST(LEFT(CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3) + RIGHT('00000000' + CAST(CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS varchar(8)),8) AS Decimal(18,0)) AS FolioSoftland,
			CASE WHEN a.TIPODOC = 13 THEN -1 ELSE 0 END AS BoletaFiscal,
			CASE WHEN a.TIPODOC = 23 THEN  1 ELSE 0 END AS BoletaElectronica
		FROM
			BDMANVARSO.dbo.ALBVENTACAB                    AS a with (nolock)
			LEFT JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
			LEFT JOIN GESTIONVARSO.Traspaso.Boletas          AS b with (nolock) ON b.NUMSERIEFAC = CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC  ELSE a.NUMSERIE      END collate database_default
																			   AND b.NUMFAC      = CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC       ELSE c.NUMERO_BOLETA END
																		       AND b.NFAC        = CASE WHEN a.TIPODOC in (13,23) THEN a.NFAC         ELSE a.N             END collate database_default
		WHERE
			( b.NUMFAC IS NULL ) --No se halla traspasado  or ( a.FECHACREACION between {d '2019-04-09'} and {d '2019-04-11'} )
			AND a.TIPODOC IN (13,18,23) --13 Boleta Fiscal, 18 Boleta Manual, 23 Boleta Electronica
			AND CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC ELSE c.NUMERO_BOLETA END > 0 --Que el folio sea >0
			AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
			AND a.IDESTADO = -1
			AND cast( a.FECHACREACION as date ) = @hoy
			AND ISNUMERIC(LEFT(CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3)) = 1
		) AS x

	--FIN: 1° consigno todas las boletas nuevas para ser procesadas
	------------------------------------------------
	INSERT INTO GESTIONVARSO.Traspaso.LogTraspasos	(TipoTraspaso, Observacion)	VALUES	('automatico', 'select' )

	------------------------------------------------
	--2° Reinicio para re-procesar
	-- select * from  GESTIONVARSO.Traspaso.Boletas
	--Llevo todos los registros Traspasados False a NULL, pues los True y False no se procesan
	-- cambié el = por un coalesce()  jgv/kinetik  
	UPDATE GESTIONVARSO.Traspaso.Boletas
	SET SeTraspasoSoftland = NULL, 
	    errorTraspasoSoftland = ''
	WHERE coalesce(SeTraspasoSoftland,0) = 0
	  and NFAC = 'B'

	--LIMPIO tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorBodega
	DELETE FROM GESTIONVARSO.traspaso.Boletas_ErrorVendedor
	------------------------------------------------
		
	-------------------------------------------------
	--3° Proceso recorriendo cada boleta
	
	-- variable de error
	declare @error_articulo	bit = 0,
			@error_bod_cc	bit = 0,
			@error_vendedor	bit = 0,
			@error_folio	bit = 0,
			@codauxbodega	varchar(10),
			@xerr_desc		nvarchar(400) = '';

	-- ICG
	DECLARE @NUMSERIEFAC		nvarchar(4),
			@NUMFAC				int,
			@NFAC				char(1),
			@FolioSoftland		decimal(18,0),
			@CODALMACEN			nvarchar(3),
			@CODVENDEDOR		int,
			@BoletaFiscal		int,
			@BoletaElectronica	int
	
	--Softland
	DECLARE @NroInt int,		--El numero del nuevo registro de la tabla en softland
			@aprocesar int = 0,
			@procesados int = 0; 

	select @aprocesar = count(*)
	FROM GESTIONVARSO.Traspaso.Boletas with (nolock)
	WHERE coalesce(SeTraspasoSoftland,0)=0 
	  and NFAC = 'B'
	  and CAST( fcrea as date ) = @hoy
	--
	INSERT INTO GESTIONVARSO.Traspaso.LogTraspasos	(TipoTraspaso, Observacion)	VALUES	('automatico', 'procesar:'+cast(@aprocesar as varchar(5)) ) ;

	-- cursor sobre documentos candidatos
	declare detalle_cursor cursor forward_only static read_only 
	for 
	select NUMSERIEFAC, NUMFAC, NFAC, FolioSoftland, CODALMACEN, CODVENDEDOR, BoletaFiscal, BoletaElectronica
	FROM GESTIONVARSO.Traspaso.Boletas with (nolock)
	WHERE coalesce(SeTraspasoSoftland,0)=0 
	  and NFAC = 'B'
	  and CAST( fcrea as date ) = @hoy
	order by NUMSERIEFAC, NUMFAC, NFAC
	--
	open detalle_cursor
	--
	fetch next from detalle_cursor
	into @NUMSERIEFAC, @NUMFAC, @NFAC, @FolioSoftland, @CODALMACEN, @CODVENDEDOR, @BoletaFiscal, @BoletaElectronica
	--
	while @@FETCH_STATUS = 0  
	begin  

		set @error_articulo	= 0;
		set @error_bod_cc	= 0;
		set @error_vendedor	= 0;
		set	@error_folio	= 0;

		--Marco como FALSE inicialmente
		UPDATE GESTIONVARSO.Traspaso.Boletas 
		SET SeTraspasoSoftland = 0, FechaUltimoIntento = GETDATE()
		WHERE NUMSERIEFAC = @NUMSERIEFAC
		  AND NUMFAC = @NUMFAC
		  AND NFAC = @NFAC

		--3.1° Compruebo articulos
		--Marco error si corresponde (considerar que ya puse false al estado)
		IF EXISTS(  SELECT *
					FROM BDMANVARSO.dbo.ALBVENTACAB                  AS a with (nolock)
					INNER JOIN BDMANVARSO.dbo.ALBVENTALIN            AS b with (nolock) ON b.NUMSERIE = a.NUMSERIE AND b.NUMALBARAN = a.NUMALBARAN AND b.N = a.N
					INNER JOIN BDMANVARSO.dbo.ARTICULOSLIN           AS c with (nolock) ON c.CODARTICULO = b.CODARTICULO	
					LEFT  JOIN BVARSOVIENNE.softland.iw_tprod           AS d with (nolock) ON d.CodProd = c.CODBARRAS collate database_default
					LEFT  JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES   AS e with (nolock) ON e.NUMSERIE = a.NUMSERIE AND e.NUMALBARAN = a.NUMALBARAN AND e.N = a.N
					WHERE   (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE      END) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC      ELSE e.NUMERO_BOLETA END) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NFAC        ELSE a.N             END) = @NFAC
						AND d.CodProd IS NULL )
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = 'Error Falta asignar cód de Articulo Softland'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC
			-- marco errores
			set @error_articulo = 1;
		END	
		--FIN: 3.1° Compruebo articulos
		---------------------------

		---------------------------
		--3.2° Compruebo CodBodega, O sea, si no encuentra bodega y  centro de costo asignado
		IF NOT EXISTS( SELECT * 
                       FROM Traspaso.Rel_Bodega_Almacen			  AS a with (nolock)
                       INNER JOIN BVARSOVIENNE.softland.iw_tbode  AS b with (nolock) ON b.CodBode = a.CodBodeSoftland COLLATE DATABASE_DEFAULT
                       INNER JOIN BVARSOVIENNE.softland.cwtccos   AS c with (nolock) ON c.CodiCC = a.CodiCCSoftland COLLATE DATABASE_DEFAULT
                       WHERE a.CODALMACENICG = LEFT(@NUMSERIEFAC, 2) ) BEGIN
			INSERT INTO	Traspaso.Boletas_ErrorBodega   ( NUMSERIEFAC, NUMFAC, NFAC, CODALMACEN )
			                                    VALUES ( @NUMSERIEFAC, @NUMFAC, @NFAC, LEFT(@NUMSERIEFAC, 2) )
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error Falta asignar Bodega y Centro Costo'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			-- marco errores
			set @error_bod_cc = 1;
		END	
		--FIN: 3.2° Compruebo CodBodega
	    ---------------------------

		---------------------------
		--3.21° Compruebo CODVENDEDOR, O sea, si no encuentra VENDEDOR
		IF NOT EXISTS(SELECT * 
					  FROM Traspaso.Rel_Vendedor AS a with (nolock)
					  INNER JOIN BVARSOVIENNE.softland.cwtvend AS b with (nolock) ON b.VenCod = a.VenCodSoftland COLLATE DATABASE_DEFAULT
					  WHERE	a.CODVENDEDOR = @CODVENDEDOR ) BEGIN
			INSERT INTO Traspaso.Boletas_ErrorVendedor (NUMSERIEFAC, NUMFAC, NFAC, CODVENDEDOR) 
                                                VALUES ( @NUMSERIEFAC, @NUMFAC, @NFAC, @CODVENDEDOR )
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error CodVendedor'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			-- marco errores
			set @error_vendedor = 1;
		END	
		--FIN: 3.21° Compruebo CODVENDEDOR
		---------------------------

		---------------------------
		--3.3° Compruebo Folio existente en Softland
		IF EXISTS (	SELECT * 
					FROM BVARSOVIENNE.softland.iw_gsaen AS a
					INNER JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen AS b ON b.CodBodeSoftland collate database_default = a.CodBode
					WHERE Tipo = 'B' 
					  AND Folio = @FolioSoftland 
					  AND b.CODALMACENICG = @CODALMACEN
					  AND a.DTE_SiiTDoc = (CASE WHEN @BoletaElectronica = 1 THEN 39 ELSE 0 END)	) BEGIN
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET SeTraspasoSoftland = 1, 
				errorTraspasoSoftland = 'Error BOLETA YA EXISTE SOFTLAND'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			-- marco errores
			set @error_folio = 1;
		END	
		--FIN: 3.3° Compruebo Folio existente en Softland
	
		----------------------------
		--3.4° Traspaso a Softland
		--Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el traspaso.
		if ( @error_articulo = 0 and @error_bod_cc = 0 and @error_vendedor = 0 and	@error_folio = 0 ) 
		begin
			BEGIN TRANSACTION 
				begin try

					-- el nuevo NroInt de Softland
					SELECT @NroInt = ISNULL(MAX(NroInt) + 1,1) FROM BVARSOVIENNE.softland.iw_gsaen	WHERE Tipo = 'B'

					--Inserto cabecera
					INSERT INTO	BVARSOVIENNE.softland.iw_gsaen
					(   Tipo, NroInt, CodBode, Folio,
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
						TipDocRef )
					SELECT  'B', @NroInt, b.CodBodeSoftland, @FolioSoftland,
							'02',
							'V', a.FECHA,
							'auticg/' + LEFT(ISNULL(b.DesBode,''),15),
							0, 0, 'A', 0, d.VenCodSoftland COLLATE DATABASE_DEFAULT, '01',
							0, 'softland',
							a.TOTALBRUTO, 0, a.TOTALIMPUESTOS, 0, 0,
							0, 0, 0, 0, 0, 0,
							0, 0,
							0, 0, 0,  a.TOTALNETO, 0,
							0, b.CodiCCSoftland, a.TOTALNETO,
							0, 0, 0, 0, 0,
							'IW', 'captura de documentos de venta',
							0, 0, 0, 0,
							0,
							(CASE WHEN @BoletaElectronica = 1 THEN 'T' ELSE 'A' END),
							0,
							a.FECHACREACION, 0, @BoletaFiscal, 0,
							0, 0, 0, 0,
							(CASE WHEN @BoletaElectronica = 1 THEN 39 ELSE 0 END), 0, 1, 0,  -- incluir boletas electronicas generadas desde ICG . kinetik  05/10/2018
							0, 3,
							0, 0,
							'B'
					FROM BDMANVARSO.dbo.ALBVENTACAB                  AS a with (nolock)
					INNER JOIN Traspaso.Rel_Bodega_Almacen           AS b with (nolock) ON b.CODALMACENICG = LEFT(@NUMSERIEFAC, 2)
					LEFT  JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES   AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.NUMALBARAN = a.NUMALBARAN AND c.N = a.N
					LEFT  JOIN GESTIONVARSO.Traspaso.Rel_Vendedor    AS d with (nolock) ON d.CODVENDEDOR = a.CODVENDEDOR
					WHERE   (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC  ELSE a.NUMSERIE       END ) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC       ELSE c.NUMERO_BOLETA  END ) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NFAC         ELSE a.N              END ) = @NFAC

					-- recuperar el codigode bodega para traspasarlo a CODAUX de movi....   jgv 

					--Ahora inserto el detalle
					INSERT INTO	BVARSOVIENNE.softland.iw_gmovi
					(   Tipo, NroInt, Linea, CodProd, CodBode,
						Fecha, CantIngresada, CantDespachada, CantFacturada,
						PreUniMB,
						PreUniMVta,
						PreUniMOrig,
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
						DetProd	)
					SELECT 
						'B', @NroInt, b.NUMLIN, c.CODBARRAS, e.CodBodeSoftland,
						a.FECHA, 0, b.UNID1, b.UNID1, 
						b.PRECIO,
						0,
						0,
						b.DTO,
						b.UNID1 * b.PRECIO * (b.DTO / 100), --b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
						0, 0,
						0, 0, 0, 0,
						0, 0,
						b.UNID1 * b.PRECIO * (b.DTO / 100), --b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
						1, -1,
						b.UNID1 * b.PRECIO * ((100-b.DTO) / 100),   --Total Linea
						0,
						'D', 'N', 'A', e.CodBodeSoftland, '', 0,
						0, 0, 0, d.CodUMed, b.UNID1,
						b.UNID1, 0, 0, b.IMPORTEANTESPROMOCION - b.IMPORTEPROMOCION,
						b.PRECIOIVA, b.UNID1 * b.PRECIO * ((100-b.DTO) / 100)* ((100+b.IVA)/100),
						b.DESCRIPCION
					FROM BDMANVARSO.dbo.ALBVENTACAB						AS a with (nolock) 
					INNER JOIN BDMANVARSO.dbo.ALBVENTALIN				AS b with (nolock) ON b.NUMSERIE = a.NUMSERIE AND b.NUMALBARAN = a.NUMALBARAN AND b.N = a.N
					INNER JOIN BDMANVARSO.dbo.ARTICULOSLIN				AS c with (nolock) ON c.CODARTICULO = b.CODARTICULO
					LEFT  JOIN BVARSOVIENNE.softland.iw_tprod			AS d with (nolock) ON d.CodProd = c.CODBARRAS collate database_default
					LEFT  JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen AS e with (nolock) ON e.CODALMACENICG = LEFT(@NUMSERIEFAC, 2)
					LEFT  JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES	AS f with (nolock) ON f.NUMSERIE = a.NUMSERIE AND f.NUMALBARAN = a.NUMALBARAN AND f.N = a.N
					WHERE   (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NUMFAC ELSE f.NUMERO_BOLETA END) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (13,23) THEN a.NFAC ELSE a.N END) = @NFAC

					-- traspaso efectuado
					UPDATE GESTIONVARSO.Traspaso.Boletas 
					SET SeTraspasoSoftland = 1,
						errorTraspasoSoftland = NULL
					WHERE NUMSERIEFAC = @NUMSERIEFAC 
						AND NUMFAC = @NUMFAC 
						AND NFAC = @NFAC
					--
					COMMIT TRANSACTION
					--
					set @procesados += 1;
					--
				end try
				begin catch
					ROLLBACK TRANSACTION
					--
					set @xerr_desc	= left( ERROR_MESSAGE(), 200 )
					UPDATE GESTIONVARSO.Traspaso.Boletas 
					SET SeTraspasoSoftland = 0,
						errorTraspasoSoftland = @xerr_desc
					WHERE NUMSERIEFAC = @NUMSERIEFAC 
						AND NUMFAC = @NUMFAC 
						AND NFAC = @NFAC
					--
				end catch

		end;

		--FIN:3.4° Traspaso a Softland
		----------------------------
		fetch next from detalle_cursor
		into @NUMSERIEFAC, @NUMFAC, @NFAC, @FolioSoftland, @CODALMACEN, @CODVENDEDOR, @BoletaFiscal, @BoletaElectronica;
		--
	END;
	
	close detalle_cursor  
	deallocate detalle_cursor  

	--FIN: 3° Proceso recorriendo cada boleta
	-------------------------------------------------
	INSERT INTO GESTIONVARSO.Traspaso.LogTraspasos	(TipoTraspaso, Observacion)	VALUES	('automatico', 'procesados '+cast(@procesados as varchar(5))+' fin' )
	
	--Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG
		
END;

