import { Component, OnInit, Inject,  } from '@angular/core';
// import { DOCUMENT } from '@angular/common';
import { SettingsService } from 'src/app/services/service.index';

@Component({
  selector: 'app-account-settings',
  templateUrl: './account-settings.component.html',
  styles: []
})
export class AccountSettingsComponent implements OnInit {

  constructor( public seteo: SettingsService ) { }

  ngOnInit() {
  }

  cambiarColor( tema: string, link: any ) {
    // console.log(link);
    this.aplicarCheck( link );
    this.seteo.aplicarTema( tema );
  }

  aplicarCheck( link ) {
    //
    const selectores = document.getElementsByClassName( 'selector' );
    // console.log( selectores );

    // tslint:disable-next-line: forin
    // for ( const ref of selectores ) {
    //   ref.classList.remove('working');
    // }
    link.classList.add( 'working' );
  }

  colocarCheck() {
    //
    const selectores = document.getElementsByClassName( 'selector' );
    const tema = this.seteo.ajustes.tema;
    //
    // for ( let ref of selectores ) {
    //   if ( ref.getAttribute('data-theme') === tema ) {
    //     ref.classList.add('working');
    //     break;
    //   }
    // }
  }

}
