import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SidebarService {

  menuInformes: any = [
    {
      titulo: 'Informes',
      icono: 'mdi mdi-gauge',
      submenu: [
        { titulo: 'Stock', url: '/stock' },
      ]
    }
  ]

  menuDocumentos: any = [
    {
      titulo: 'Documentos',
      icono: 'mdi mdi-gauge',
      submenu: [
        { titulo: 'Guías de Traslado', url: '/guias' },
        { titulo: 'ProgressBar', url: '/progress' },
        { titulo: 'Gráficas', url: '/graficas1' },
      ]
    }
  ];

  constructor() { }
}
