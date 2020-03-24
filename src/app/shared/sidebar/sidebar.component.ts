import { Component, OnInit } from '@angular/core';
import { SidebarService } from '../../services/service.index';
import { LoginService } from '../../services/login.service';

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.component.html',
  styles: []
})
export class SidebarComponent implements OnInit {

  admin = false;

  constructor( public sidebar: SidebarService,
               public login: LoginService ) { }

  ngOnInit() {
    if ( this.login.usuario ) {
      this.admin = this.login.usuario.admin;
      if ( this.admin === false ) {
        this.sidebar.menuUsuarios = [];
        this.sidebar.menuFolios   = [];
        this.sidebar.menuInformes = [];
      }
    }
  }

}
