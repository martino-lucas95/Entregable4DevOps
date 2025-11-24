import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { StockModule } from './stock/stock.module';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { ProductsModule } from './products/products.module';
import { MovementsModule } from './movements/movements.module';
import { PrometheusModule } from './prometheus/prometheus.module';
import { MetricsInterceptor } from './prometheus/metrics.interceptor';

@Module({
  imports: [
    PrismaModule,
    ProductsModule,
    MovementsModule,
    StockModule,
    CommonModule,
    PrometheusModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: MetricsInterceptor,
    },
  ],
})
export class AppModule { }
