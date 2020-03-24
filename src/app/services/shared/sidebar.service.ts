import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SidebarService {

  menuUsuarios: any = [
    {
      titulo: 'Usuarios',
      icono: 'mdi mdi-face',
      submenu: [
        { titulo: 'Mantención', url: '/usuarios'   },
        { titulo: 'Locales por usuario', url: '/locporuser'   },
      ]
    }
  ];

  menuFolios: any = [
    {
      titulo: 'Folios',
      icono: 'mdi mdi-note-plus-outline',
      submenu: [
        { titulo: 'Folios por Locales', url: '/folios'   },
      ]
    }
  ];

  menuInformes: any = [
    {
      titulo: 'Informes',
      icono: 'mdi mdi-cloud-print-outline',
      submenu: [
        { titulo: 'Stock por Locales',  url: '/stock'   },
        { titulo: 'Stock por Producto', url: '/stockP'  },
      ]
    }
  ];

  menuDocumentos: any = [
    {
      titulo: 'Documentos',
      icono: 'mdi mdi-cube-send',
      submenu: [
        { titulo: 'Consumo Interno',        url: '/guiasci'     },
        { titulo: 'Devoluciones',           url: '/guiasdevo/1' },
        { titulo: 'Traslado entre tiendas', url: '/guiastras/2' },
        { titulo: 'Recepciones',            url: '/guiasrecep'  },
        { titulo: 'Informe de Guías',       url: '/iguiasc'     },
      ]
    }
  ];

  constructor() { }

}
