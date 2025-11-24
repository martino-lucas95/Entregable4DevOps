import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Counter, Histogram, register } from 'prom-client';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
    private readonly httpRequestsTotal: Counter<string>;
    private readonly httpRequestDurationSeconds: Histogram<string>;

    constructor() {
        // Crear métricas HTTP
        this.httpRequestsTotal = new Counter({
            name: 'http_requests_total',
            help: 'Total number of HTTP requests',
            labelNames: ['method', 'route', 'status_code'],
            registers: [register],
        });

        this.httpRequestDurationSeconds = new Histogram({
            name: 'http_request_duration_seconds',
            help: 'HTTP request duration in seconds',
            labelNames: ['method', 'route', 'status_code'],
            buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
            registers: [register],
        });
    }

    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        const request = context.switchToHttp().getRequest();
        const response = context.switchToHttp().getResponse();

        const method = request.method;
        const route = request.route?.path || request.url;
        const start = Date.now();

        return next.handle().pipe(
            tap({
                next: () => {
                    const duration = (Date.now() - start) / 1000;
                    const statusCode = response.statusCode.toString();

                    this.httpRequestsTotal.inc({ method, route, status_code: statusCode });
                    this.httpRequestDurationSeconds.observe({ method, route, status_code: statusCode }, duration);
                },
                error: (error) => {
                    const duration = (Date.now() - start) / 1000;
                    const statusCode = error.status?.toString() || '500';

                    this.httpRequestsTotal.inc({ method, route, status_code: statusCode });
                    this.httpRequestDurationSeconds.observe({ method, route, status_code: statusCode }, duration);
                },
            }),
        );
    }
}
