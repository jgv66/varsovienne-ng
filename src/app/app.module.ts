import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

// rutas
import { APP_ROUTES } from './app.routes';

// modulos
import { PagesModule } from './pages/pages.module';

// temporal
import { HttpClientModule } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

// material
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatTableModule } from '@angular/material/table';

// servicios
import { ServiceModule } from './services/service.module';

import { AppComponent } from './app.component';
import { LoginComponent } from './login/login.component';
import { RegisterComponent } from './login/register.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { BsDatepickerModule } from 'ngx-bootstrap/datepicker';

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    RegisterComponent
  ],
  imports: [
    BrowserModule,
    APP_ROUTES,
    PagesModule,
    HttpClientModule,
    FormsModule,
    ReactiveFormsModule,
    BsDatepickerModule.forRoot(),
    ServiceModule,
    BrowserAnimationsModule,
    MatProgressBarModule,
    MatTableModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
