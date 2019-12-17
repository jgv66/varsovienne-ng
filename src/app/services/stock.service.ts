import { environment } from '../../environments/environment';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map } from 'rxjs/operators';
import { ClassField } from '@angular/compiler';

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

  retieveCausales() {
    const xUrl = this.API_URL + '/causalesConsumo' ;
    return this.http.get( xUrl );
  }

  retieveAuxiliares() {
    const xUrl = this.API_URL + '/auxiliares' ;
    return this.http.get( xUrl );
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

  getFolio( pTipo:string, pConcepto: string, pBodega: string ) {
    const xUrl = this.API_URL + '/proximoFolio' ;
    const body = { tipo: pTipo, concepto: pConcepto, bodega: pBodega };
    return this.http.post( xUrl, body );
  }

  retrieveTraslado( pBodega: string, ptipo: string, pfolio: number, pNroInterno: number ) {
    const xUrl = this.API_URL + '/rescatarTraslado' ;
    return this.http.post( xUrl, { bodega: pBodega } );
  }
}
