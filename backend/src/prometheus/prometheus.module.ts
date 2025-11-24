import { Module } from '@nestjs/common';
import {
  PrometheusModule as PrometheusModuleBase,
  makeCounterProvider,
  makeGaugeProvider,
} from '@willsoto/nestjs-prometheus';
import { PrometheusService } from './prometheus.service';

@Module({
  imports: [
    PrometheusModuleBase.register({
      path: '/metrics',
      defaultMetrics: {
        enabled: true,
      },
    }),
  ],
  providers: [
    // Métricas personalizadas
    makeGaugeProvider({
      name: 'stock_products_total',
      help: 'Total number of products in inventory',
    }),
    makeCounterProvider({
      name: 'stock_movements_total',
      help: 'Total number of stock movements',
      labelNames: ['type'],
    }),
    PrometheusService,
  ],
  exports: [
    PrometheusModuleBase,
    PrometheusService,
  ],
})
export class PrometheusModule {}
