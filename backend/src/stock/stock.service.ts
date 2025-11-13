import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MovementType } from '../common/enums/movement-type.enum';

@Injectable()
export class StockService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const products = await this.prisma.product.findMany();

    const result = [];

    for (const product of products) {
      const stock = await this.getStock(product.id);
      result.push({
        productId: product.id,
        name: product.name,
        stock,
      });
    }

    return result;
  }

  async findOne(productId: number) {
    const stock = await this.getStock(productId);

    return { productId, stock };
  }

  async getStock(productId: number): Promise<number> {
    const grouped = await this.prisma.movement.groupBy({
      by: ['type'],
      where: { productId },
      _sum: { quantity: true },
    });

    const ins =
      grouped.find((g) => g.type === MovementType.IN)?._sum.quantity ?? 0;
    const outs =
      grouped.find((g) => g.type === MovementType.OUT)?._sum.quantity ?? 0;

    return ins - outs;
  }
}
