/*
exec ksp_GT_imprimir 1131835,1097310 ;
*/

IF OBJECT_ID('ksp_GT_imprimir', 'P') IS NOT NULL DROP PROCEDURE ksp_GT_imprimir;  
GO  
CREATE PROCEDURE ksp_GT_imprimir ( @nroint int, @folio int ) 
With Encryption
AS
BEGIN
	--
	set nocount on

	-- no existe? se crea
	if not exists ( select * from dbo.sysobjects where id = object_id(N'[dbo].[ktb_lineas_FBG]') and OBJECTPROPERTY(id, N'IsUserTable') = 1) begin 
		create table ktb_lineas_FBG ( 
			id		int not null, 
			folio	int not null, 
			linea	int, 
			dato	varchar(250) ); 
	end;
	--

	if not exists ( select * from ktb_lineas_FBG where id = @nroint  and folio = @folio ) begin

		-- encabezado
		declare @linea			int = 0,
				@tido			char(3),
				@nudo			char(10),
				@endo			char(13),
				@feemdo			char(10),
				@feulvedo		char(10),
				@rut			char(10),
				@destino		varchar(70),
				@razon			varchar(50),
				@giro			varchar(50),
				@direccion		varchar(80),
				@comuna			varchar(50),
				@ciudad			varchar(50),
				@occ			varchar(20),
				@fono			varchar(20),
				@tipoen			char(1),
				@rubro			varchar(50),		
				@zona			varchar(50),		
				@contacto		varchar(50),		
				@condiciones	varchar(50),		
				@sucursal		varchar(50),	
				@vendedor		varchar(20),
				@nombreven		varchar(50),
				@docprevios		varchar(80),
				@obs			varchar(120),
				@placapat		varchar(20),
				@diendesp		varchar(13),
				@fileOut		varchar(100),
				@impuestos		decimal(11,0),
				@neto			decimal(11,0),
				@iva			decimal(11,0),
				@bruto			decimal(11,0),
				@codigovarso    varchar(10) = '81013400';  
		--
		select	@fileOut		= replace('GDV' + ltrim(rtrim(cast(edo.Folio as varchar(20)))) + ltrim(rtrim(edo.CodAux)),' ', '') + '.txt',
				@tido			= 'GDV', 
				@nudo			= edo.Folio,
				@endo			= ltrim(rtrim(replace((select top 1 CodAux from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso),'.',''))),
				@feemdo			= convert( char(10), edo.Fecha, 103 ),
				@feulvedo		= convert( char(10), edo.Fecha, 103 ),
				@rut			= ltrim(rtrim(replace((select top 1 RutAux from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso),'.',''))),
				@razon			= left(( select top 1 NomAUx from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso ),70),
				@giro			= 'COMERCIO',
				@direccion		= ( select top 1 rtrim(DirAux) +' ' +rtrim(DirNum) from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso ),
				@comuna			= ( select ComDes FROM softland.cwtcomu where ComCod=(select top 1 ComAux from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso) ),
				@ciudad			= ( select CiuDes FROM softland.cwtciud where CiuCod=(select top 1 CiuAux from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso) ),
				@occ			= '',
				@destino		= left(en.NomAUx,70),
				@fono			= ( select top 1 rtrim(FonAux1) from BVARSOVIENNE.softland.cwtauxi where CodAux=@codigovarso ),
				@tipoen			= '',
				@rubro			= '',
				@zona			= '',
				@contacto		= '',
				@condiciones	= 'Traslado entre sucursales',
				@sucursal		= edo.CodBode,
				@vendedor		= edo.Usuario,
				@nombreven		= edo.Usuario,  /* coalesce(( select nombre FROM ktb_usuarios_vista_web where id = edo.Usuario ),''), */
				@docprevios		= '',
				@placapat		= '',
				@obs			= 'Nro.Interno: '+ltrim(rtrim(cast( @nroint as varchar(20) ))),
				@neto			= 0,  -- edo.NetoAfecto,
				@iva			= 0,  -- edo.IVA,
				@impuestos		= 0,
				@bruto			= 0   -- edo.Total
		from BVARSOVIENNE.softland.iw_gsaen		as edo	with (nolock)
		left join BVARSOVIENNE.softland.cwtauxi	as en	with (nolock) on en.CodAux = edo.CodAux
		WHERE edo.NroInt = @nroint
		  and edo.Folio = @folio
		  and edo.Tipo = 'S';
		-- exec ksp_GT_imprimir 1029190,3160263 ;

		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @tido);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @nudo);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @feemdo );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @feulvedo);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @rut);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @endo);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @razon);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @direccion);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @fono );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @comuna );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @ciudad );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @giro);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @destino);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @nombreven);
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @sucursal );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '' ); /* codigo de sucursal tributaria  */
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '5');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, cast( @neto AS varchar(13) ) );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, cast( @iva AS varchar(13) ) );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, cast( @bruto AS varchar(13) ) );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, @obs );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, 'Li' );
		set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, @linea, '');

		-- detalle
		declare @nulido			char(3),
				@codigo			varchar(13),
				@descripcion	varchar(50),
				@cantidad		decimal(18,3),
				@unidad			varchar(6),
				@precioneto		decimal(18,2),
				@xprecioneto	varchar(13),
				@netolinea		decimal(18,2),
				@xnetolinea		varchar(13),
				@porcedesc		decimal(18,3),
				@xporcedesc		varchar(13),
				@valordesc		decimal(18,2),
				@xvalordesc		varchar(13),
				@xTotal			char(13),
				@npos			int	=	33,    /* linea inicial */
				@laLinea		char(400);
		--
		declare detalle_cursor cursor forward_only static read_only 
		for 
		select	ddo.linea as nulido, ddo.CodProd as codigo, coalesce(pr.DesProd,ddo.CodProd,'') as descripcion, 
				ddo.CantDespachada as cantidad, ddo.CodUMed as unidad,
				ddo.PreUniMB as precioneto, ddo.TotLinea as netolinea,
				ddo.PorcDescMov01 as porcedesc, ddo.DescMov01 as valordesc
		from softland.iw_gmovi as ddo with (nolock)
		left join softland.iw_tprod  as pr on pr.CodProd = ddo.CodProd
		where ddo.NroInt = @nroint
		  and ddo.Tipo = 'S'
		order by ddo.linea;
		--
		open detalle_cursor  
		--
		fetch next from detalle_cursor 
		into @nulido,@codigo,@descripcion,@cantidad,@unidad,@precioneto,@netolinea,@porcedesc,@valordesc	
		--
		while @@FETCH_STATUS = 0 begin
			--
			set @npos += 1 ;
			-- 
			set @xprecioneto = cast( 0 as varchar(11) ); -- @precioneto
			set @xporcedesc	 = cast( 0 as varchar(20) ); -- @porcedesc	
			set @xvalordesc	 = cast( 0 as varchar(20) ); -- @valordesc 
			set @xTotal		 = cast( 0 as varchar(20) ); -- @netolinea 
			--
			set @laLinea =	right( '00'+ ltrim(rtrim(cast(@nulido as varchar(3)))),2 )	+ replicate(' ',3)+
							left(@codigo+space(13),13)									+ 
							left(@descripcion+space(61),61)								+ 
							str( @cantidad, 11, 3 )										+ ' ' +
							left(@unidad+space(4),4)									+
							@xprecioneto												+ space(1)+
							@xporcedesc													+ space(1)+
							@xvalordesc													+ space(1)+
							@xTotal;
			--
			set @linea += 1; insert into ktb_lineas_FBG (id, folio, linea, dato) values ( @nroint, @folio, rtrim(@linea), @laLinea );
			--
			fetch next from detalle_cursor 
			into @nulido,@codigo,@descripcion,@cantidad,@unidad,@precioneto,@netolinea,@porcedesc,@valordesc
			--
		end;
		--
		close detalle_cursor
		deallocate detalle_cursor
		-- pruebas:  select * from ktb_lineas_FBG;

		declare @comando	VARCHAR(MAX),
				@carpeta	VARCHAR(512) = 'C:\InputTXT\',
				@x1			char(4)		 = 'GDV_',
				@x2			float		 = RAND(),
				@x3			varchar(100) = '',
				@table		varchar(100),
				@query		NVARCHAR(2500);
		-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	end
	--
	set @query = concat( 'select linea,dato from ktb_lineas_FBG where id = ',cast( @nroint as varchar ), ' and folio = ',cast( @folio as varchar ), ' order by linea ;' ); 
	EXECUTE sp_executesql @query ;
	--
END;
go
-- 




