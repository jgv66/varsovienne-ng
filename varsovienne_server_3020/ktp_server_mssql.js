// console.log("hola mundo");
var express = require('express');
var app = express();
// configuracion
var sql = require('mssql');
var dbconex = require('./conexion_mssql.js');
var servicios = require('./k_serviciosweb.js');
var path = require('path');
//
app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
// 
var bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// servidor escuchando puerto 3020
var server = app.listen(3020, function() {
    console.log("Escuchando http en el puerto: %s", server.address().port);
});

publicpath = path.resolve(__dirname, 'public');
app.use('/static', express.static(publicpath));
CARPETA_PDF = publicpath + '/pdf/';
console.log(CARPETA_PDF);

// --------------------- end-points
app.post('/login',
    function(req, res) {
        //
        // console.log('/login', req.body);
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query("select * from ktb_usuarios_vista_web with (nolock) where email = '" + req.body.email + "' and code = '" + req.body.code + "' ;");
            })
            .then(resultado => {
                console.log(resultado);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/usuarios',
    function(req, res) {
        //
        var query = "exec ksp_usuarios ";
        if (req.body.nombre) {
            query += req.body.nombre.toUpperCase();
        }
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                // console.log(resultado);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/grabarUsuarios',
    function(req, res) {
        //
        var query =
            `if exists ( select * from ktb_usuarios_vista_web where id = ${ req.body.id } ) begin 
            update ktb_usuarios_vista_web 
            set nombre='${ req.body.nombre }',
                email='${ req.body.email }',
                code='${ req.body.pssw }',
                ultimo_acceso=getdate(),
                codigo_softland='${ req.body.xsoft }',
                supervisor=${ req.body.xsuper ? 1 : 0 },
                admin=${ req.body.admin ? 1 : 0 }
            where id = ${ req.body.id }
        end
        else begin
            insert into ktb_usuarios_vista_web (nombre,email,code,creacion,ultimo_acceso,codigo_softland,supervisor,admin) 
            values ('${ req.body.nombre }','${ req.body.email }','${ req.body.pssw }',getdate(),getdate(),
                    '${ req.body.xsoft }',${ req.body.xsuper ? 1 : 0 },${ req.body.admin ? 1 : 0 } )
        end ;`;
        //
        // console.log('/grabarUsuarios', query);
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                console.log(resultado);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/folios',
    function(req, res) {
        //
        if (req.body.nombre.toUpperCase() !== '') {
            query = "exec ksp_folios '" + req.body.nombre.toUpperCase() + "' ;";
        } else {
            query = "exec ksp_folios '' ;";
        }
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                console.log(resultado);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/updateFolio',
    function(req, res) {
        //
        var query = "exec ksp_updateFolio " + req.body.folio.toString() + "," + req.body.desde.toString() + "," + req.body.hasta.toString() + ",'" + req.body.bodega + "' ";
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                console.log(resultado);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/stock',
    function(req, res) {
        //
        // console.log('/stock', req.body);
        // 
        var conStock = '';
        if (req.body.soloConStock) {
            conStock = " and Stock > 0";
        }
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query("select * from ARE_StockxBodega where CodBode = '" + req.body.bodega + "' " + conStock + " order by CodProd ;");
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.get('/bodegas',
    function(req, res) {
        //
        // console.log('/bodegas');
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query("select * from ARE_BodComi order by DescCC ;");
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/productos',
    function(req, res) {
        //
        // console.log('/productos', req.body);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query("exec ksp_ListaDeProductos '" + req.body.buscando + "' ;");
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/stockProd',
    function(req, res) {
        //
        // console.log('/stockProd', req.body);
        var query = "exec ksp_stockProd '" + req.body.codigo + "' ";
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/locxuser',
    function(req, res) {
        //
        // console.log('/localesxusario', req.body);
        var query = "exec ksp_localesxusuario " + req.body.id.toString() + " ;";
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/locales',
    function(req, res) {
        //
        // console.log('/locales', req.body);
        var query = 'exec ksp_locales ;';
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/causaconsumo',
    function(req, res) {
        //
        // console.log('/causalesConsumo -> entrada');
        var query = "exec ksp_causaconsumo ;";
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                // console.log('/causalesConsumo -> respondiendo', resultado.recordset);
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/centrodecosto',
    function(req, res) {
        //
        var query = "exec ksp_centrodecosto '" + req.body.bodega + "' ;";
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                //
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

function segundos() {
    var fecha = new Date();
    var segundos = fecha.getSeconds();
    var milisecs = fecha.getMilliseconds();
    return [segundos, milisecs];
}

app.post('/proximoFolio',
    function(req, res) {
        //
        var query = `
            select f.*
                from ARE_FolDispGuiaxBod as f
            where f.Tipo = '${ req.body.tipo }'
            and f.Concepto = '${ req.body.concepto }'
            and f.CodBode = '${ req.body.bodega }';
            `;
        // console.log(query);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                // console.log(resultado);
                if (resultado.recordset[0].ok !== false) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/grabarGuiaDeConsumo',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        var xml = `<?xml version="1.0" encoding="ISO-8859-1"?>
                    <!-- kinetik.cl -->
                    <Guia>
                    <Encabezado>
                        <estado>0</estado>
                        <bodega>${enca.bodega}</bodega>
                        <folio>${enca.folio}</folio>             
                        <codigoSII>${enca.codigoSII}</codigoSII>
                        <electronico>${enca.electronico}</electronico>
                        <tipo>${enca.tipo}</tipo>
                        <tipoServSII>${enca.tipoServSII}</tipoServSII>
                        <concepto>${enca.concepto}</concepto>
                        <descConcepto>${enca.descConcepto}</descConcepto>
                        <causal>${enca.causal}</causal>
                        <fecha>${enca.fecha}</fecha>
                        <glosa>${enca.glosa}</glosa>
                        <ccosto>${enca.ccosto}</ccosto>
                        <descCCosto>${enca.descCCosto}</descCCosto>
                        <vendedor></vendedor>
                        <usuario>${enca.usuario}</usuario>
                        <neto>${ enca.neto }</neto>
                        <iva>${ enca.iva }</iva>
                        <bruto>${ enca.bruto }</bruto>
                        <fecha_registro></fecha_registro>
                        <traspasado>1</traspasado>
                        <cerrado>1</cerrado>
                        <glosa_traspaso>en traspaso</glosa_traspaso>
                   </Encabezado>
                   `;
        var xmld = '';
        var linea = 0;
        deta.forEach(d => {
            ++linea;
            xmld += `<Detalle>
                        <id_padre>0</id_padre>
                        <id_origen>0</id_origen>
                        <linea>${linea}</linea>   
                        <codigo>${d.codigo}</codigo>         
                        <descripcion>${d.descripcion}</descripcion>
                        <cantidad>${d.cantidad}</cantidad>           
                        <unidadMed>${d.unidadMed}</unidadMed>           
                        <netoUnitario>${d.netoUnitario}</netoUnitario>
                        <subTotal>${d.subTotal}</subTotal>            
                        <traspasado>0</traspasado>
                        <glosa_traspaso></glosa_traspaso>
                    </Detalle>
                    `;
        });
        // 
        var xquery = "exec ksp_Leer_consumo_XML '" + xml + xmld + "</Guia>' ;";
        //
        console.log(xquery);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(xquery);
            })
            .then(resultado => {
                // console.log('grabarGuiaDeConsumo -> ', resultado);
                if (resultado.recordset[0].ok === true) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR grabarGuiaDeConsumo -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });

app.post('/auxiliares',
    function(req, res) {
        //
        var query = "exec ksp_auxiliares ;";
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                res.json({ resultado: 'ok', datos: resultado.recordset });
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/grabarGuiaDeTraslado',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        if (enca.ccosto === undefined) {
            enca.ccosto = 'CO-00001';
            enca.descCCosto = 'ADMINISTRACION COMERCIAL';
        }
        //
        var xml = `<?xml version="1.0" encoding="ISO-8859-1"?>
                    <!-- kinetik.cl -->
                    <Guia>
                    <Encabezado>
                        <estado>0</estado>
                        <bodega>${enca.bodega}</bodega>
                        <destino>${enca.destino}</destino>
                        <codigoauxi>${enca.auxiliar}</codigoauxi>
                        <folio>${enca.folio}</folio>             
                        <codigoSII>${enca.codigoSII}</codigoSII>
                        <electronico>${enca.electronico}</electronico>
                        <tipo>${enca.tipo}</tipo>
                        <tipoServSII>${enca.tipoServSII}</tipoServSII>
                        <concepto>${enca.concepto}</concepto>
                        <descConcepto>${enca.descConcepto}</descConcepto>
                        <causal></causal>
                        <fecha>${enca.fecha}</fecha>
                        <glosa>${enca.glosa}</glosa>
                        <ccosto>${enca.ccosto}</ccosto>
                        <descCCosto>${enca.descCCosto}</descCCosto>
                        <vendedor>${enca.vendedor}</vendedor>
                        <usuario>${enca.usuario}</usuario>
                        <neto>${ enca.neto }</neto>
                        <iva>${ enca.iva }</iva>
                        <bruto>${ enca.bruto }</bruto>
                        <fecha_registro></fecha_registro>
                        <traspasado>1</traspasado>
                        <cerrado>1</cerrado>
                        <glosa_traspaso>en traspaso</glosa_traspaso>
                    </Encabezado>
                    `;
        var xmld = '';
        var linea = 0;
        deta.forEach(d => {
            ++linea;
            xmld += `<Detalle>
                        <id_padre>0</id_padre>
                        <id_origen>0</id_origen>
                        <linea>${linea}</linea>   
                        <codigo>${d.codigo}</codigo>         
                        <descripcion>${d.descripcion}</descripcion>
                        <cantidad>${d.cantidad}</cantidad>           
                        <unidadMed>${d.unidadMed}</unidadMed>           
                        <netoUnitario>${d.netoUnitario}</netoUnitario>
                        <subTotal>${d.subTotal}</subTotal>            
                        <traspasado>0</traspasado>
                        <glosa_traspaso></glosa_traspaso>
                    </Detalle>
                    `;
        });
        // 
        var xquery = "exec ksp_Leer_traslado_XML '" + xml + xmld + "</Guia>' ;";
        //
        console.log(xquery);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(xquery);
            })
            .then(resultado => {
                console.log('grabarGuiaDeTraslado -> ', resultado);
                if (resultado.recordset[0].ok !== false) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR grabarGuiaDeTraslado -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });

app.post('/G2Print',
    function(req, res) {
        //
        var queryE = "exec ksp_GT_imprimir " + req.body.nrointerno.toString() + ", " + req.body.folio.toString() + " ;";
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryE);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: 'Sin Datos' });
                }
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/rescatarTraslado',
    function(req, res) {
        //
        // console.log(req.body);
        var queryE = "exec ksp_rescatarTraslado " + req.body.folio.toString() + "," + req.body.nrointerno.toString() + ",'" + req.body.destino + "' ;";
        console.log(queryE);
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryE);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: 'Sin Datos' });
                }
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

app.post('/rescatarDetalle',
    function(req, res) {
        //
        var queryD = "exec ksp_rescatarDetalle " + req.body.id.toString() + " ;";
        console.log(queryD);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryD);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: 'Sin Datos' });
                }
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

//////////////////////////////////////////////////////////////////////////////////////////////////////
app.post('/testsave_json2sql_recep',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        console.log(query);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query("exec ksp_save_json2ing  '" + enca + "', '" + deta + "'; ");
            })
            .then(resultado => {
                console.log('testsave_json2sql_recep -> ', resultado);
                if (resultado.recordset[0].ok) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR testsave_json2sql_recep -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });
//////////////////////////////////////////////////////////////////////////////////////////////////////

app.post('/grabarGuiaDeRecepcion',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        // console.log('/grabarGuiaDeRecepcion', enca, deta);
        //
        if (enca.ccosto === undefined) {
            enca.ccosto = 'CO-00001';
            enca.descCCosto = 'ADMINISTRACION COMERCIAL';
        }
        //
        var xml = `<?xml version="1.0" encoding="ISO-8859-1"?>
                    <!-- kinetik.cl -->
                    <Guia>
                    <Encabezado>
                        <estado>0</estado>
                        <bodega>${enca.bodega}</bodega>
                        <destino>${enca.destino}</destino>
                        <codigoauxi>${enca.auxiliar}</codigoauxi>
                        <folio>${enca.folio}</folio>             
                        <codigoSII>${enca.codigoSII}</codigoSII>
                        <electronico>${enca.electronico}</electronico>
                        <tipo>${enca.tipo}</tipo>
                        <id_origen>${enca.id_origen}</id_origen>
                        <tipoServSII>${enca.tipoServSII}</tipoServSII>
                        <concepto>${enca.concepto}</concepto>
                        <descConcepto>${enca.descConcepto}</descConcepto>
                        <causal>${enca.causal}</causal>
                        <fecha>${enca.fecha}</fecha>
                        <glosa>${enca.glosa}</glosa>
                        <ccosto>${ enca.ccosto ? enca.ccosto : "CO-00001" }</ccosto>
                        <descCCosto>${enca.descCCosto}</descCCosto>
                        <vendedor></vendedor>
                        <usuario>${enca.usuario}</usuario>
                        <neto>${ enca.neto }</neto>
                        <iva>${ enca.iva }</iva>
                        <bruto>${ enca.bruto }</bruto>
                        <fecha_registro></fecha_registro>
                        <traspasado>1</traspasado>
                        <cerrado>0</cerrado>
                        <glosa_traspaso>en traspaso</glosa_traspaso>
                    </Encabezado>
                    `;
        var xmld = '';
        var linea = 0;
        deta.forEach(d => {
            ++linea;
            xmld += `<Detalle>
                        <id_padre>0</id_padre>
                        <id_origen>0</id_origen>
                        <linea>${linea}</linea>   
                        <codigo>${d.codigo}</codigo>         
                        <descripcion>${d.descripcion}</descripcion>
                        <cantidad>${d.cantidad}</cantidad>           
                        <unidadMed>${d.unidadMed}</unidadMed>           
                        <netoUnitario>${d.netoUnitario}</netoUnitario>
                        <subTotal>${d.subTotal}</subTotal>            
                        <traspasado>0</traspasado>
                        <glosa_traspaso></glosa_traspaso>
                    </Detalle>
                    `;
        });
        // 
        var xquery = "exec ksp_Leer_recepcion_XML '" + xml + xmld + "</Guia>' ;";
        //
        console.log(xquery);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(xquery);
            })
            .then(resultado => {
                console.log('grabarGuiaDeRecepcion -> ', resultado);
                if (resultado.recordset[0].ok) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR grabarGuiaDeRecepcion -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });

app.post('/leerGuias',
    function(req, res) {
        //
        var queryE = "exec ksp_leerGuias '" + req.body.fechaIni.replace(/-/g, '') + "','" + req.body.fechaFin.replace(/-/g, '') + "','" + req.body.local + "','" + ((req.body.tipoDoc === '03') ? 'E' : 'S') + "','" + req.body.tipoDoc + "' ; ";
        console.log(queryE);
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryE);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: 'Sin Datos' });
                }
            })
            .catch(err => {
                res.json({ resultado: 'error', datos: err });
                console.log(err);
            });
    });

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
app.post('/imprimirGuia',
    function(req, res) {
        //
        console.log('imprimirGuia->', req.body);
        getDatos(req.body)
            .then(resultado => {
                servicios.PDFDoc(resultado, CARPETA_PDF)
                    .then(file => {
                        res.json({ resultado: 'ok', datos: file });
                    })
                    .catch(err => {
                        res.json({ resultado: 'error', datos: err });
                    });

            });
        //
    });

let getDatos = async(body) => {
    const enca = await getHeader(body);
    const deta = await getDetail(body);
    return { enca, deta };
};
let getHeader = async(body) => {
    //
    return new Promise((resolve, reject) => {
        //
        var queryE = "exec ksp_getHeader '" + body.tipo + "','" + body.folio + "'," + body.nroint + "  ;";
        console.log(queryE);
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryE);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    resolve(resultado.recordset);
                } else {
                    reject(null);
                }
            })
            .catch(err => {
                reject(null);
                console.log(err);
            });
    });
};
let getDetail = (body) => {
    //
    return new Promise((resolve, reject) => {
        //
        var queryD = "exec ksp_getDetail '" + body.tipo + "','" + body.folio + "'," + body.nroint.toString() + " ;";
        console.log(queryD);
        //
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(queryD);
            })
            .then(resultado => {
                if (resultado.recordset.length > 0) {
                    resolve(resultado.recordset);
                } else {
                    reject(null);
                }
            })
            .catch(err => {
                reject(null);
                console.log(err);
            });
    });
};
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
/*
app.post('/grabarGuiaDeTraslado_1.0',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        if (enca.ccosto === undefined) {
            enca.ccosto = 'CO-00001';
            enca.descCCosto = 'ADMINISTRACION COMERCIAL';
        }
        // var queryE = 
        //     --
        //     set nocount on
        //     --
        //     declare @id_ktp int = 0,
        //         @folio int = 0,
        //         @nroint int = 0,
        //         @errNum nvarchar(255),
        //         @errDesc nvarchar(2550),
        //         @Error nvarchar(250),
        //         @ErrMsg nvarchar(2048),
        //         @texto varchar(20) = '';
        //     --
        //     begin
        //     try
        //     begin transaction
        //     --
        //     insert into ktb_guia_encabezado
        //         (estado, bodega, destino, codigoauxi, folio, codigoSII, electronico, tipo, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, traspasado, cerrado, glosa_traspaso)
        //     values(0, '${enca.bodega}', '${enca.destino}', '${enca.auxiliar}', '${ enca.folio }', $ { enca.codigoSII }, 1, '${ enca.tipo }', $ { enca.tipoServSII }, '${ enca.concepto }', '${ enca.descConcepto }', '${enca.causal}', '${enca.fecha}', '${enca.glosa}', '${enca.ccosto}', '${enca.descCCosto}', null, $ { enca.usuario }, $ { enca.neto }, $ { enca.iva }, $ { enca.bruto }, getdate(), 1, 0, 'en traspaso');
        //     --
        //     select @id_ktp = @ @IDENTITY;
        //     --
        //     if (@id_ktp > 0) begin###
        //     end;
        //     --
        //     update ktb_guia_encabezado set neto = (select sum(subTotal) from ktb_guia_detalle where id_padre = @id_ktp) where id = @id_ktp;
        //     update ktb_guia_encabezado set iva = round(neto * 0.19, 0) where id = @id_ktp;
        //     update ktb_guia_encabezado set bruto = neto + iva where id = @id_ktp;

        //     --se genera guia de traslado en softland
        //     exec ksp_graba_guia_traslado @id_ktp, @Error OUTPUT, @ErrMsg OUTPUT;
        //     --
        //     if (@Error < > 0) begin
        //     THROW @Error, @ErrMsg, 0;
        //     end

        //     --se obtienen los datos de los recien grabado
        //     select @folio = folio, @nroint = nrointerno from ktb_guia_encabezado where id = @id_ktp;
        //     --
        //     --
        //     commit transaction
        //     --
        //     select cast(1 as bit) as ok, cast(0 as bit) as error, 0 as err_num, ''
        //     as errDesc, @folio as folio, @nroint as nroint;
        //     --
        //     end
        //     try
        //     --
        //     begin
        //     catch
        //     --
        //     set @errNum = @ @error;
        //     set @errDesc = ERROR_MESSAGE();
        //     --
        //     if @ @trancount > 0 ROLLBACK TRANSACTION;
        //     select cast(0 as bit) as ok, cast(1 as bit) as error, @errNum as err_num, @errDesc as errDesc, 0 as folio, 0 as nroint;
        //     --
        //     end
        //     catch;
        //     ;
        // var queryD = '';
        var linea = 0;
        deta.forEach(element => {
            ++linea;
        //     queryD += 
        //     insert into ktb_guia_detalle
        //         (id_padre, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso)
        //     values(@id_ktp, $ { linea }, '${element.codigo}', '${element.descripcion}', $ { element.cantidad }, '${element.unidadMed}', '${element.netoUnitario}', '${element.subTotal}', 0, '');
        //     --
        //     ;
        // });
        // remplazar el ### con las inserciones de detalle 
        var query = queryE.replace('###', queryD);
        //
        console.log(query);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                console.log('grabarGuiaDeTraslado -> ', resultado);
                if (resultado.recordset[0].ok !== false) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR grabarGuiaDeTraslado -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });

app.post('/grabarGuiaDeRecepcion',
    function(req, res) {
        //
        var enca = JSON.parse(req.body.enca);
        var deta = JSON.parse(req.body.deta);
        //
        // console.log('/grabarGuiaDeRecepcion', enca, deta);
        //
        if (enca.ccosto === undefined) {
            enca.ccosto = 'CO-00001';
            enca.descCCosto = 'ADMINISTRACION COMERCIAL';
        }
        var queryE = 
            --
            set nocount on
            --
            declare @id_ktp int = 0,
                @folio int = 0,
                @nroint int = 0,
                @errNum nvarchar(255),
                @errDesc nvarchar(2550),
                @Error nvarchar(250),
                @ErrMsg nvarchar(2048);
            --
            begin
            try
            --
            begin transaction
            --
            insert into ktb_guia_encabezado
                (estado, bodega, folio, codigoSII, electronico, tipo, id_origen, tipoServSII, concepto, descConcepto, causal, fecha, glosa, ccosto, descCCosto, vendedor, usuario, neto, iva, bruto, fecha_registro, traspasado, cerrado, glosa_traspaso)
            values(0, '${enca.bodega}', '${ enca.folio }', $ { enca.codigoSII }, 0, '${ enca.tipo }', $ { enca.id_origen }, $ { enca.tipoServSII }, '${ enca.concepto }', '${ enca.descConcepto }', '${enca.causal}', '${enca.fecha}', '${enca.glosa}', '${ enca.ccosto ? enca.ccosto : "CO-00001" }', '${enca.descCCosto}', null, $ { enca.usuario }, $ { enca.neto }, $ { enca.iva }, $ { enca.bruto }, getdate(), 1, 0, 'en traspaso');
            --
            select @id_ktp = @ @IDENTITY;
            --
            if (@id_ktp > 0) begin###
            end;
            --
            update ktb_guia_encabezado set neto = (select sum(subTotal) from ktb_guia_detalle where id_padre = @id_ktp) where id = @id_ktp;
            update ktb_guia_encabezado set iva = round(neto * 0.19, 0) where id = @id_ktp;
            update ktb_guia_encabezado set bruto = neto + iva where id = @id_ktp;
            --
            exec ksp_graba_guia_recepcion @id_ktp, @Error OUTPUT, @ErrMsg OUTPUT;
            --
            if (@Error < > 0) begin
            THROW @Error, @ErrMsg, 0;
            end
            --
            commit transaction
            --
            select @folio = folio, @nroint = nrointerno from ktb_guia_encabezado where id = @id_ktp;
            --
            select cast(1 as bit) as ok, cast(0 as bit) as error, 0 as err_num, ''
            as errDesc, @folio as folio, @nroint as nroint;
            --
            end
            try
            --
            begin
            catch
            --
            set @errNum = @ @error;
            set @errDesc = ERROR_MESSAGE();
            --
            if @ @trancount > 0 rollback transaction;
            select cast(0 as bit) as ok, cast(1 as bit) as error, @errNum as err_num, @errDesc as errDesc, 0 as folio, 0 as nroint;
            --
            end
            catch;
            ;
        var queryD = '';
        var linea = 0;
        deta.forEach(element => {
            ++linea;
            queryD += 
            insert into ktb_guia_detalle(id_padre, id_origen, linea, codigo, descripcion, cantidad, unidadMed, netoUnitario, subTotal, traspasado, glosa_traspaso)
            values(@id_ktp, $ { element.id_origen }, $ { linea }, '${element.codigo}', '${element.descripcion}', $ { element.cantidad }, '${element.unidadMed}', '${element.netoUnitario}', '${element.subTotal}', 0, '');
            --
            ;
        });
        // 
        var query = queryE.replace('###', queryD);
        //
        console.log(query);
        // 
        sql.close();
        sql.connect(dbconex)
            .then(pool => {
                return pool.request()
                    .query(query);
            })
            .then(resultado => {
                console.log('grabarGuiaDeRecepcion -> ', resultado);
                if (resultado.recordset[0].ok) {
                    res.json({ resultado: 'ok', datos: resultado.recordset });
                } else {
                    res.json({ resultado: 'error', datos: resultado.recordset[0].errDesc });
                }
            })
            .catch(err => {
                console.log('ERROR grabarGuiaDeRecepcion -> ', err);
                res.json({ resultado: 'error', datos: err });
            });
    });



*/