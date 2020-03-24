import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { Router } from '@angular/router';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

@Component({
  selector: 'app-folios',
  templateUrl: './folios.component.html',
  styles: []
})
export class FoliosComponent implements OnInit {

  nombre = '';
  cargando = false;
  folios = [];
  actual = 0;
  desde  = 0;
  hasta  = 0;
  bodega = '';
  local  = '';

  constructor( public login: LoginService,
               private router: Router) {
  }

  ngOnInit() {
    if ( !this.login.usuario ) {
      this.router.navigate(['/login']);
    }
    this.consultaFolios();
  }

  consultaFolios() {
    this.cargando = true;
    this.folios = [];
    this.login.retrieveFolios( this.nombre )
        .subscribe( (resultado: any) => {
          this.folios = resultado.datos;
          this.cargando = false;
        });
  }

  modificarFolio( folio ) {
    this.local  = folio.local;
    this.bodega = folio.bodega;
    this.actual = folio.folio;
    this.desde  = folio.foliodesde;
    this.hasta  = folio.foliohasta;
  }

  grabarFolio() {
    this.cargando = true;
    this.login.saveFolio( this.bodega, this.actual, this.desde, this.hasta )
        .subscribe( (resultado: any) => {
          // console.log(resultado);
          if ( resultado.resultado === 'ok' ) {
            this.folios.forEach(element => {
              if ( this.bodega === element.bodega ) {
                element.folio       = this.actual;
                element.foliodesde  = this.desde;
                element.foliohasta  = this.hasta;
              }
              this.cargando = false;
              Swal.fire({
                icon: 'success',
                title: 'ATENCION',
                text: 'La grabación se realizó con éxito',
                footer: '<a href>ID: ' + this.bodega + ' </a>'
              });
            });
          } else {
            this.cargando = false;
            Swal.fire({
              icon: 'error',
              title: 'Cuidado...',
              text: 'La grabación no se pudo llevar a cabo. Corrija y reintente.',
              footer: '<a href>' + resultado.datos + '</a>'
            });
          }
        });
  }

}
