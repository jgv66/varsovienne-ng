import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SidebarService {

  menuInformes: any = [
    {
      titulo: 'Informes',
      icono: 'mdi mdi-cloud-print-outline',
      submenu: [
        { titulo: 'Stock por Locales', url: '/stock' },
        { titulo: 'Stock por Producto', url: '/stockP' },
        // { titulo: 'Informe de Guías', url: '/iguias' },
      ]
    }
  ];

  menuDocumentos: any = [
    {
      titulo: 'Documentos',
      icono: 'mdi mdi-cube-send',
      submenu: [
        { titulo: 'Consumo Interno',        url: '/guiasci' },
        { titulo: 'Traslado entre Locales', url: '/guias' },
        { titulo: 'Gráficas',               url: '/graficas1' },
        // { titulo: 'Promesas',          url: '/promesas' },
        // { titulo: 'RxJs',              url: '/rxjs' },
      ]
    }
  ];

  constructor() { }
}
