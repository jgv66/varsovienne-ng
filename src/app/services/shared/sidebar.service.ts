import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SidebarService {

  menu: any = [
    {
      titulo: 'Documentos',
      icono: 'mdi mdi-gauge',
      submenu: [
        { titulo: 'Stock', url: '/stock' },
        { titulo: 'Guías', url: '/guias' },
        { titulo: 'Dashboard', url: '/dashboard' },
        { titulo: 'ProgressBar', url: '/progress' },
        { titulo: 'Gráficas', url: '/graficas1' },
      ]
    }
  ];

  constructor() { }
}
