import { environment } from '../../environments/environment';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
// import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class GuiasService {

  API_URL: string;

  constructor(private http: HttpClient) {
    this.API_URL = environment.API_URL;
  }

  retrieveStock(bodega?: string, soloConStock?: boolean) {
    const xUrl = this.API_URL + '/stock' ;
    return this.http.post( xUrl, { bodega, soloConStock } );
  }

  retrieveBodegas() {
    const xUrl = this.API_URL + '/bodegas' ;
    return this.http.get( xUrl );
  }

}
