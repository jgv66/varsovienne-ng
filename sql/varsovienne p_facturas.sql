USE [GESTIONVARSO]
GO
/****** Object:  StoredProcedure [Traspaso].[p_Facturas_TraspasarSoftland]    Script Date: 28-10-2019 22:30:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Traspaso].[p_Facturas_TraspasarSoftland]
AS
BEGIN
	--COLLATE SQL_Latin1_General_CP1_CI_AI
	SET NOCOUNT ON;
	
	--Deshabilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen DISABLE TRIGGER IW_GSaEnVW_ITRIG
		
	------------------------------------------------------------
	--0° Antes de Todo, reviso y registro las Boletas Repetidas (Hasta ahora pasa con las Manuales) 21-12-2016 Daniel Cornejo

	--a) Limpio tabla completa
	DELETE FROM Traspaso.FacturasRepetidas

	-- SELECT TOP (1000) TIPODOC,TIPODOCFAC,CODCLIENTE,TIQUET,* from BDMANVARSO.dbo.ALBVENTACAB where FECHA='20190620' and NUMSERIE like '121%'
	
	--b) Inserto las repetidas encontradas, ojo, estas no han sido traspasadas a Softland
	INSERT INTO	Traspaso.FacturasRepetidas (NUMSERIEFAC,   NUMFAC,   NFAC,   TOTALNETO, 	NUMSERIE,   NUMALBARAN,   N,   CODALMACEN,   CODVENDEDOR, CODCLIENTE,     FolioSoftland,   BoletaFiscal,   FacturaElectronica )
	SELECT	                                x.NUMSERIEFAC, x.NUMFAC, x.NFAC, x.TOTALNETO, x.NUMSERIE, x.NUMALBARAN, x.N, x.CODALMACEN, x.CODVENDEDOR, x.CODCLIENTE, x.FolioSoftland, x.BoletaFiscal, x.FacturaElectronica
	FROM
		(   SELECT
				CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC   ELSE a.NUMSERIE      END AS NUMSERIEFAC,
				CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC        ELSE c.NUMERO_BOLETA END AS NUMFAC,
				CASE WHEN a.TIPODOC in (24) THEN a.NFAC          ELSE a.N             END AS NFAC,
				a.TOTALNETO, a.NUMSERIE, a.NUMALBARAN, a.N,
				LEFT(CASE WHEN a.TIPODOC = 24 THEN a.NUMSERIEFAC ELSE a.NUMSERIE END, 2) AS CODALMACEN, 
				a.CODVENDEDOR,
				a.CODCLIENTE,
				CAST(LEFT(CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC 
							   ELSE case when ISNUMERIC(LEFT(a.NUMSERIE,3))=1 then a.NUMSERIE 
									     else RIGHT('77777777' + cast(a.NUMALBARAN as varchar(20)),3) end END,3) + RIGHT('00000000' + CAST(CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS varchar(8)),8) AS Decimal(18,0)) AS FolioSoftland,
				0 AS BoletaFiscal,
				(CASE WHEN a.TIPODOC=24 then 1 else 0 end ) as FacturaElectronica
			FROM
				BDMANVARSO.dbo.ALBVENTACAB AS a with (nolock)
				LEFT JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
				LEFT JOIN GESTIONVARSO.Traspaso.Boletas          AS b with (nolock) ON b.NUMSERIEFAC  = CASE WHEN a.TIPODOC   in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE       END collate database_default
																				   AND b.NUMFAC       = CASE WHEN a.TIPODOC   in (24) THEN a.NUMFAC      ELSE c.NUMERO_BOLETA  END
																				   AND b.NFAC         = CASE WHEN a.TIPODOC   in (24) THEN a.NFAC        ELSE a.N              END collate database_default
			WHERE
				b.NUMFAC IS NULL --No se halla traspasado
				AND a.FECHACREACION > '20190531'
				AND a.TIPODOC IN (24) --24 factura electronica
				AND a.NUMFAC > 0 --Que el folio sea >0
				AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
				AND a.IDESTADO = -1
				AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10 
		) AS x
        --FActuras NO traspasadas y Repetidas
		INNER JOIN	
        (   SELECT
				CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC   ELSE a.NUMSERIE      END AS NUMSERIEFAC,
				CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC        ELSE c.NUMERO_BOLETA END AS NUMFAC,
				CASE WHEN a.TIPODOC in (24) THEN a.NFAC          ELSE a.N             END AS NFAC,
                CASE WHEN a.TIPODOC = 24 	THEN 1               ELSE 0               END AS BoletaElectronica,
                COUNT(*) AS Repetidas
            FROM
                BDMANVARSO.dbo.ALBVENTACAB                    AS a with (nolock)
                LEFT JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
				LEFT JOIN GESTIONVARSO.Traspaso.Boletas       AS b with (nolock) ON b.NUMSERIEFAC  = CASE WHEN a.TIPODOC   in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE       END collate database_default
																			    AND b.NUMFAC       = CASE WHEN a.TIPODOC   in (24) THEN a.NUMFAC      ELSE c.NUMERO_BOLETA  END
																				AND b.NFAC         = CASE WHEN a.TIPODOC   in (24) THEN a.NFAC        ELSE a.N              END collate database_default
            WHERE
                b.NUMFAC IS NULL --No se halla traspasado
                AND a.TIPODOC IN (24 ) --13 Boleta Fiscal, 18 Boleta Manual, 23 Boleta Electronica
                AND a.NUMFAC > 0 --Que el folio sea >0
                AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
                AND a.IDESTADO = -1
                AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10
            GROUP BY
                CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE      END,
                CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC      ELSE c.NUMERO_BOLETA END,
                CASE WHEN a.TIPODOC in (24) THEN a.NFAC        ELSE a.N             END,
				CASE WHEN a.TIPODOC = 24    THEN 1             ELSE 0               END
            HAVING 
                COUNT(*) > 1
            ) AS y
		ON  y.NUMSERIEFAC = x.NUMSERIEFAC 
        AND y.NUMFAC = x.NUMFAC 
        AND y.NFAC = x.NFAC
		AND y.BoletaElectronica = x.FacturaElectronica
	--FIN: 0° Antes de Todo, reviso y registro las Boletas Repetidas (Hasta ahora pasa con las Manuales) 21-12-2016 Daniel Cornejo
	---------------------------------------------------------------

	-----------------------------------------------
	--1° consigno todas las facturas nuevas para ser procesadas
	INSERT INTO GESTIONVARSO.Traspaso.Boletas (	NUMSERIEFAC, 	NUMFAC,    NFAC,   TOTALNETO, NUMSERIE,     NUMALBARAN,   N,   CODALMACEN,   CODVENDEDOR,	CODCLIENTE,   FolioSoftland,   BoletaFiscal, FacturaElectronica )
	SELECT	                                    x.NUMSERIEFAC, x.NUMFAC, x.NFAC, x.TOTALNETO, x.NUMSERIE, x.NUMALBARAN, x.N, x.CODALMACEN, x.CODVENDEDOR, x.CODCLIENTE, x.FolioSoftland, x.BoletaFiscal, x.FacturaElectronica
	FROM
		(
		SELECT
			CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC   ELSE a.NUMSERIE      END AS NUMSERIEFAC,
			CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC        ELSE c.NUMERO_BOLETA END AS NUMFAC,
			CASE WHEN a.TIPODOC in (24) THEN a.NFAC          ELSE a.N             END AS NFAC,
			a.TOTALNETO, a.NUMSERIE, a.NUMALBARAN, a.N,
			LEFT(CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END, 2) AS CODALMACEN, 
			a.CODVENDEDOR,
			a.CODCLIENTE,
			CAST(LEFT(CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3) + RIGHT('00000000' + CAST(CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC ELSE c.NUMERO_BOLETA END AS varchar(8)),8) AS Decimal(18,0)) AS FolioSoftland,
			0 AS BoletaFiscal,
			(CASE WHEN a.TIPODOC=24 then 1 else 0 end ) as FacturaElectronica
		FROM
			BDMANVARSO.dbo.ALBVENTACAB                    AS a with (nolock)
			LEFT JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.N = a.N AND c.NUMALBARAN = a.NUMALBARAN
			LEFT JOIN GESTIONVARSO.Traspaso.Boletas       AS b with (nolock) ON b.NUMSERIEFAC = CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC  ELSE a.NUMSERIE      END collate database_default
																		    AND b.NUMFAC      = CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC       ELSE c.NUMERO_BOLETA END
																		    AND b.NFAC        = CASE WHEN a.TIPODOC in (24) THEN a.NFAC         ELSE a.N             END collate database_default
		WHERE
			( b.NUMFAC IS NULL ) --No se halla traspasado   between {d '2019-04-09'} and {d '2019-04-11'} )
			AND a.FECHACREACION > '20190531'
			AND a.TIPODOC IN (24) --13 Boleta Fiscal, 18 Boleta Manual, 23 Boleta Electronica, 24 factura electronica
			AND a.NUMFAC > 0 --Que el folio sea >0
			AND a.TOTALNETO > 0 --OJO QUE HAY DEVOLUCIONES, POR ESO ESTE FILTRO. (ADEMAS CONSIDERAR QUE NETO ACA ES BRUTO)
			AND a.IDESTADO = -1
			AND DATEDIFF(MINUTE,a.FECHACREACION,GETDATE()) >= 10
			AND ISNUMERIC(LEFT(CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END,3)) = 1
		) AS x
		LEFT JOIN Traspaso.FacturasRepetidas AS y with (nolock) ON	y.NUMSERIEFAC = x.NUMSERIEFAC	COLLATE DATABASE_DEFAULT 
																AND y.NFAC		  = x.NFAC			COLLATE DATABASE_DEFAULT 
																AND y.NUMFAC = x.NUMFAC 
																AND y.FacturaElectronica = x.FacturaElectronica
	WHERE y.NUMSERIEFAC IS NULL --No estén repetidas	
	--FIN: 1° consigno todas las facturas nuevas para ser procesadas
	------------------------------------------------

	------------------------------------------------
	--2° Reinicio para re-procesar

	/*
	select * from GESTIONVARSO.Traspaso.Boletas
	WHERE coalesce(SeTraspasoSoftland,0) = 0
	  and FacturaElectronica = 1	
	*/

	--Llevo todos los registros de Traspasados False a NULL, pues los True y False no se procesan
	-- cambié el = por un coalesce()  jgv/kinetik  
	UPDATE GESTIONVARSO.Traspaso.Boletas
	SET SeTraspasoSoftland = NULL, 
	    errorTraspasoSoftland = ''
	WHERE coalesce(SeTraspasoSoftland,0) = 0
	  and FacturaElectronica = 1

	--LIMPIO tabla de errores
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorArticulos
	DELETE FROM GESTIONVARSO.Traspaso.Boletas_ErrorBodega
	DELETE FROM GESTIONVARSO.traspaso.Boletas_ErrorVendedor
	--FIN: 2° Reinicio para re-procesar
	------------------------------------------------
		
	-------------------------------------------------
	--3° Proceso recorriendo cada boleta
	
	-- variable de error
	declare @error_articulo	bit = 0,
			@error_bod_cc	bit = 0,
			@error_vendedor	bit = 0,
			@error_cliente	bit = 0,
			@error_folio	bit = 0,
			@codauxbodega	varchar(10),
			@xerr_desc		nvarchar(400) = '';

	--Creo variables para recorrer
	--Vars ICG
	DECLARE @NUMSERIEFAC		nvarchar(4),
			@NUMFAC				int, 
			@NFAC				char(1), 
			@FolioSoftland		decimal(18,0), 
			@CODALMACEN nvarchar(3), 
			@CODVENDEDOR int, 
			@CODCLIENTE varchar(10), 
			@BoletaFiscal int, 
			@FacturaElectronica int

	-- variables para clientes
	declare	@id_Region	int,
		@giro		int = 120,
			@provincia	nvarchar(100),
			@ciudad		varchar(7),
			@poblacion	nvarchar(100),
			@comuna		varchar(7),
			@nrorut		varchar(10);
	
	--Vars Softland
	DECLARE @NroInt int --El numero del nuevo registro de la tabla en softland

	-- cursor sobre documentos candidatos
	declare detalle_cursor cursor forward_only static read_only 
	for 
	select NUMSERIEFAC, NUMFAC, NFAC, FolioSoftland, CODALMACEN, CODVENDEDOR, CODCLIENTE, BoletaFiscal, FacturaElectronica
	FROM GESTIONVARSO.Traspaso.Boletas with (nolock)
	WHERE coalesce(SeTraspasoSoftland,0)=0 
	  and FacturaElectronica = 1
	order by NUMSERIEFAC, NUMFAC, NFAC

	--
	open detalle_cursor
	--
	fetch next from detalle_cursor
	into @NUMSERIEFAC, @NUMFAC, @NFAC, @FolioSoftland, @CODALMACEN, @CODVENDEDOR, @CODCLIENTE, @BoletaFiscal, @FacturaElectronica
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
		  and FacturaElectronica = @FacturaElectronica

		--3.1° Compruebo articulos
		--Marco error si corresponde (considerar que ya puse false al estado)
		IF EXISTS(  SELECT *
					FROM BDMANVARSO.dbo.ALBVENTACAB                AS a with (nolock)
					INNER JOIN BDMANVARSO.dbo.ALBVENTALIN          AS b with (nolock) ON b.NUMSERIE = a.NUMSERIE AND b.NUMALBARAN = a.NUMALBARAN AND b.N = a.N
					INNER JOIN BDMANVARSO.dbo.ARTICULOSLIN         AS c with (nolock) ON c.CODARTICULO = b.CODARTICULO	
					LEFT  JOIN BVARSOVIENNE.softland.iw_tprod      AS d with (nolock) ON d.CodProd = c.CODBARRAS collate database_default
					LEFT  JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS e with (nolock) ON e.NUMSERIE = a.NUMSERIE AND e.NUMALBARAN = a.NUMALBARAN AND e.N = a.N
					WHERE   (CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE      END) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC      ELSE e.NUMERO_BOLETA END) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NFAC        ELSE a.N             END) = @NFAC
						AND d.CodProd IS NULL )
		BEGIN
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = 'Error Falta asignar cód de Articulo Softland'
			WHERE NUMSERIEFAC = @NUMSERIEFAC AND NUMFAC = @NUMFAC AND NFAC = @NFAC and FacturaElectronica = @FacturaElectronica
			-- marco errores
			set @error_articulo = 1;
			--print 'articulo '+@NUMSERIEFAC+' '+cast(@FolioSoftland as varchar(20) )
		END	
		--FIN: 3.1° Compruebo articulos
		---------------------------

		---------------------------
		--3.2° Compruebo CodBodega
		IF NOT EXISTS( SELECT * 
                       FROM Traspaso.Rel_Bodega_Almacen			  AS a with (nolock)
                       INNER JOIN BVARSOVIENNE.softland.iw_tbode  AS b with (nolock) ON b.CodBode = a.CodBodeSoftland COLLATE DATABASE_DEFAULT
                       INNER JOIN BVARSOVIENNE.softland.cwtccos   AS c with (nolock) ON c.CodiCC = a.CodiCCSoftland COLLATE DATABASE_DEFAULT
                       WHERE a.CODALMACENICG = LEFT(@NUMSERIEFAC, 2) ) --O sea, si no encuentra bodega y  centro de costo asignado
		BEGIN
			INSERT INTO	Traspaso.Boletas_ErrorBodega   ( NUMSERIEFAC, NUMFAC, NFAC, CODALMACEN )
			                                    VALUES ( @NUMSERIEFAC, @NUMFAC, @NFAC, LEFT(@NUMSERIEFAC, 2) )
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error Falta asignar Bodega y Centro Costo'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			  and FacturaElectronica = @FacturaElectronica
			-- marco errores
			set @error_bod_cc = 1;
			--print 'bod/cc '+@NUMSERIEFAC+' '+cast(@FolioSoftland as varchar(20))
		END	
		--FIN: 3.2° Compruebo CodBodega
	    ---------------------------

		---------------------------
		--3.21° Compruebo CODVENDEDOR
		IF NOT EXISTS(SELECT * 
					  FROM Traspaso.Rel_Vendedor AS a with (nolock)
					  INNER JOIN BVARSOVIENNE.softland.cwtvend AS b with (nolock) ON b.VenCod = a.VenCodSoftland COLLATE DATABASE_DEFAULT
					  WHERE	a.CODVENDEDOR = @CODVENDEDOR ) --O sea, si no encuentra VENDEDOR
		BEGIN
			INSERT INTO Traspaso.Boletas_ErrorVendedor (NUMSERIEFAC, NUMFAC, NFAC, CODVENDEDOR) 
                                                VALUES ( @NUMSERIEFAC, @NUMFAC, @NFAC, @CODVENDEDOR )
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error CodVendedor'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			  and FacturaElectronica = @FacturaElectronica
			-- marco errores
			set @error_vendedor = 1;
			--print 'vendedor '+@NUMSERIEFAC+' '+@FolioSoftland

		END	
		--FIN: 3.21° Compruebo CODVENDEDOR
		---------------------------

		-- intento de creacion de cliente
		select @nrorut = left( replace(replace(CIF,'.',''),'-','') ,8 )
		FROM [BDMANVARSO].[dbo].[CLIENTES]
		where CODCLIENTE= @CODCLIENTE 
		-- print 'cliente existe en softland ? ' + @nrorut

		--
		if not exists ( select * from BVARSOVIENNE.softland.cwtauxi where CodAux = @nrorut ) begin 

			-- print 'cliente no existe en softland ->' + @nrorut
			--
			Select @provincia = PROVINCIA, @poblacion = POBLACION
			FROM [BDMANVARSO].[dbo].[CLIENTES]
			where CODCLIENTE= @CODCLIENTE 
			--
			select top 1 @id_Region=id_Region	from BVARSOVIENNE.softland.cwtciud where CiuDes = @provincia
			select top 1 @ciudad = CiuCod		from BVARSOVIENNE.softland.cwtciud where CiuDes = @provincia and id_Region = @id_Region
			select @comuna = ComCod				from BVARSOVIENNE.softland.cwtcomu where ComDes = @poblacion and id_Region = @id_Region
			--
			insert into BVARSOVIENNE.softland.cwtauxi (	CodAux,NomAux,NoFAux,RutAux,ActAux,GirAux,ComAux,CiuAux,DirAux,FonAux1,
														ClaCli,ClaPro,ClaEmp,ClaSoc,ClaDis,ClaOtr,Bloqueado,EMail,Region,TipoSaludo,CodPostal,CodAreaFon,CodAreaFax,
														TipoUsuario,eMailDTE,esReceptorDTE,BloqueadoPro,Usuario,Sistema,Proceso,FechaUlMod)
			select	left( replace(replace(CIF,'.',''),'-','') ,8 ),NOMBRECLIENTE,'',CIF,'S',120,@comuna,@ciudad,DIRECCION1,
					TELEFONO1,'S','N','N','N','N','N','N',E_MAIL, @id_Region,0,0,0,0,0,E_MAIL,'S','N','IGC','IW','Traspaso AUT.ICG-Softland',GETDATE()
			FROM [BDMANVARSO].[dbo].[CLIENTES]
			where CODCLIENTE= @CODCLIENTE 

		end
		-- clientes

		---------------------------
		--3.21° Compruebo CLIENTES
		IF NOT EXISTS(SELECT * 
					  FROM BVARSOVIENNE.softland.cwtauxi AS b with (nolock) 
					  where b.CodAux = @nrorut COLLATE DATABASE_DEFAULT ) --O sea, si no encuentra cliente
		BEGIN
			INSERT INTO Traspaso.Boletas_ErrorCliente ( NUMSERIEFAC,  NUMFAC,  NFAC,  CODCLIENTE ) 
                                               VALUES ( @NUMSERIEFAC, @NUMFAC, @NFAC, @CODCLIENTE )
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET errorTraspasoSoftland = ISNULL(errorTraspasoSoftland, '') + ' -Error CodCliente'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			  and FacturaElectronica = @FacturaElectronica
			-- marco errores
			set @error_cliente = 1;

		END	
		--FIN: 3.21° Compruebo CLIENTES
		---------------------------

		---------------------------
		--3.3° Compruebo Folio existente en Softland

		IF EXISTS (	SELECT * 
					FROM BVARSOVIENNE.softland.iw_gsaen AS a
					INNER JOIN GESTIONVARSO.Traspaso.Rel_Bodega_Almacen AS b ON b.CodBodeSoftland collate database_default = a.CodBode
					WHERE Tipo = 'F' 
					  AND Folio = @FolioSoftland 
					  AND b.CODALMACENICG = @CODALMACEN
					  AND a.DTE_SiiTDoc = 33 ) BEGIN
			--Marco error (considerar que ya puse false al estado)
			UPDATE GESTIONVARSO.Traspaso.Boletas 
			SET SeTraspasoSoftland = 1, 
				errorTraspasoSoftland = 'Error FACTURA ELEC. YA EXISTE EN SOFTLAND'
			WHERE NUMSERIEFAC = @NUMSERIEFAC 
              AND NUMFAC = @NUMFAC 
              AND NFAC = @NFAC
			  and FacturaElectronica = @FacturaElectronica
			-- marco errores
			set @error_folio = 1;

		END	
		--FIN: 3.3° Compruebo Folio existente en Softland
	
		----------------------------
		--3.4° Traspaso a Softland
		--Si llega hasta aquí quiere decir que estan todas las condiciones para efectuar el traspaso.
		if ( @error_articulo = 0 and @error_bod_cc = 0 and @error_vendedor = 0 and	@error_folio = 0  and @error_cliente = 0 ) 
		begin
			BEGIN TRANSACTION 
				begin try

					-- el nuevo NroInt de Softland
					SELECT @NroInt = ISNULL(MAX(NroInt) + 1,1) FROM BVARSOVIENNE.softland.iw_gsaen	WHERE Tipo = 'F'
					--print @NroInt
					--Inserto cabecera
					INSERT INTO	BVARSOVIENNE.softland.iw_gsaen
					(   Tipo, NroInt, CodBode, Folio,
						Concepto, CodAux,
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
					SELECT  'F', @NroInt, b.CodBodeSoftland, @FolioSoftland,
							'02',@nrorut,
							'V', a.FECHA,
							'AutICG*' + LEFT(ISNULL(b.DesBode,''),15),
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
							a.FECHACREACION, 0, 0, 0,
							0, 0, 0, 0,
							33, 0, 1, 0,  -- incluir factura electronicas generadas desde ICG . kinetik 29/06/2019
							0, 3,
							0, 0,
							'F'
					FROM BDMANVARSO.dbo.ALBVENTACAB                AS a with (nolock)
					INNER JOIN Traspaso.Rel_Bodega_Almacen         AS b with (nolock) ON b.CODALMACENICG = LEFT(@NUMSERIEFAC, 2)
					LEFT  JOIN BDMANVARSO.dbo.ALBVENTACAMPOSLIBRES AS c with (nolock) ON c.NUMSERIE = a.NUMSERIE AND c.NUMALBARAN = a.NUMALBARAN AND c.N = a.N
					LEFT  JOIN GESTIONVARSO.Traspaso.Rel_Vendedor  AS d with (nolock) ON d.CODVENDEDOR = a.CODVENDEDOR
					WHERE   (CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC  ELSE a.NUMSERIE       END ) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC       ELSE c.NUMERO_BOLETA  END ) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NFAC         ELSE a.N              END ) = @NFAC
					-- print 'pasamos encabezado'
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
						'F', @NroInt, b.NUMLIN, c.CODBARRAS, e.CodBodeSoftland,
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
					WHERE   (CASE WHEN a.TIPODOC in (24) THEN a.NUMSERIEFAC ELSE a.NUMSERIE END) = @NUMSERIEFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NUMFAC ELSE f.NUMERO_BOLETA END) = @NUMFAC 
						AND (CASE WHEN a.TIPODOC in (24) THEN a.NFAC ELSE a.N END) = @NFAC
					-- print 'pasamos detalle'
					-- traspaso efectuado
					UPDATE GESTIONVARSO.Traspaso.Boletas 
					SET SeTraspasoSoftland = 1,
						errorTraspasoSoftland = NULL
					WHERE NUMSERIEFAC = @NUMSERIEFAC 
						AND NUMFAC = @NUMFAC 
						AND NFAC = @NFAC
						and FacturaElectronica = @FacturaElectronica
					--print 'listos !!!'

					COMMIT TRANSACTION
				end try
				begin catch
					ROLLBACK TRANSACTION
                    -- print 'afuera '+@NUMSERIEFAC+' '+cast(@FolioSoftland as varchar(20) )
					--
					set @xerr_desc	= left( ERROR_MESSAGE(), 200 )
					UPDATE GESTIONVARSO.Traspaso.Boletas 
					SET SeTraspasoSoftland = 0,
						errorTraspasoSoftland = @xerr_desc
					WHERE NUMSERIEFAC = @NUMSERIEFAC 
						AND NUMFAC = @NUMFAC 
						AND NFAC = @NFAC
						and FacturaElectronica = @FacturaElectronica
					--
				end catch

		end;

		--FIN:3.4° Traspaso a Softland
		----------------------------
		fetch next from detalle_cursor
		into @NUMSERIEFAC, @NUMFAC, @NFAC, @FolioSoftland, @CODALMACEN, @CODVENDEDOR, @CODCLIENTE, @BoletaFiscal, @FacturaElectronica
		--
	END;
	
	close detalle_cursor  
	deallocate detalle_cursor  

	--FIN: 3° Proceso recorriendo cada boleta
	-------------------------------------------------
	
	--Habilito triggers conflictivos por APP_NAME() que se guarda en un varchar chico de 50, problema de programática gente Softland.
	ALTER TABLE BVARSOVIENNE.softland.iw_gsaen ENABLE TRIGGER IW_GSaEnVW_ITRIG
	
END;

