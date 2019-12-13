import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { PAGES_ROUTES } from './pages.routes';

import { HttpClientModule } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

// ng2-charts
import { ChartsModule } from 'ng2-charts';

// material modules
import { MaterialModule } from './../material.module';

import { PagesComponent } from './pages.component';
import { SharedModule } from '../shared/shared.module';

import { DashboardComponent } from './dashboard/dashboard.component';
import { ProgressComponent } from './progress/progress.component';
import { StockComponent } from './stock/stock.component';
import { StockpComponent } from './stockp/stockp.component';
import { GuiasComponent } from './guias/guias.component';
import { GuiasciComponent } from './guiasci/guiasci.component';
import { IncrementadorComponent } from '../components/incrementador/incrementador.component';
import { Graficas1Component } from './graficas1/graficas1.component';
import { GraficoDonaComponent } from '../components/grafico-dona/grafico-dona.component';
import { AccountSettingsComponent } from './account-settings/account-settings.component';
import { PromesasComponent } from './promesas/promesas.component';
import { RxjsComponent } from './rxjs/rxjs.component';
import { BuscarCodigosComponent } from '../components/buscar-codigos/buscar-codigos.component';
import { EditalineaComponent } from '../components/editalinea/editalinea.component';

@NgModule({
    declarations: [
        PagesComponent,
        DashboardComponent,
        ProgressComponent,
        StockComponent,
        StockpComponent,
        GuiasComponent,
        GuiasciComponent,
        IncrementadorComponent,
        Graficas1Component,
        GraficoDonaComponent,
        AccountSettingsComponent,
        PromesasComponent,
        RxjsComponent,
        GuiasciComponent,
        BuscarCodigosComponent,
        EditalineaComponent
    ],
    exports: [
        DashboardComponent,
        ProgressComponent,
        StockComponent,
        GuiasComponent,
        BuscarCodigosComponent,
        EditalineaComponent
    ],
    imports: [
        CommonModule,
        SharedModule,
        PAGES_ROUTES,
        HttpClientModule,
        FormsModule,
        ReactiveFormsModule,
        ChartsModule,
        MaterialModule,
    ]
})
export class PagesModule { }
