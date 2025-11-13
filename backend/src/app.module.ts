import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { StockModule } from './stock/stock.module';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { ProductsModule } from './products/products.module';
import { MovementsModule } from './movements/movements.module';

@Module({
  imports: [
    PrismaModule,
    ProductsModule,
    MovementsModule,
    StockModule,
    CommonModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
