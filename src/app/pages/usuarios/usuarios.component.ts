import { Component, OnInit, ɵCodegenComponentFactoryResolver } from '@angular/core';
import { Router } from '@angular/router';
import { LoginService } from '../../services/login.service';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

@Component({
  selector: 'app-usuarios',
  templateUrl: './usuarios.component.html',
  styles: []
})
export class UsuariosComponent implements OnInit {

  cargando = false;
  usuarios = [];
  nombre   = '';
  xid      = 0;
  xnomb    = '';
  xmail    = '';
  xpssw    = '';
  xsoft    = '';
  xsuper   = false;
  xadmin   = false;

  constructor( private login: LoginService,
               private router: Router ) {}

  ngOnInit() {
    if ( !this.login.usuario ) {
      this.router.navigate(['/login']);
    }
    this.consultaUsuario();
  }

  consultaUsuario() {
    this.cargando = true;
    this.usuarios = [];
    this.login.retrieveUsuarios( this.nombre )
        .subscribe( (resultado: any) => {
          this.usuarios = resultado.datos;
          this.cargando = false;
        });
  }

  crearUsuario() {
    this.xid    = -1;
    this.xnomb  = '';
    this.xmail  = '';
    this.xpssw  = '';
    this.xsoft  = '';
    this.xsuper = false;
    this.xadmin = false;
  }

  modificarUsuario( user ) {
    // console.log( user );
    this.xid    = user.id;
    this.xnomb  = user.nombre;
    this.xmail  = user.email;
    this.xpssw  = user.code;
    this.xsoft  = user.codigo_softland;
    this.xsuper = user.supervisor;
    this.xadmin = user.admin;
  }

  grabarUser() {
    this.cargando = true;
    this.login.saveUser( this.xid, this.xnomb, this.xmail, this.xpssw, this.xsoft, this.xsuper, this.xadmin )
        .subscribe( (resultado: any) => {
          // console.log(resultado);
          if ( resultado.resultado === 'ok' ) {
            this.usuarios.forEach(element => {
              if ( this.xid === element.id ) {
                element.nombre = this.xnomb;
                element.email  = this.xmail;
                element.code   = this.xpssw;
                element.codigo_softland = this.xsoft;
                element.supervisor = this.xsuper;
                element.admin = this.xadmin;
              }
              this.cargando = false;
              Swal.fire({
                icon: 'success',
                title: 'ATENCION',
                text: 'La grabación se realizó con éxito',
                footer: '<a href>ID: ' + this.xid.toString() + ' </a>'
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
