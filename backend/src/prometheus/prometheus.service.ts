import { Injectable, OnModuleInit } from '@nestjs/common';
import * as client from 'prom-client';
import { InjectMetric } from '@willsoto/nestjs-prometheus';
import { Counter, Gauge } from 'prom-client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PrometheusService implements OnModuleInit {
    private readonly register: client.Registry;

    constructor(
        @InjectMetric('stock_products_total')
        private readonly productsGauge: Gauge<string>,

        @InjectMetric('stock_movements_total')
        private readonly movementsCounter: Counter<string>,

        private readonly prisma: PrismaService,
    ) {
        this.register = new client.Registry();
        this.register.setDefaultLabels({ app: 'nestjs-prometheus' });
        client.collectDefaultMetrics({ register: this.register });
        this.register.registerMetric(this.productsGauge);
        this.register.registerMetric(this.movementsCounter);
    }

    async onModuleInit() {
        // Inicializar métricas al arrancar (carga completa)
        await this.initializeMetrics();
        // Actualizar gauge de productos periódicamente (cada 10 s)
        setInterval(async () => {
            await this.updateMetrics();
        }, 10000);
    }

    async updateMetrics() {
        try {
            // 1. Actulizar total de productos
            const totalProducts = await this.prisma.product.count();
            this.productsGauge.set(totalProducts);

        } catch (error) {
            console.error('Error updating metrics from DB:', error);
        }
    }

    async initializeMetrics() {
        try {
            // 1. Inicializar total de productos
            const totalProducts = await this.prisma.product.count();
            this.productsGauge.set(totalProducts);

            // 2. Inicializar contador de movimientos por tipo
            const movements = await this.prisma.movement.groupBy({
                by: ['type'],
                _count: { type: true },
            });
            movements.forEach((m) => {
                if (m.type) {
                    // Incrementar el counter con el valor almacenado en DB
                    this.movementsCounter.inc({ type: m.type }, m._count.type);
                }
            });
        } catch (error) {
            console.error('Error initializing metrics from DB:', error);
        }
    }

    updateProductsTotal(count: number): void {
        this.productsGauge.set(count);
    }

    incrementMovements(type: string): void {
        this.movementsCounter.inc({ type });
    }

    getMetrics(): Promise<string> {
        return this.register.metrics();
    }
}
