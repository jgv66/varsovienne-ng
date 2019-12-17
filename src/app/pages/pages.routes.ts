
import { Routes, RouterModule } from '@angular/router';
import { NgModule } from '@angular/core';

import { PagesComponent } from './pages.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { GuiasciComponent } from './guiasci/guiasci.component';
import { GuiasComponent } from './guias/guias.component';
import { StockComponent } from './stock/stock.component';
import { ProgressComponent } from './progress/progress.component';
import { Graficas1Component } from './graficas1/graficas1.component';
import { AccountSettingsComponent } from './account-settings/account-settings.component';
import { PromesasComponent } from './promesas/promesas.component';
import { RxjsComponent } from './rxjs/rxjs.component';
import { StockpComponent } from './stockp/stockp.component';
import { IguiascComponent } from './iguiasc/iguiasc.component';
import { GuiasrecepComponent } from './guiasrecep/guiasrecep.component';

const pagesRoutes: Routes = [
    {   path: '',
        component: PagesComponent,
        children: [
            { path: 'dashboard',         component: DashboardComponent       , data: { titulo: 'Dashboard' } },
            { path: 'guiasci',           component: GuiasciComponent         , data: { titulo: 'Guía de Consumo Interno' } },
            { path: 'guiastr',           component: GuiasComponent           , data: { titulo: 'Guía de Traslado entre Locales' } },
            { path: 'guiasrecep',        component: GuiasrecepComponent      , data: { titulo: 'Guía de Recepción de Traslado' } },
            { path: 'stock',             component: StockComponent           , data: { titulo: 'Stock por Locales' } },
            { path: 'stockP',            component: StockpComponent          , data: { titulo: 'Stock por Producto' } },
            { path: 'iguiasc',           component: IguiascComponent         , data: { titulo: 'Informe de Guias de Consumo' } },
            { path: 'progress',          component: ProgressComponent        , data: { titulo: 'Progress Bar' } },
            { path: 'graficas1',         component: Graficas1Component       , data: { titulo: 'Gráficos' } },
            { path: 'account-settings',  component: AccountSettingsComponent , data: { titulo: 'Ajustes del Tema' } },
            { path: 'promesas',          component: PromesasComponent        , data: { titulo: 'Promesas' } },
            { path: 'rxjs',              component: RxjsComponent            , data: { titulo: 'RxJs' } },
            { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
        ]
    },
];

export const PAGES_ROUTES = RouterModule.forChild( pagesRoutes );
