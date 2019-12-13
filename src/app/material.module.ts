import { NgModule } from '@angular/core';

import {
    MatInputModule,
    MatButtonModule,
    MatProgressBarModule,
    MatTableModule,
    MatNativeDateModule,
    MatDatepickerModule
} from '@angular/material';

import {MatSelectModule} from '@angular/material/select';
import {MatFormFieldModule} from '@angular/material/form-field';

@NgModule({
    imports: [
      MatButtonModule,
      MatInputModule,
      MatSelectModule,
      MatFormFieldModule,
      MatProgressBarModule,
      MatTableModule,
      MatNativeDateModule,
      MatDatepickerModule,
      ],
    exports: [
      MatButtonModule,
      MatFormFieldModule,
      MatInputModule,
      MatSelectModule,
      MatProgressBarModule,
      MatTableModule,
      MatNativeDateModule,
      MatDatepickerModule,
      ],
  })

export class MaterialModule {}



