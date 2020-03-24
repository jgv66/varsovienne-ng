import { environment } from '../../environments/environment';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class StockService {

  API_URL: string;

  constructor(private http: HttpClient) {
    this.API_URL = environment.API_URL;
  }

  retrieveBodegas() {
    const xUrl = this.API_URL + '/bodegas' ;
    return this.http.get( xUrl );
  }

  retrieveStock(bodega?: string, soloConStock?: boolean) {
    const xUrl = this.API_URL + '/stock' ;
    return this.http.post( xUrl, { bodega, soloConStock } );
  }

  retrieveCodigos( buscar?: string ) {
    const xUrl = this.API_URL + '/productos' ;
    return this.http.post( xUrl, { buscando: buscar } );
  }

  retrieveStockxProd( code?: string ) {
    const xUrl = this.API_URL + '/stockProd' ;
    return this.http.post( xUrl, { codigo: code } );
  }

  retrieveGuias( local: string, tipoDoc: string, fechaIni: Date, fechaFin: Date ) {
    const xUrl = this.API_URL + '/leerGuias' ;
    const body = { local, tipoDoc, fechaIni, fechaFin };
    return this.http.post( xUrl, body );
  }

  imprimirGuia( tipo, folio, nroint ) {
    const xUrl = this.API_URL + '/imprimirGuia' ;
    const body = { tipo, folio, nroint };
    return this.http.post( xUrl, body );
  }

  retieveAuxiliares() {
    const xUrl = this.API_URL + '/auxiliares' ;
    return this.http.post( xUrl, {} );
  }

  retieveCenCosto( pBodega: string ) {
    const xUrl = this.API_URL + '/centrodecosto' ;
    return this.http.post( xUrl, { bodega: pBodega } );
  }

  grabarGuiaDeConsumo( enca, deta ) {
    const xUrl = this.API_URL + '/grabarGuiaDeConsumo' ;
    const body = { enca: JSON.stringify(enca), deta: JSON.stringify(deta) };
    return this.http.post( xUrl, body );
  }

  grabarGuiaDeTraslado( enca, deta ) {
    const xUrl = this.API_URL + '/grabarGuiaDeTraslado' ;
    const body = { enca: JSON.stringify(enca), deta: JSON.stringify(deta) };
    return this.http.post( xUrl, body );
  }
  G2Print( nroint, folio ) {
    const xUrl = this.API_URL + '/G2Print' ;
    const body = { nrointerno: nroint, folio };
    return this.http.post( xUrl, body );
  }

  getFolio( pTipo: string, pConcepto: string, pBodega: string ) {
    const xUrl = this.API_URL + '/proximoFolio' ;
    const body = { tipo: pTipo, concepto: pConcepto, bodega: pBodega };
    return this.http.post( xUrl, body );
  }

  retrieveTraslado( pDestino: string, ptipo: string, pfolio: number, pNroInterno: number ) {
    const xUrl = this.API_URL + '/rescatarTraslado' ;
    return this.http.post( xUrl, { destino: pDestino, tipo: ptipo, folio: pfolio, nrointerno: pNroInterno } );
  }

  retrieveDetalle( pId: number ) {
    const xUrl = this.API_URL + '/rescatarDetalle' ;
    return this.http.post( xUrl, { id: pId } );
  }

  grabarGuiaDeRecepcion( enca, deta ) {
    const xUrl = this.API_URL + '/grabarGuiaDeRecepcion' ;
    const body = { enca: JSON.stringify(enca), deta: JSON.stringify(deta) };
    return this.http.post( xUrl, body );
  }

}
