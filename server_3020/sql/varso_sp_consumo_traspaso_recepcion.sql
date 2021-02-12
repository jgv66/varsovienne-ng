Use BVARSOVIENNE
go

-- exec ksp_causaconsumo
IF OBJECT_ID('ksp_causaconsumo', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_causaconsumo;  
GO  
CREATE PROCEDURE ksp_causaconsumo 
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	select causal,descripcion 
	from ktb_causales_de_consumo with (nolock) 
	order by causal ;
	--
END;
go

-- exec ksp_locales ;
IF OBJECT_ID('ksp_locales', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_locales;  
GO  
CREATE PROCEDURE ksp_locales
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    SELECT CodBode,DescCC,CodiCC 
	FROM ARE_BodComi with (nolock) 
	order by DescCC ;
	--
END;
go

-- exec ksp_localesxusuario 14 ;
IF OBJECT_ID('ksp_localesxusuario', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_localesxusuario;  
GO  
CREATE PROCEDURE ksp_localesxusuario ( @id int )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select u.id, u.id_padre, u.CodBode, b.DescCC
    from ktb_usuario_local_vista_web as u  with (nolock)
    inner join ARE_BodComi as b with (nolock) on b.CodBode = u.CodBode
    where u.id_padre = @id
    order by b.DescCC ;
	--
END;
go

-- exec ksp_stockProd '100100' ;
IF OBJECT_ID('ksp_stockProd', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_stockProd;  
GO  
CREATE PROCEDURE ksp_stockProd ( @codigo varchar(20) )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select s.*,coalesce(b.DescCC,cast('n/n' as varchar(60))) as DescCC
    from ARE_StockxBodega as s with (nolock)
    inner join ARE_BodComi as b with (nolock) on b.CodBode = s.CodBode
    where s.CodProd = @codigo
    order by b.DescCC ;
	--
END;
go

-- exec ksp_updateFolio ;
IF OBJECT_ID('ksp_updateFolio', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_updateFolio;  
GO  
CREATE PROCEDURE ksp_updateFolio ( @folio int, @desde int, @hasta int, @bodega varchar(10) )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	update ktb_folio_x_bodega set folio=@folio, foliodesde=@desde, foliohasta=@hasta where bodega = @bodega ;
	--
END;
go

-- exec ksp_folios ;
-- exec ksp_folios 'AGUS' ;
IF OBJECT_ID('ksp_folios', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_folios;  
GO  
CREATE PROCEDURE ksp_folios ( @xnombre varchar(20) = '' )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	if ( @xnombre = '' ) begin
		--
		select fb.*,bod.DescCC as local 
		from ktb_folio_x_bodega as fb with (nolock) 
		left join ARE_BodComi as bod with (nolock) on bod.CodBode = fb.bodega 
		order by local ; 
		--
	end
	else begin
		--
		select fb.*,bod.DescCC as local 
		from ktb_folio_x_bodega as fb with (nolock) 
		left join ARE_BodComi as bod with (nolock) on bod.CodBode = fb.bodega 
		where upper(bod.DescCC) like '%' + @xnombre + '%' 
		order by local ; 
		--
	end;
	--
END;
go

-- exec ksp_centrodecosto 'B'
IF OBJECT_ID('ksp_centrodecosto', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_centrodecosto;  
GO  
CREATE PROCEDURE ksp_centrodecosto ( @bodega varchar(10) = '' )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	select	cc.DescCC, cc.CodiCC, 
			(select top 1 VenCod 
			 from softland.cwtvend as vend with (nolock) 
			 where cc.DescCC = vend.VenDes) as VenCod 
    from ARE_BodComi as cc with (nolock) 
    where cc.CodBode = @bodega ; 
	--
END;
go

-- exec ksp_auxiliares ;
IF OBJECT_ID('ksp_auxiliares', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_auxiliares;  
GO  
CREATE PROCEDURE ksp_auxiliares
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select CodAux, NomAux 
	from softland.cwtauxi with (nolock)
	where UPPER(NomAux) like '%VARSOVIENNE%'
    order by NomAux;
	--
END;
go

-- exec ksp_usuarios 'norte' ;
IF OBJECT_ID('ksp_usuarios', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_usuarios;  
GO  
CREATE PROCEDURE ksp_usuarios ( @xnombre varchar(20) = '' )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	if ( @xnombre = '' ) begin 
		select id, nombre, email, code, convert( nvarchar(10),creacion,103) as creacion, codigo_softland, supervisor, admin 
		from ktb_usuarios_vista_web with (nolock) 
		order by nombre ;
	end
	else begin
		select id, nombre, email, code, convert( nvarchar(10),creacion,103) as creacion, codigo_softland, supervisor, admin 
		from ktb_usuarios_vista_web with (nolock) 
		where upper(nombre) like '%' + @xnombre + '%' 
		order by nombre ;
	end;
	--
END;
go

-- exec ksp_leerGuias '20200101','20200331','B','S','02' ;
IF OBJECT_ID('ksp_leerGuias', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_leerGuias;  
GO  
CREATE PROCEDURE ksp_leerGuias ( @fechaini date, @fechafin date, @local varchar(10), @xtipo char(1), @tipodoc varchar(10) )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select top 100 Tipo as tipo, NroInt as nroint, CodBode as codbode, Folio as folio, Concepto as concepto,
            case when Concepto = '07' then 'Consumo   '
				 when Concepto = '06' then 'Traslado  '
				 when Concepto = '03' then 'Recepción '
				 else					   '???       '
            end as nombreconcepto, 
			Estado as estado, convert(nvarchar(10), Fecha, 103) as fecha, Glosa as glosa, Usuario as usuario, CentroDeCosto as ccosto, 
			CodBod as traslado, NetoAfecto as neto, Iva as iva, Total as total, cast(0 as bit) as spinn
    from softland.iw_gsaen with (nolock)
    where Fecha between @fechaini and @fechafin
      and CodBode = @local 
      and Tipo = @xtipo
      and Concepto = @tipodoc
    order by Fecha desc, NroInt desc;
	--
END;
go

-- ksp_getHeader 'E','20200331',321321 ;
IF OBJECT_ID('ksp_getHeader', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_getHeader;  
GO  
CREATE PROCEDURE ksp_getHeader ( @tipo char(1), @folio varchar(10), @nroint int )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select doc.Tipo as tipo, doc.NroInt as nroint, doc.Folio as folio, doc.CodBode as codbode,
		  (select top 1 cc.DescCC from ARE_BodComi as cc where cc.CodBode = doc.CodBode) as nomlocal, 
		  doc.Concepto as concepto, doc.Estado as estado, convert(nvarchar(10), doc.Fecha, 103) as fecha,
		  doc.Glosa as glosa, doc.Usuario as usuario, doc.CentroDeCosto as ccosto, doc.CodBod as traslado,
		  (select top 1 cc.DescCC from ARE_BodComi as cc where cc.CodBode = doc.CodBod) as nomtraslado,
		  round(doc.NetoAfecto, 0) as neto, round(doc.Iva, 0) as iva, round(doc.Total, 0) as total, 
		  (case when k.descConcepto is not null then k.descConcepto 
				when doc.Concepto = '07' then 'Consumo Interno '
				when doc.Concepto = '06' then 'Traslado entre Bodegas'
				when doc.Concepto = '03' then 'Recepcion de Mercaderías'
				else '??????'
		   end) as descconcepto, k.ccosto, k.causal
    from softland.iw_gsaen as doc with (nolock)
    left join ktb_guia_encabezado as k with(nolock) on k.tipo = doc.tipo and k.folio = doc.folio and k.nrointerno = doc.NroInt
    where doc.Tipo = @tipo
      and doc.Folio = @folio
      and doc.NroInt = @nroint ;
	--
END;
go

IF OBJECT_ID('ksp_getDetail', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_getDetail;  
GO  
CREATE PROCEDURE ksp_getDetail ( @tipo char(1), @folio varchar(10), @nroint int )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	select d.CodProd as codigo, d.DetProd as descripcion, 
		   (case when e.Concepto = '03' then d.CantIngresada else d.CantDespachada end) as cantidad,
		   d.CodUMed as unidad, d.PreUniMB as precio, d.TotLinea as subtotal
	from softland.iw_gsaen as e with (nolock)
	inner join softland.iw_gmovi as d with (nolock) on d.Tipo = e.Tipo and e.NroInt = d.NroInt
	where e.Tipo = @tipo
	  and e.Folio = @folio
	  and e.NroInt = @nroint
	--
END;
go

-- exec ksp_rescatarTraslado '20200101',20200331,'B' ;
IF OBJECT_ID('ksp_rescatarTraslado', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_rescatarTraslado;  
GO  
CREATE PROCEDURE ksp_rescatarTraslado ( @folio int, @nrointerno int, @destino varchar(10) )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
    select a.*
    from ktb_guia_encabezado as a with (nolock)
    where a.folio = @folio
      and a.nrointerno = @nrointerno
      and a.destino = @destino
      and coalesce(a.traspasado, 0) = 1
      and coalesce(a.cerrado, 0) = 0
      and exists ( select *
		  		   from softland.iw_gsaen as b with (nolock) 
				   where b.Tipo = 'S'
				     and b.concepto = '06'
				     and b.Folio = a.folio 
					 and b.NroInt = a.nrointerno );
	--
END;
go

-- exec ksp_rescatarDetalle 321 ;
IF OBJECT_ID('ksp_rescatarDetalle', 'P') IS NOT NULL 
	DROP PROCEDURE ksp_rescatarDetalle;  
GO  
CREATE PROCEDURE ksp_rescatarDetalle ( @id int )
With Encryption
AS
BEGIN
	--
	set nocount on
	--
	select a.*, a.cantidad as cant_original, cast(0 as bit) as aceptado
	from ktb_guia_detalle as a with (nolock)
	where a.id_padre = @id
	order by a.id;
	--
END;
go

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  CONSUMO
IF OBJECT_ID('ksp_Leer_consumo_XML', 'P') IS NOT NULL  
	DROP PROCEDURE ksp_Leer_consumo_XML;  
GO  
CREATE PROCEDURE ksp_Leer_consumo_XML ( @xml XML ) With Encryption
AS
BEGIN
	--
    SET NOCOUNT ON;
	--
	declare @id_ktp		int = 0, 
            @folio		int = 0,
            @nroint		int = 0,
            @errNum		nvarchar(255),
            @errDesc	nvarchar(2550),
			@Error		nvarchar(250) , 
			@ErrMsg		nvarchar(2048), 
			@mydoc		xml,
			@i			int;

	-- <Encabezado>
	declare @t_enca table(	estado			bit				 NULL,
							bodega			varchar(10)		 NULL,
							destino			varchar(10)		 NULL,
							codigoauxi		varchar(20)		 NULL,
							recibida		bit				 NULL,
							fecharecepcion	datetime		 NULL,
							folio			varchar(20)		 NULL,
							nrointerno		int				 NULL,
							id_origen		int				 NULL,
							tipo			char(1)			 NULL,
							codigoSII		int				 NULL,
							electronico		bit				 NULL,
							tipoServSII		int				 NULL,
							concepto		varchar(2)		 NULL,
							descConcepto	varchar(50)		 NULL,
							causal			varchar(50)		 NULL,
							fecha			date			 NULL,
							glosa			varchar(255)	 NULL,
							ccosto			varchar(8)		 NULL,
							descCCosto		varchar(50)		 NULL,
							vendedor		varchar(4)		 NULL,
							usuario			int				 NULL,
							neto			decimal(18, 0)	 NULL,
							iva				decimal(18, 0)	 NULL,
							bruto			decimal(18, 0)	 NULL,
							ultimointento	datetime		 NULL,
							fecha_registro	datetime		 NULL,
							traspasado		bit				 NULL,
							cerrado			bit				 NULL,
							glosa_traspaso	varchar(255)	 NULL );
	-- <Detalle>
	declare @t_deta table(	id_padre		int				NULL,
							id_origen		int				NULL,
							linea			int				NULL,
							codigo			varchar(20)		NULL,
							descripcion		varchar(80)		NULL,
							cantidad		decimal(18, 3)	NULL,
							unidadMed		varchar(10)		NULL,
							netoUnitario	decimal(18, 2)	NULL,
							subTotal		decimal(18, 0)	NULL,
							traspasado		bit				NULL,
							glosa_traspaso	varchar(80)		NULL );
	--
	BEGIN TRY ;  

		-- traspasar el XML a una variable 
		set @mydoc = @xml;

		-- rescata los datos del XML y los prepara para ser leidos
		exec sp_xml_preparedocument @i output, @mydoc;

		-- <Encabezado>
		insert into @t_enca
		select * 
		from OPENXML(@i,'/Guia/Encabezado',2)
		WITH (	estado			bit				,
				bodega			varchar(10)		,
				destino			varchar(10)		,
				codigoauxi		varchar(20)		,
				recibida		bit				,
				fecharecepcion	datetime		,
				folio			varchar(20)		,
				nrointerno		int				,
				id_origen		int				,
				tipo			char(1)			,
				codigoSII		int				,
				electronico		bit				,
				tipoServSII		int				,
				concepto		varchar(2)		,
				descConcepto	varchar(50)		,
				causal			varchar(50)		,
				fecha			date			,
				glosa			varchar(255)	,
				ccosto			varchar(8)		,
				descCCosto		varchar(50)		,
				vendedor		varchar(4)		,
				usuario			int				,
				neto			decimal(18, 0)	,
				iva				decimal(18, 0)	,
				bruto			decimal(18, 0)	,
				ultimointento	datetime		,
				fecha_registro	datetime		,
				traspasado		bit				,
				cerrado			bit				,
				glosa_traspaso	varchar(255)	 );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 )
		begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		-- select * From @t_enca;
		--

		-- <Detalle>
		insert into @t_deta
		select * 
		from OPENXML(@i,'/Guia/Detalle',2)
		WITH (	id_padre		int				,
				id_origen		int				,
				linea			int				,
				codigo			varchar(20)		,
				descripcion		varchar(80)		,
				cantidad		decimal(18, 3)	,
				unidadMed		varchar(10)		,
				netoUnitario	decimal(18, 2)	,
				subTotal		decimal(18, 0)	,
				traspasado		bit				,
				glosa_traspaso	varchar(80)	    );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 ) begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		-- select * From @t_deta;
		--
        begin transaction
			--
			insert into ktb_guia_encabezado (estado, bodega, folio, nrointerno, codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, fecharecepcion, traspasado, cerrado, glosa_traspaso)
			select							 estado, bodega, 0,		0,          codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, null,     usuario, neto, iva, bruto, getdate(),	  getdate(),      traspasado, 0,	   glosa_traspaso
			from @t_enca;
			--
			select @id_ktp = @@IDENTITY;
			--
			if (@id_ktp > 0) begin
				insert into ktb_guia_detalle(id_padre, id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso)
				select						 @id_ktp,  id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso
				from @t_deta
				order by linea;
				--
			end;
			--
			update ktb_guia_encabezado set neto = (select sum(subTotal) from ktb_guia_detalle where id_padre = @id_ktp) where id = @id_ktp;
			update ktb_guia_encabezado set iva = round(neto * 0.19, 0) where id = @id_ktp;
			update ktb_guia_encabezado set bruto = neto + iva where id = @id_ktp;
			--
			exec ksp_graba_guia_consumo @id_ktp, @Error OUTPUT, @ErrMsg OUTPUT;
			--
			if (@Error <> 0) begin
				set @ErrMsg = left(@ErrMsg,2048);
				THROW @Error, @ErrMsg, 0;
			end;
			--
        commit transaction
        --
        select cast(1 as bit) as ok, cast(0 as bit) as error, 0 as err_num, '' as errDesc, folio, nrointerno as nroint from ktb_guia_encabezado with (nolock) where id = @id_ktp;
        --
	END TRY
	BEGIN CATCH
        --
        set @errNum = @@ERROR;
        set @errDesc = ERROR_MESSAGE();
        --
        if @@TRANCOUNT > 0 rollback transaction;
        select cast(0 as bit) as ok, cast(1 as bit) as error, @errNum as err_num, @errDesc as errDesc, 0 as folio, 0 as nroint;
        --
	END CATCH;
END;
go

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  TRASLADO
IF OBJECT_ID('ksp_Leer_traslado_XML', 'P') IS NOT NULL  
	DROP PROCEDURE ksp_Leer_traslado_XML;  
GO  
CREATE PROCEDURE ksp_Leer_traslado_XML ( @xml XML ) With Encryption
AS
BEGIN
	--
    SET NOCOUNT ON;
	--
	declare @id_ktp		int = 0, 
            @folio		int = 0,
            @nroint		int = 0,
            @errNum		nvarchar(255),
            @errDesc	nvarchar(2550),
			@Error		nvarchar(250) , 
			@ErrMsg		nvarchar(2048), 
			@mydoc		xml,
			@i			int;

	-- <Encabezado>
	declare @t_enca table(	estado			bit				 NULL,
							bodega			varchar(10)		 NULL,
							destino			varchar(10)		 NULL,
							codigoauxi		varchar(20)		 NULL,
							recibida		bit				 NULL,
							fecharecepcion	datetime		 NULL,
							folio			varchar(20)		 NULL,
							nrointerno		int				 NULL,
							id_origen		int				 NULL,
							tipo			char(1)			 NULL,
							codigoSII		int				 NULL,
							electronico		bit				 NULL,
							tipoServSII		int				 NULL,
							concepto		varchar(2)		 NULL,
							descConcepto	varchar(50)		 NULL,
							causal			varchar(50)		 NULL,
							fecha			date			 NULL,
							glosa			varchar(255)	 NULL,
							ccosto			varchar(8)		 NULL,
							descCCosto		varchar(50)		 NULL,
							vendedor		varchar(4)		 NULL,
							usuario			int				 NULL,
							neto			decimal(18, 0)	 NULL,
							iva				decimal(18, 0)	 NULL,
							bruto			decimal(18, 0)	 NULL,
							ultimointento	datetime		 NULL,
							fecha_registro	datetime		 NULL,
							traspasado		bit				 NULL,
							cerrado			bit				 NULL,
							glosa_traspaso	varchar(255)	 NULL );
	-- <Detalle>
	declare @t_deta table(	id_padre		int				NULL,
							id_origen		int				NULL,
							linea			int				NULL,
							codigo			varchar(20)		NULL,
							descripcion		varchar(80)		NULL,
							cantidad		decimal(18, 3)	NULL,
							unidadMed		varchar(10)		NULL,
							netoUnitario	decimal(18, 2)	NULL,
							subTotal		decimal(18, 0)	NULL,
							traspasado		bit				NULL,
							glosa_traspaso	varchar(80)		NULL );
	--
	BEGIN TRY ;  

		-- traspasar el XML a una variable 
		set @mydoc = @xml;

		-- rescata los datos del XML y los prepara para ser leidos
		exec sp_xml_preparedocument @i output, @mydoc;

		-- <Encabezado>
		insert into @t_enca
		select * 
		from OPENXML(@i,'/Guia/Encabezado',2)
		WITH (	estado			bit				,
				bodega			varchar(10)		,
				destino			varchar(10)		,
				codigoauxi		varchar(20)		,
				recibida		bit				,
				fecharecepcion	datetime		,
				folio			varchar(20)		,
				nrointerno		int				,
				id_origen		int				,
				tipo			char(1)			,
				codigoSII		int				,
				electronico		bit				,
				tipoServSII		int				,
				concepto		varchar(2)		,
				descConcepto	varchar(50)		,
				causal			varchar(50)		,
				fecha			date			,
				glosa			varchar(255)	,
				ccosto			varchar(8)		,
				descCCosto		varchar(50)		,
				vendedor		varchar(4)		,
				usuario			int				,
				neto			decimal(18, 0)	,
				iva				decimal(18, 0)	,
				bruto			decimal(18, 0)	,
				ultimointento	datetime		,
				fecha_registro	datetime		,
				traspasado		bit				,
				cerrado			bit				,
				glosa_traspaso	varchar(255)	 );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 )
		begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		-- select * From @t_enca;
		--

		-- <Detalle>
		insert into @t_deta
		select * 
		from OPENXML(@i,'/Guia/Detalle',2)
		WITH (	id_padre		int				,
				id_origen		int				,
				linea			int				,
				codigo			varchar(20)		,
				descripcion		varchar(80)		,
				cantidad		decimal(18, 3)	,
				unidadMed		varchar(10)		,
				netoUnitario	decimal(18, 2)	,
				subTotal		decimal(18, 0)	,
				traspasado		bit				,
				glosa_traspaso	varchar(80)	    );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 ) begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		-- select * From @t_deta;
		--
        begin transaction
			--
			insert into ktb_guia_encabezado (estado, bodega, destino, codigoauxi, folio, nrointerno, codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, fecharecepcion, traspasado, cerrado, glosa_traspaso)
			select							 estado, bodega, destino, codigoauxi, 0,	 0,          codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, null,     usuario, neto, iva, bruto, getdate(),	  getdate(),      traspasado,  0,		glosa_traspaso
			from @t_enca;
			--
			select @id_ktp = @@IDENTITY;
			--
			if (@id_ktp > 0) begin
				insert into ktb_guia_detalle(id_padre, id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso)
				select						 @id_ktp,  id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso
				from @t_deta
				order by linea;
				--
			end;
			--
			update ktb_guia_encabezado set neto = (select sum(subTotal) from ktb_guia_detalle where id_padre = @id_ktp) where id = @id_ktp;
			update ktb_guia_encabezado set iva = round(neto * 0.19, 0) where id = @id_ktp;
			update ktb_guia_encabezado set bruto = neto + iva where id = @id_ktp;
			--
            exec ksp_graba_guia_traslado @id_ktp, @Error OUTPUT, @ErrMsg OUTPUT;
			--
			if (@Error <> 0) begin
				set @ErrMsg = left(@ErrMsg,2048);
				THROW @Error, @ErrMsg, 0;
			end;
			--
			-- descomentar para ejemplos
			-- select @folio = folio, @nroint = nrointerno from ktb_guia_encabezado with (nolock) where id = @id_ktp;
			-- select * from BVARSOVIENNE.softland.iw_gsaen with (nolock) where NroInt=@nroint and Folio=@folio
			-- select * from ktb_guia_encabezado with (nolock) where id = @id_ktp;
			-- select 1/0;
			--
        commit transaction
        --
        select cast(1 as bit) as ok, cast(0 as bit) as error, 0 as err_num, '' as errDesc, folio, nrointerno as nroint from ktb_guia_encabezado with (nolock) where id = @id_ktp;
        --
	END TRY
	BEGIN CATCH
        --
        set @errNum = @@ERROR;
        set @errDesc = ERROR_MESSAGE();
        --
        if @@TRANCOUNT > 0 rollback transaction;
        select cast(0 as bit) as ok, cast(1 as bit) as error, @errNum as err_num, @errDesc as errDesc, 0 as folio, 0 as nroint;
        --
	END CATCH;
END;
go

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  RECEPCION
IF OBJECT_ID('ksp_Leer_recepcion_XML', 'P') IS NOT NULL  
	DROP PROCEDURE ksp_Leer_recepcion_XML;  
GO  
CREATE PROCEDURE ksp_Leer_recepcion_XML ( @xml XML ) With Encryption
AS
BEGIN
	--
    SET NOCOUNT ON;
	--
	declare @id_ktp		int = 0, 
            @folio		int = 0,
            @nroint		int = 0,
            @errNum		nvarchar(255),
            @errDesc	nvarchar(2550),
			@Error		nvarchar(250) , 
			@ErrMsg		nvarchar(2048), 
			@mydoc		xml,
			@i			int;

	-- <Encabezado>
	declare @t_enca table(	estado			bit				 NULL,
							bodega			varchar(10)		 NULL,
							destino			varchar(10)		 NULL,
							codigoauxi		varchar(20)		 NULL,
							recibida		bit				 NULL,
							fecharecepcion	datetime		 NULL,
							folio			varchar(20)		 NULL,
							nrointerno		int				 NULL,
							id_origen		int				 NULL,
							tipo			char(1)			 NULL,
							codigoSII		int				 NULL,
							electronico		bit				 NULL,
							tipoServSII		int				 NULL,
							concepto		varchar(2)		 NULL,
							descConcepto	varchar(50)		 NULL,
							causal			varchar(50)		 NULL,
							fecha			date			 NULL,
							glosa			varchar(255)	 NULL,
							ccosto			varchar(8)		 NULL,
							descCCosto		varchar(50)		 NULL,
							vendedor		varchar(4)		 NULL,
							usuario			int				 NULL,
							neto			decimal(18, 0)	 NULL,
							iva				decimal(18, 0)	 NULL,
							bruto			decimal(18, 0)	 NULL,
							ultimointento	datetime		 NULL,
							fecha_registro	datetime		 NULL,
							traspasado		bit				 NULL,
							cerrado			bit				 NULL,
							glosa_traspaso	varchar(255)	 NULL );
	-- <Detalle>
	declare @t_deta table(	id_padre		int				NULL,
							id_origen		int				NULL,
							linea			int				NULL,
							codigo			varchar(20)		NULL,
							descripcion		varchar(80)		NULL,
							cantidad		decimal(18, 3)	NULL,
							unidadMed		varchar(10)		NULL,
							netoUnitario	decimal(18, 2)	NULL,
							subTotal		decimal(18, 0)	NULL,
							traspasado		bit				NULL,
							glosa_traspaso	varchar(80)		NULL );
	--
	BEGIN TRY ;  

		-- traspasar el XML a una variable 
		set @mydoc = @xml;

		-- rescata los datos del XML y los prepara para ser leidos
		exec sp_xml_preparedocument @i output, @mydoc;

		-- <Encabezado>
		insert into @t_enca
		select * 
		from OPENXML(@i,'/Guia/Encabezado',2)
		WITH (	estado			bit				,
				bodega			varchar(10)		,
				destino			varchar(10)		,
				codigoauxi		varchar(20)		,
				recibida		bit				,
				fecharecepcion	datetime		,
				folio			varchar(20)		,
				nrointerno		int				,
				id_origen		int				,
				tipo			char(1)			,
				codigoSII		int				,
				electronico		bit				,
				tipoServSII		int				,
				concepto		varchar(2)		,
				descConcepto	varchar(50)		,
				causal			varchar(50)		,
				fecha			date			,
				glosa			varchar(255)	,
				ccosto			varchar(8)		,
				descCCosto		varchar(50)		,
				vendedor		varchar(4)		,
				usuario			int				,
				neto			decimal(18, 0)	,
				iva				decimal(18, 0)	,
				bruto			decimal(18, 0)	,
				ultimointento	datetime		,
				fecha_registro	datetime		,
				traspasado		bit				,
				cerrado			bit				,
				glosa_traspaso	varchar(255)	 );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 )
		begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		--select * From @t_enca;
		--

		-- <Detalle>
		insert into @t_deta
		select * 
		from OPENXML(@i,'/Guia/Detalle',2)
		WITH (	id_padre		int				,
				id_origen		int				,
				linea			int				,
				codigo			varchar(20)		,
				descripcion		varchar(80)		,
				cantidad		decimal(18, 3)	,
				unidadMed		varchar(10)		,
				netoUnitario	decimal(18, 2)	,
				subTotal		decimal(18, 0)	,
				traspasado		bit				,
				glosa_traspaso	varchar(80)	    );  
		--
		set  @Error = @@ERROR
		if ( @Error <> 0 ) begin
			set @ErrMsg = ERROR_MESSAGE();
			THROW @Error, @ErrMsg, 0 ;  
		end				
		--
		--select * From @t_deta;
		--
		--
        begin transaction
			--
			insert into ktb_guia_encabezado (estado, bodega, destino, codigoauxi, folio, nrointerno, id_origen, codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, fecharecepcion, traspasado, cerrado, glosa_traspaso)
			select							 estado, bodega, destino, codigoauxi, 0,	 0,          id_origen, codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, null,     usuario, neto, iva, bruto, getdate(),	  getdate(),      traspasado,  0,		glosa_traspaso
			from @t_enca;
			/*
            insert into ktb_guia_encabezado (estado, bodega, folio, codigoSII, electronico, tipo, id_origen, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, traspasado, cerrado, glosa_traspaso)
                                      values(0, '${enca.bodega}', '${ enca.folio }', $ { enca.codigoSII }, 0, '${ enca.tipo }', $ { enca.id_origen }, $ { enca.tipoServSII }, '${ enca.concepto }', '${ enca.descConcepto }', '${enca.causal}', '${enca.fecha}', '${enca.glosa}', '${ enca.ccosto ? enca.ccosto : "CO-00001" }', '${enca.descCCosto}', null, $ { enca.usuario }, $ { enca.neto }, $ { enca.iva }, $ { enca.bruto }, getdate(), 1, 0, 'en traspaso');
			*/
			--
			select @id_ktp = @@IDENTITY;
			--
			if (@id_ktp > 0) begin
				insert into ktb_guia_detalle(id_padre, id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso)
				select						 @id_ktp,  id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso
				from @t_deta
				order by linea;
				--
			end;
			--
			update ktb_guia_encabezado set neto = (select sum(subTotal) from ktb_guia_detalle where id_padre = @id_ktp) where id = @id_ktp;
			update ktb_guia_encabezado set iva = round(neto * 0.19, 0) where id = @id_ktp;
			update ktb_guia_encabezado set bruto = neto + iva where id = @id_ktp;
			--
            exec ksp_graba_guia_recepcion @id_ktp, @Error OUTPUT, @ErrMsg OUTPUT;
			--
			if (@Error <> 0) begin
				set @ErrMsg = left(@ErrMsg,2048);
				THROW @Error, @ErrMsg, 0;
			end;
			--
			-- descomentar para ejemplos
			-- select @folio = folio, @nroint = nrointerno from ktb_guia_encabezado with (nolock) where id = @id_ktp;
			-- select * from BVARSOVIENNE.softland.iw_gsaen with (nolock) where NroInt=@nroint and Folio=@folio
			-- select * from ktb_guia_encabezado with (nolock) where id = @id_ktp;
			-- select 1/0;
			--
        commit transaction
        --
        select cast(1 as bit) as ok, cast(0 as bit) as error, 0 as err_num, '' as errDesc, folio, nrointerno as nroint from ktb_guia_encabezado with (nolock) where id = @id_ktp;
        --
	END TRY
	BEGIN CATCH
        --
        set @errNum = @@ERROR;
        set @errDesc = ERROR_MESSAGE();
        --
        if @@TRANCOUNT > 0 rollback transaction;
        select cast(0 as bit) as ok, cast(1 as bit) as error, @errNum as err_num, @errDesc as errDesc, 0 as folio, 0 as nroint;
        --
	END CATCH;
END;
go

