//
var pdfs = require('html-pdf');
var path = require('path');
// var fs = require('fs');

publicpath = path.resolve(__dirname, 'public');
CARPETA_PDF = publicpath + '/pdf/';

module.exports = {
    //
    PDFDoc: function(resultado) {
        //
        return new Promise((resolve, reject) => {

            var enca = resultado.enca[0];
            var deta = resultado.deta;
            //
            xhoy = new Date();
            hora = xhoy.getHours().toString();
            minu = xhoy.getMinutes().toString();
            // shortname = 'GDV.pdf';
            shortname = `GDV_${ enca.folio.toString() }_${ enca.nroint.toString() }_${ hora }_${ minu }.pdf`;
            filename = path.join(CARPETA_PDF, shortname);
            //
            var contenido = `                       
                            <html>
                                <head>
                                    <meta charset="utf-8">
                                    <style>
                                        html, body { font-size: 14px; }
                                        table { width: 100%; font-size: 7px;  }
                                        thead { color: white; background: #565252; }
                                        tbody { color: black; }
                                        td,th { border: 1px; padding: 5px; }
                                        tfoot { color: red; }
                                    </style>
                                </head>
                                <body>
                                    <h3 style="text-align: center;">${ enca.descconcepto }</h3>
                                    <h3 style="text-align: center;">Folio : ${ enca.folio } - Nro.Interno : ${ enca.nroint }</h3>
                                    <hr><br>
                                    <!-- encabezado -->
                                    <table>
                                        <tbody>
                                            <tr>
                                                <td width="15%" align="left">Local</td>
                                                <td width="40%" align="left" style="font-weight: bold;">${ enca.nomlocal }</td width="15%" align="left">
                                                <td width="15%" align="right">Fecha : </td>
                                                <td width="15%" align="left" style="font-weight: bold;">${ enca.fecha }</td>
                                                <td>&nbsp;</td>
                                            </tr>
                                            <tr>
                                                <td width="15%" align="left">Centro de Costo</td>
                                                <td width="60%" align="left" style="font-weight: bold;">${ enca.ccosto }</td>
                                                <td width="15%" align="right">Usuario : </td>
                                                <td width="15%" align="left" style="font-weight: bold;">${ enca.usuario }</td>
                                                <td>&nbsp;</td>
                                            </tr>
                                            <tr>
                                                <td width="15%" align="left">Glosa</td>
                                                <td width="60%" align="left" style="font-weight: bold;">${ enca.glosa }</td>
                                                <td>&nbsp;</td>
                                                <td>&nbsp;</td>
                                                <td>&nbsp;</td>
                                            </tr>                                            
                                        </tbody>
                                    </table>
                                    <!--  -->
                                    <br>
                                    <!-- detalle -->
                                    <table>
                                        <thead style="color:white;background: #565252;">
                                            <tr>
                                                <th width="12%" align="left">Código</th>
                                                <th width="49%" align="left">Producto</th>
                                                <th width="9%" align="right">Cantidad</th>
                                                <th width="5%" align="left">Unidad</th>
                                                <th width="10%" align="right">Precio</th>
                                                <th width="15%" align="right">SubTotal</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                        `;
            var linea = 0;
            deta.forEach(element => {
                ++linea;
                contenido += `
                                            <tr>
                                                <td width="12%" align="left" >${ element.codigo      }</td>
                                                <td width="49%" align="left" >${ element.descripcion }</td>
                                                <td width="9%" align="right" >${ element.cantidad    }</td>
                                                <td width="5%" align="left"  >${ element.unidad      }</td>
                                                <td width="10%" align="right">n/a</td>
                                                <td width="15%" align="right">n/a</td>
                                            </tr>
                            `;
            });
            contenido += `
                                        </tbody>

                                        <tfoot>
                                            <tr>
                                                <td>&nbsp;</td>
                                                <td>&nbsp;</td>
                                                <td>&nbsp;</td>
                                                <td>&nbsp;</td>
                                                <td style="font-weight: bold;">Neto</td>
                                                <td align="right" style="font-weight: bold;">n/a</td>
                                            </tr>
                                        </tfoot>                                                                   
                                    </table>
                                </body>
                            </html>
                            `;
            // 
            // console.log(contenido);
            //
            var options = {
                "format": 'A4',
                "header": { "height": "10mm" },
                "footer": { "height": "10mm" }
            };
            pdfs.create(contenido, options)
                .toFile(filename,
                    function(err, res) {
                        if (err) {
                            reject('error');
                            console.log(err);
                        } else {
                            console.log(res);
                            resolve(shortname);
                        }
                    });
        });
    },
};

/*
                                            -- <tr>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td style="font-weight: bold;">IVA</td>
                                            --     <td align="right" style="font-weight: bold;">${ enca.iva.toString() }</td>
                                            -- </tr>
                                            -- <tr>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td>&nbsp;</td>
                                            --     <td style="font-weight: bold;">Total</td>
                                            --     <td align="right" style="font-weight: bold;">${ enca.total.toString() }</td>
                                            -- </tr>
*/